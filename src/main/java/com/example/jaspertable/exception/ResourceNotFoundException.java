package com.example.jaspertable.exception;

/**
 * Exception thrown when a requested resource cannot be found.
 */
public class ResourceNotFoundException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * Constructs a new resource not found exception with the specified detail message.
     *
     * @param message the detail message
     */
    public ResourceNotFoundException(String message) {
        super(message);
    }

    /**
     * Constructs a new resource not found exception for a specific resource identified by its ID.
     *
     * @param resourceName the name of the resource type
     * @param fieldName    the name of the identifier field
     * @param fieldValue   the value of the identifier
     * @return a new ResourceNotFoundException with a formatted message
     */
    public static ResourceNotFoundException create(String resourceName, String fieldName, Object fieldValue) {
        return new ResourceNotFoundException(
                String.format("%s not found with %s: '%s'", resourceName, fieldName, fieldValue));
    }
} 