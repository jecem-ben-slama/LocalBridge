package com.localbridge.localbridge.application.service;

import com.localbridge.localbridge.application.port.inbound.AuthenticateRequestUseCase;
import com.localbridge.localbridge.application.port.outbound.TokenManagerPort;
import com.localbridge.localbridge.domain.model.SecurityContext;
import org.springframework.stereotype.Service;

@Service
public class AuthenticationService implements AuthenticateRequestUseCase {

    private final TokenManagerPort tokenManagerPort; // Outbound port for token validation

    public AuthenticationService(TokenManagerPort tokenManagerPort) {
        this.tokenManagerPort = tokenManagerPort;
    }

    @Override
    public SecurityContext evaluateRequest(String remoteAddress, String hostHeader, String tokenHeader) {
        // Only trust the socket peer address. Host is client-controlled.
        boolean isLoopback = "127.0.0.1".equals(remoteAddress) ||
                "0:0:0:0:0:0:0:1".equals(remoteAddress) ||
                "::1".equals(remoteAddress);

        if (isLoopback) {
            return SecurityContext.trustedLocal();
        }

        // 2. Check for Mobile / External Device Token (QR Pairing or Console Token)
        if (tokenHeader != null && tokenManagerPort.validateToken(tokenHeader)) {
            return SecurityContext.trustedDevice(tokenHeader);
        }

        return SecurityContext.unauthorized();
    }
}