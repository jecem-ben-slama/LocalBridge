package com.localbridge.localbridge.presentation.handler;

import com.localbridge.localbridge.presentation.dto.ApiResponse;
import com.localbridge.localbridge.domain.exception.UnauthorizedException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<ApiResponse<Void>> handleUnauthorized(UnauthorizedException exception) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(exception.getMessage()));
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ApiResponse<Void>> fileTooLarge(MaxUploadSizeExceededException exception) {
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(ApiResponse.error("That file is too large. The maximum upload size is 10 GB."));
    }

    @ExceptionHandler(MultipartException.class)
    public ResponseEntity<ApiResponse<Void>> multipartError(MultipartException exception) {
        return ResponseEntity.badRequest()
                .body(ApiResponse.error("The upload could not be read. Please try the file again."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> unexpectedError(Exception exception) {
        return ResponseEntity.internalServerError()
                .body(ApiResponse.error("The request could not be completed. Please try again."));
    }
}
