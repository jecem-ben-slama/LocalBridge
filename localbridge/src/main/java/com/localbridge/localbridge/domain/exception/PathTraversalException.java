package com.localbridge.localbridge.domain.exception;

public class PathTraversalException extends RuntimeException {
    public PathTraversalException(String message) {
        super(message);
    }
}