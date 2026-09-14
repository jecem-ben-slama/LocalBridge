package com.localbridge.localbridge.infrastructure.config;

import com.localbridge.localbridge.application.service.SessionService;
import com.localbridge.localbridge.domain.model.Session;
import com.localbridge.localbridge.infrastructure.http.PhoneHttpRelayService;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Scheduled tasks for session management.
 * Periodically checks for idle sessions, disconnects the phone relay for
 * them, and cleans up expired session records.
 */
@Component
@Configuration
@EnableScheduling
public class SessionSchedulingConfig {
    private final SessionService sessionService;
    private final PhoneHttpRelayService relayService;

    public SessionSchedulingConfig(SessionService sessionService,
            PhoneHttpRelayService relayService) {
        this.sessionService = sessionService;
        this.relayService = relayService;
    }

    /**
     * Runs every 30s rather than every 5 minutes: with
     * app.session.inactivity-timeout-seconds set to something shorter than
     * 5 minutes (e.g. a few minutes), a 5-minute sweep interval would make
     * the actual cutoff far looser than configured. 30s keeps the effective
     * disconnect delay close to the configured timeout regardless of its
     * value.
     */
    @Scheduled(fixedRate = 30000)
    public void cleanupExpiredSessions() {
        try {
            List<Session> idleSessions = sessionService.findExpiredActiveSessions();
            if (!idleSessions.isEmpty()) {
                // Single-phone-connection model: any active session going
                // idle means the current relay/direct connection is idle.
                // This actually tears down phoneServerUrl/phoneServerToken
                // and fails pending relay work, so the PC's next
                // /api/phone/status poll reflects the disconnect within
                // its normal ~10s cadence, instead of waiting on the
                // relay's own internal poll-timeout window.
                relayService.disconnect();
            }
            sessionService.cleanupExpiredSessions();
        } catch (Exception e) {
            System.err.println("Error during session cleanup: " + e.getMessage());
        }
    }
}