package com.example.jaspertable.exception;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Standardized error response for API errors.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ErrorResponse {

    /**
     * The HTTP status code.
     */
    private int status;

    /**
     * The error code for the client.
     */
    private String code;

    /**
     * A user-friendly error message.
     */
    private String message;

    /**
     * The timestamp when the error occurred.
     */
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
    private LocalDateTime timestamp;

    /**
     * The path of the request that caused the error.
     */
    private String path;

    /**
     * Detailed error information for debugging.
     */
    private String debugMessage;

    /**
     * List of sub-errors (field-level validation errors, etc.)
     */
    private List<ValidationError> errors;

    /**
     * Adds a validation error to the list of errors.
     *
     * @param field   the field name that has the error
     * @param message the error message
     */
    public void addValidationError(String field, String message) {
        if (errors == null) {
            errors = new ArrayList<>();
        }
        errors.add(new ValidationError(field, message));
    }

    /**
     * Creates a builder with common fields pre-populated.
     *
     * @param status  the HTTP status
     * @param message the error message
     * @param path    the request path
     * @return a pre-configured ErrorResponse
     */
    public static ErrorResponse of(HttpStatus status, String message, String path) {
        return ErrorResponse.builder()
                .status(status.value())
                .code(status.name())
                .message(message)
                .path(path)
                .timestamp(LocalDateTime.now())
                .build();
    }

    /**
     * Represents a field-level validation error.
     */
    @Data
    @AllArgsConstructor
    public static class ValidationError {
        private String field;
        private String message;
    }
} 