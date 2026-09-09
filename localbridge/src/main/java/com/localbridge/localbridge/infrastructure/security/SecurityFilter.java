/* package com.localbridge.localbridge.infrastructure.security;

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
public class SecurityFilter extends OncePerRequestFilter {

    private final AuthenticateRequestUseCase authenticateRequestUseCase;

    public SecurityFilter(AuthenticateRequestUseCase authenticateRequestUseCase) {
        this.authenticateRequestUseCase = authenticateRequestUseCase;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        // 1. Always bypass CORS Preflight requests
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();

        // 2. Extract token from Header or Query Param
        String tokenHeader = request.getHeader("X-Auth-Token");
        if (tokenHeader == null || tokenHeader.isBlank()) {
            tokenHeader = request.getParameter("pairing_token");
        }

        String remoteAddress = request.getRemoteAddr();
        String hostHeader = request.getHeader("Host");

        // Force stdout log output immediately
        System.out.println("\n>>> [SecurityFilter] Incoming Request: " + request.getMethod() + " " + path);
        System.out.println(">>> [SecurityFilter] Remote IP: " + remoteAddress);
        System.out.println(">>> [SecurityFilter] Received Token: [" + tokenHeader + "]");
        System.out.flush();

        // 3. Validate
        SecurityContext context = authenticateRequestUseCase.evaluateRequest(remoteAddress, hostHeader, tokenHeader);

        System.out.println(">>> [SecurityFilter] Auth Status: " + context.isAuthenticated() + "\n");
        System.out.flush();

        if (!context.isAuthenticated()) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write(
                    "{\"success\":false,\"message\":\"Unauthorized: Local loopback or valid pairing token required.\"}");
            return; // Block execution
        }

        filterChain.doFilter(request, response);
    }
} */