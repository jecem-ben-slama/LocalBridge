package com.localbridge.localbridge.domain.model;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Represents an active user session with transfer tracking.
 * Sessions automatically expire after inactivity period and are cleaned up.
 */
public class Session {
    private String sessionId;
    private String deviceId;
    private String deviceName;
    private LocalDateTime createdAt;
    private LocalDateTime lastActivityAt;
    private boolean active;
    private int activeTransfers;

    public Session(String deviceId, String deviceName) {
        this.sessionId = UUID.randomUUID().toString();
        this.deviceId = deviceId;
        this.deviceName = deviceName;
        this.createdAt = LocalDateTime.now();
        this.lastActivityAt = LocalDateTime.now();
        this.active = true;
        this.activeTransfers = 0;
    }

    public void recordActivity() {
        this.lastActivityAt = LocalDateTime.now();
    }

    public void incrementTransfers() {
        this.activeTransfers++;
    }

    public void decrementTransfers() {
        if (this.activeTransfers > 0) {
            this.activeTransfers--;
        }
    }

    public boolean isExpired(int inactivityTimeoutSeconds) {
        LocalDateTime expirationTime = lastActivityAt.plusSeconds(inactivityTimeoutSeconds);
        return LocalDateTime.now().isAfter(expirationTime);
    }

    // Getters and setters
    public String getSessionId() {
        return sessionId;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public String getDeviceName() {
        return deviceName;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public LocalDateTime getLastActivityAt() {
        return lastActivityAt;
    }

    public boolean isActive() {
        return active;
    }

    public int getActiveTransfers() {
        return activeTransfers;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
