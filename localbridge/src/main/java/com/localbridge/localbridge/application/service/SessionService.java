package com.localbridge.localbridge.application.service;

import com.localbridge.localbridge.application.port.SessionRepository;
import com.localbridge.localbridge.domain.model.Session;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.List;
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
        Optional<Session> existingSession = sessionRepository.findByDeviceId(deviceId);
        if (existingSession.isPresent()) {
            Session session = existingSession.get();
            if (session.isActive() && !session.isExpired(inactivityTimeoutSeconds)) {
                session.recordActivity();
                sessionRepository.update(session);
                return session;
            }
            // Stale/closed session for this device — don't resurrect it, replace it.
            sessionRepository.delete(session.getSessionId());
        }

        Session session = new Session(deviceId, deviceName);
        sessionRepository.save(session);
        return session;
    }

    public Session getOrCreateSession(String deviceId, String deviceName) {
        return sessionRepository.findByDeviceId(deviceId)
                .filter(s -> s.isActive() && !s.isExpired(inactivityTimeoutSeconds))
                .orElseGet(() -> createSession(deviceId, deviceName));
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
     * Returns active sessions that have gone idle past the configured
     * timeout (transfers in progress never count as idle — see
     * Session.isExpired). Used by the scheduled sweep to react to idle
     * sessions (e.g. disconnect the phone relay) BEFORE they're deleted,
     * since cleanupExpiredSessions()/deleteExpired() only removes the
     * records and has no way to notify anything else.
     */
    public List<Session> findExpiredActiveSessions() {
        return sessionRepository.findAllActive().stream()
                .filter(s -> s.isExpired(inactivityTimeoutSeconds))
                .toList();
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