@echo off
setlocal enableextensions enabledelayedexpansion

	cd /D %APPVEYOR_BUILD_FOLDER%
	if %errorlevel% neq 0 exit /b 3

	set STABILITY=staging
	set DEPS_DIR=%PHP_BUILD_CACHE_BASE_DIR%\deps-%PHP_REL%-%PHP_SDK_VC%-%PHP_SDK_ARCH%
	rem SDK is cached, deps info is cached as well
	echo Updating dependencies in %DEPS_DIR%
	cmd /c phpsdk_deps --update --no-backup --branch %PHP_REL% --stability %STABILITY% --deps %DEPS_DIR% --crt %PHP_BUILD_CRT%
	if %errorlevel% neq 0 exit /b 3

	rem Something went wrong, most likely when concurrent builds were to fetch deps
	rem updates. It might be, that some locking mechanism is needed.
	if not exist "%DEPS_DIR%" (
		cmd /c phpsdk_deps --update --force --no-backup --branch %PHP_REL% --stability %STABILITY% --deps %DEPS_DIR% --crt %PHP_BUILD_CRT%
	)
	if %errorlevel% neq 0 exit /b 3

	for %%z in (%ZTS_STATES%) do (
		set ZTS_STATE=%%z
		if "!ZTS_STATE!"=="enable" set ZTS_SHORT=ts
		if "!ZTS_STATE!"=="disable" set ZTS_SHORT=nts

		cd /d C:\projects\php-src

		cmd /c buildconf.bat --force

		if %errorlevel% neq 0 exit /b 3

		cmd /c configure.bat --disable-all --with-mp=auto --enable-cli --!ZTS_STATE!-zts --enable-embed --enable-object-out-dir=%PHP_BUILD_OBJ_DIR% --with-config-file-scan-dir=%APPVEYOR_BUILD_FOLDER%\build\modules.d --with-prefix=%APPVEYOR_BUILD_FOLDER%\build --with-php-build=%DEPS_DIR%

		if %errorlevel% neq 0 exit /b 3

		nmake /NOLOGO

		if %errorlevel% neq 0 exit /b 3

		nmake install

		if %errorlevel% neq 0 exit /b 3

		cd /d %APPVEYOR_BUILD_FOLDER%


		rem xcopy %APPVEYOR_BUILD_FOLDER%\LICENSE %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\ /y /f

        call vcvarsall.bat
        MSBuild.exe embeder.sln /p:Configuration="Debug console" /p:Platform="Win32"
        copy "Debug console\embeder.exe" "../out/console.exe" || exit /b 1
        del /q /f ".\embeder2.exe" 2>nul
        IF NOT EXIST "php.exe" echo Error, PHP not found. && exit /b 1
        php.exe php/embeder2.php new embeder2
        php.exe php/embeder2.php main embeder2 php/embeder2.php
        php.exe php/embeder2.php add embeder2 out/console.exe out/console.exe


		rem if not exist "%APPVEYOR_BUILD_FOLDER%\build\ext\php_winbinder.dll" exit /b 3
		rem xcopy %APPVEYOR_BUILD_FOLDER%\LICENSE %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\ /y /f
		rem xcopy %APPVEYOR_BUILD_FOLDER%\docs %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\docs\ /y /f
		rem xcopy %APPVEYOR_BUILD_FOLDER%\php %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\examples\ /y /f
		rem rem xcopy %APPVEYOR_BUILD_FOLDER%\build\ext\php_winbinder.dll %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\ /y /f
		rem xcopy %APPVEYOR_BUILD_FOLDER%\build\ext\*.dll %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\ /y /f
		rem 7z a php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%.zip %APPVEYOR_BUILD_FOLDER%\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%\*
		rem appveyor PushArtifact php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%.zip -FileName php_winbinder-%APPVEYOR_REPO_TAG_NAME%-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%.zip
		rem move build\ext\php_winbinder.dll artifacts\php_winbinder-%PHP_REL%-!ZTS_SHORT!-%PHP_BUILD_CRT%-%PHP_SDK_ARCH%.dll
	)
endlocal
