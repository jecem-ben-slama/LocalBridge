package com.localbridge.localbridge.infrastructure.security;

import com.localbridge.localbridge.application.port.inbound.AuthenticateRequestUseCase;
import com.localbridge.localbridge.domain.model.SecurityContext;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class SecurityAdapterFilterTest {

    @Test
    void acceptsPairingTokenQueryParameter() throws Exception {
        AuthenticateRequestUseCase auth = (remoteAddress, hostHeader,
                tokenHeader) -> "pairing-token-123".equals(tokenHeader)
                        ? SecurityContext.trustedDevice(tokenHeader)
                        : SecurityContext.unauthorized();

        SecurityAdapterFilter filter = new SecurityAdapterFilter(auth);
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/phone/status");
        request.setParameter("pairing_token", "pairing-token-123");

        MockHttpServletResponse response = new MockHttpServletResponse();
        AtomicBoolean chainCalled = new AtomicBoolean(false);

        filter.doFilter(request, response, (req, res) -> chainCalled.set(true));

        assertTrue(chainCalled.get(), "Request should continue when a valid pairing token is supplied");
        assertEquals(200, response.getStatus(), "Authentication should succeed for pairing_token");
    }
}
