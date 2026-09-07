package com.localbridge.localbridge.infrastructure.security;

import com.localbridge.localbridge.application.port.inbound.AuthenticateRequestUseCase;
import com.localbridge.localbridge.domain.model.SecurityContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class SecurityAdapterFilter extends OncePerRequestFilter {

    private final AuthenticateRequestUseCase authenticateUseCase;

    public SecurityAdapterFilter(AuthenticateRequestUseCase authenticateUseCase) {
        this.authenticateUseCase = authenticateUseCase;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();

        // Bypass static assets and auth verification endpoints
        if (path.startsWith("/api/auth/") || path.startsWith("/index.html") || path.equals("/") || path.endsWith(".js")
                || path.endsWith(".css")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Extract raw network attributes (Infrastructure concern)
        String remoteAddr = request.getRemoteAddr();
        String hostHeader = request.getHeader("Host");
        String tokenHeader = request.getHeader("X-LocalBridge-Token");

        // Delegate verification to the Inbound Port (Core business logic)
        SecurityContext context = authenticateUseCase.evaluateRequest(remoteAddr, hostHeader, tokenHeader);

        if (context.isAuthenticated()) {
            // Attach security context or attributes if needed downstream
            request.setAttribute("securityContext", context);
            filterChain.doFilter(request, response);
        } else {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write(
                    "{\"success\":false,\"message\":\"Unauthorized: Local loopback or valid pairing token required.\"}");
        }
    }
}