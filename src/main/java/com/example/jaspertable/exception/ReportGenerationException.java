package com.example.jaspertable.exception;

/**
 * Exception thrown when there is an error during report generation.
 */
public class ReportGenerationException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /**
     * Constructs a new report generation exception with the specified detail message.
     *
     * @param message the detail message
     */
    public ReportGenerationException(String message) {
        super(message);
    }

    /**
     * Constructs a new report generation exception with the specified detail message and cause.
     *
     * @param message the detail message
     * @param cause   the cause of the exception
     */
    public ReportGenerationException(String message, Throwable cause) {
        super(message, cause);
    }

    /**
     * Creates a new exception for a specific report file that couldn't be generated.
     *
     * @param fileName the name of the report file
     * @param cause    the cause of the failure
     * @return a new ReportGenerationException with relevant details
     */
    public static ReportGenerationException forFile(String fileName, Throwable cause) {
        return new ReportGenerationException(
                String.format("Failed to generate report for file: '%s'", fileName), cause);
    }
} 