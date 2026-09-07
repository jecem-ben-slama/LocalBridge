package com.localbridge.localbridge.application.port.inbound;

import com.localbridge.localbridge.domain.model.SecurityContext;

public interface AuthenticateRequestUseCase {
    SecurityContext evaluateRequest(String remoteAddress, String hostHeader, String tokenHeader);
}