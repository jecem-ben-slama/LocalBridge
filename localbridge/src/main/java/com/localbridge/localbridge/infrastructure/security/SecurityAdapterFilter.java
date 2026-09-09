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

        // Bypass only the endpoint needed to establish a session and static assets.
        if (path.equals("/api/auth/verify") || path.equals("/ws/phone") || path.startsWith("/index.html")
                || path.equals("/") || path.endsWith(".js")
                || path.endsWith(".css")) {
            filterChain.doFilter(request, response);
            return;
        }

        // Extract raw network attributes
        String remoteAddr = request.getRemoteAddr();
        String hostHeader = request.getHeader("Host");

        // Support multiple token header keys for compatibility
        String tokenHeader = request.getHeader("X-LocalBridge-Token");
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getHeader("X-Auth-Token");
        }
        if (tokenHeader == null || tokenHeader.isBlank()) {
            String authHeader = request.getHeader("Authorization");
            if (authHeader != null && authHeader.startsWith("Bearer ")) {
                tokenHeader = authHeader.substring(7);
            }
        }
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getParameter("token");
        }
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getParameter("pairing_token");
        }
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getParameter("pairing_code");
        }
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getParameter("code");
        }

        // Delegate verification to the Inbound Port
        SecurityContext context = authenticateUseCase.evaluateRequest(remoteAddr, hostHeader, tokenHeader);

        if (context.isAuthenticated()) {
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