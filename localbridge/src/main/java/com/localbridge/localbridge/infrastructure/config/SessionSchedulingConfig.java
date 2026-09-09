package com.localbridge.localbridge.infrastructure.config;

import com.localbridge.localbridge.application.service.SessionService;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Scheduled tasks for session management.
 * Periodically cleans up expired sessions.
 */
@Component
@Configuration
@EnableScheduling
public class SessionSchedulingConfig {
    private final SessionService sessionService;

    public SessionSchedulingConfig(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    /**
     * Cleans up expired sessions every 5 minutes.
     */
    @Scheduled(fixedRate = 300000) // 5 minutes in milliseconds
    public void cleanupExpiredSessions() {
        try {
            sessionService.cleanupExpiredSessions();
        } catch (Exception e) {
            System.err.println("Error during session cleanup: " + e.getMessage());
        }
    }
}
