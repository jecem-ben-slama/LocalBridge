package com.localbridge.localbridge.application.service;

import com.localbridge.localbridge.application.port.SessionRepository;
import com.localbridge.localbridge.domain.model.Session;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.Optional;

/**
 * Application service for managing user sessions.
 * Handles session creation, refresh, and cleanup.
 */
@Service
public class SessionService {
    private final SessionRepository sessionRepository;

    @Value("${app.session.inactivity-timeout-seconds:3600}")
    private int inactivityTimeoutSeconds;

    public SessionService(SessionRepository sessionRepository) {
        this.sessionRepository = sessionRepository;
    }

    /**
     * Creates a new session for a device.
     */
    public Session createSession(String deviceId, String deviceName) {
        // Check if an existing session exists
        Optional<Session> existingSession = sessionRepository.findByDeviceId(deviceId);
        if (existingSession.isPresent()) {
            Session session = existingSession.get();
            session.recordActivity();
            sessionRepository.update(session);
            return session;
        }

        // Create new session
        Session session = new Session(deviceId, deviceName);
        sessionRepository.save(session);
        return session;
    }

    /**
     * Records activity for a session and resets inactivity timeout.
     */
    public Optional<Session> refreshSession(String sessionId) {
        Optional<Session> sessionOpt = sessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            session.recordActivity();
            sessionRepository.update(session);
        }
        return sessionOpt;
    }

    /**
     * Gets or creates a session (idempotent).
     */
    public Session getOrCreateSession(String deviceId, String deviceName) {
        return sessionRepository.findByDeviceId(deviceId)
                .orElseGet(() -> createSession(deviceId, deviceName));
    }

    /**
     * Closes a session.
     */
    public void closeSession(String sessionId) {
        Optional<Session> sessionOpt = sessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            session.setActive(false);
            sessionRepository.update(session);
        }
    }

    /**
     * Checks if a session is still valid.
     */
    public boolean isSessionValid(String sessionId) {
        Optional<Session> sessionOpt = sessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            if (!session.isActive() || session.isExpired(inactivityTimeoutSeconds)) {
                sessionRepository.delete(sessionId);
                return false;
            }
            return true;
        }
        return false;
    }

    /**
     * Cleans up expired sessions (should be called periodically).
     */
    public void cleanupExpiredSessions() {
        sessionRepository.deleteExpired(inactivityTimeoutSeconds);
    }

    /**
     * Increments the active transfer count for a session.
     */
    public void recordTransferStart(String sessionId) {
        Optional<Session> sessionOpt = sessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            session.incrementTransfers();
            session.recordActivity();
            sessionRepository.update(session);
        }
    }

    /**
     * Decrements the active transfer count for a session.
     */
    public void recordTransferEnd(String sessionId) {
        Optional<Session> sessionOpt = sessionRepository.findBySessionId(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            session.decrementTransfers();
            session.recordActivity();
            sessionRepository.update(session);
        }
    }
}
