package com.localbridge.localbridge.infrastructure.persistence;

import com.localbridge.localbridge.application.port.SessionRepository;
import com.localbridge.localbridge.domain.model.Session;
import org.springframework.stereotype.Repository;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * In-memory implementation of SessionRepository.
 * Stores sessions in memory using ConcurrentHashMap.
 * Can be replaced with a database-backed implementation for persistence.
 */
@Repository
public class InMemorySessionRepository implements SessionRepository {
    private final Map<String, Session> sessionsBySessionId = new ConcurrentHashMap<>();
    private final Map<String, Session> sessionsByDeviceId = new ConcurrentHashMap<>();

    @Override
    public void save(Session session) {
        sessionsBySessionId.put(session.getSessionId(), session);
        sessionsByDeviceId.put(session.getDeviceId(), session);
    }

    @Override
    public Optional<Session> findBySessionId(String sessionId) {
        return Optional.ofNullable(sessionsBySessionId.get(sessionId));
    }

    @Override
    public Optional<Session> findByDeviceId(String deviceId) {
        return Optional.ofNullable(sessionsByDeviceId.get(deviceId));
    }

    @Override
    public List<Session> findAllActive() {
        return sessionsBySessionId.values().stream()
                .filter(Session::isActive)
                .collect(Collectors.toList());
    }

    @Override
    public void update(Session session) {
        sessionsBySessionId.put(session.getSessionId(), session);
        sessionsByDeviceId.put(session.getDeviceId(), session);
    }

    @Override
    public void delete(String sessionId) {
        Session session = sessionsBySessionId.remove(sessionId);
        if (session != null) {
            sessionsByDeviceId.remove(session.getDeviceId());
        }
    }

    @Override
    public void deleteExpired(int inactivityTimeoutSeconds) {
        sessionsBySessionId.values().removeIf(s -> s.isExpired(inactivityTimeoutSeconds));
        sessionsByDeviceId.values().removeIf(s -> s.isExpired(inactivityTimeoutSeconds));
    }
}
