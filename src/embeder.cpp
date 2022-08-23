//========================================================================
//       Embeder - Make an executable Windows-binary file from a PHP script
//
//       License : PHP License (http://www.php.net/license/3_0.txt)
//       Author : Eric Colinet <e dot colinet at laposte dot net>
//       http://wildphp.free.fr/wiki/doku?id=win32std:embeder
//========================================================================

/* PHP Conf */
#ifndef ZEND_WIN32
#define ZEND_WIN32
#endif
#ifndef PHP_WIN32
#define PHP_WIN32
#endif
#ifndef ZTS
#define ZTS 1
#endif
#ifndef ZEND_DEBUG
#define ZEND_DEBUG 0
#endif

/* PHP Includes */
#include <php_embed.h>


/* Main */
int main(int argc, char** argv) {
	zval ret_value;
	int exit_status;
	char *eval_string = "include 'res:///PHP/LIB';";
    zend_string *ini_name;

	/* Start PHP embed */
	php_embed_init(argc, argv TSRMLS_CC);
    php_embed_module.php_ini_ignore = 0;
    php_embed_module.php_ini_path_override = "./php.ini";

    //zend_alter_ini_entry("extension_dir", '".\\ext"', PHP_INI_ALL, PHP_INI_STAGE_ACTIVATE);
    //zend_alter_ini_entry("display_errors", "-1", PHP_INI_ALL, PHP_INI_STAGE_ACTIVATE);
    //zend_alter_ini_entry("error_reporting", "E_ALL", PHP_INI_ALL, PHP_INI_STAGE_ACTIVATE);
    //zend_alter_ini_entry("error_log", "error.log", PHP_INI_ALL, PHP_INI_STAGE_ACTIVATE);

    ini_name = zend_string_init("extension_dir", sizeof("extension_dir") - 1, 0);
    zend_alter_ini_entry(ini_name, zend_string_init(".\\ext", sizeof(".\\ext") - 1, 0), PHP_INI_USER, PHP_INI_STAGE_RUNTIME);
    zend_string_release_ex(ini_name, 0);

    ini_name = zend_string_init("display_errors", sizeof("display_errors") - 1, 0);
    zend_alter_ini_entry(ini_name, zend_string_init("Off", sizeof("Off") - 1, 0), PHP_INI_USER, PHP_INI_STAGE_RUNTIME);
    zend_string_release_ex(ini_name, 0);

    ini_name = zend_string_init("error_reporting", sizeof("error_reporting") - 1, 0);
    zend_alter_ini_entry(ini_name, zend_string_init("E_ALL", sizeof("E_ALL") - 1, 0), PHP_INI_USER, PHP_INI_STAGE_RUNTIME);
    zend_string_release_ex(ini_name, 0);

    ini_name = zend_string_init("error_log", sizeof("error_log") - 1, 0);
    zend_alter_ini_entry(ini_name, zend_string_init(".\\error.log", sizeof(".\\error.log") - 1, 0), PHP_INI_USER, PHP_INI_STAGE_RUNTIME);
    zend_string_release_ex(ini_name, 0);

	zend_first_try {
		PG(during_request_startup) = 0;

		/* We are embeded */
		zend_eval_string("define('EMBEDED', 1);", &ret_value, "main" TSRMLS_CC);

		/* Execute */
		zend_eval_string(eval_string, &ret_value, "main" TSRMLS_CC);

		/* Get Exit Status */
		exit_status= Z_LVAL(ret_value);
	}

	/* Catch Exit status */
	zend_catch {
		exit_status = EG(exit_status);
	}
	zend_end_try();

	/* Stop PHP embed */
	php_embed_shutdown(TSRMLS_C);

	/* Return exit status */
	return exit_status;
}


