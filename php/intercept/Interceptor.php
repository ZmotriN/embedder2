<?php

namespace Embeder;

class Interceptor {

    /** @var string[] */
    private $protocols;

    /** @var callable */
    private $hook;

    /**
     * Create an interceptor.
     *
     * The hook should have the following signature:
     *     function(string $path): string|null
     *
     * The hook is passed the realpath of the included file.
     * The hook can return null to skip interception for this file,
     * or a string, to specify the transformed file contents.
     */
    public function __construct(callable $hook, array $protocols = ['file','res']) {
        $this->hook = $hook;
        $this->protocols = $protocols;
    }

    /**
     * Open a file and run it through the hook.
     *
     * @return resource|null
     * @internal
     */
    public function intercept(string $path) {
        $result = ($this->hook)($path);
        if ($result === null) {
            return null;
        }

        $stream = fopen('php://temp', 'r+');
        fwrite($stream, $result);
        rewind($stream);
        return $stream;
    }

    /**
     * Setup this instance to intercept include calls.
     */
    public function setUp(): void {
        if (Stream::hasInterceptor()) {
            throw new \BadMethodCallException('An interceptor is already active');
        }
        Stream::setInterceptor($this);
        $this->wrap();
    }

    /**
     * Stop intercepting include calls.
     */
    public function tearDown(): void {
        $this->unwrap();
        Stream::clearInterceptor();
    }

    /**
     * Register the stream wrapper.
     *
     * @internal
     */
    public function wrap(): void {
        foreach ($this->protocols as $protocol) {
            stream_wrapper_unregister($protocol);
            stream_wrapper_register($protocol, Stream::class);
        }
    }

    /**
     * Unregister the stream wrapper.
     *
     * @internal
     */
    public function unwrap(): void {
        foreach ($this->protocols as $protocol) {
            stream_wrapper_restore($protocol);
        }
    }
}
