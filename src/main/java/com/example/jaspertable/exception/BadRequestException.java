package com.example.jaspertable.exception;

/**
 * Exception thrown when a client sends an invalid request.
 */
public class BadRequestException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * Constructs a new bad request exception with the specified detail message.
     *
     * @param message the detail message
     */
    public BadRequestException(String message) {
        super(message);
    }

    /**
     * Constructs a new bad request exception with the specified detail message and cause.
     *
     * @param message the detail message
     * @param cause   the cause of the exception
     */
    public BadRequestException(String message, Throwable cause) {
        super(message, cause);
    }
} 