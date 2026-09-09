package com.localbridge.localbridge.application.port;

import com.localbridge.localbridge.domain.model.Session;
import java.util.Optional;
import java.util.List;

/**
 * Port for managing session persistence.
 */
public interface SessionRepository {
    void save(Session session);

    Optional<Session> findBySessionId(String sessionId);

    Optional<Session> findByDeviceId(String deviceId);

    List<Session> findAllActive();

    void update(Session session);

    void delete(String sessionId);

    void deleteExpired(int inactivityTimeoutSeconds);
}
