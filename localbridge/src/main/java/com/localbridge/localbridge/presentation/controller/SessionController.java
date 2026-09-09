package com.localbridge.localbridge.presentation.controller;

import com.localbridge.localbridge.application.service.SessionService;
import com.localbridge.localbridge.domain.model.Session;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.Optional;

/**
 * REST controller for session management.
 * Handles session creation, refresh, heartbeat, and lifecycle.
 */
@RestController
@RequestMapping("/api/session")
@CrossOrigin(origins = "*")
public class SessionController {
    private final SessionService sessionService;

    public SessionController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    /**
     * Creates or retrieves a session for a device.
     * POST /api/session/create
     */
    @PostMapping("/create")
    public ResponseEntity<?> createSession(@RequestBody Map<String, String> payload) {
        String deviceId = payload.get("deviceId");
        String deviceName = payload.get("deviceName");

        if (deviceId == null || deviceId.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "deviceId is required"));
        }

        try {
            Session session = sessionService.getOrCreateSession(
                    deviceId,
                    deviceName != null ? deviceName : "Unknown Device");

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "sessionId", session.getSessionId(),
                    "message", "Session created successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "message", "Failed to create session: " + e.getMessage()));
        }
    }

    /**
     * Sends heartbeat to keep session alive.
     * GET /api/session/heartbeat
     * Expects sessionId in header: X-Session-Id
     */
    @GetMapping("/heartbeat")
    public ResponseEntity<?> heartbeat(@RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "No session header; session tracking is optional for this connection"));
        }

        Optional<Session> sessionOpt = sessionService.refreshSession(sessionId);
        if (sessionOpt.isPresent()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Session heartbeat recorded"));
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Session not found; continuing without strict verification"));
    }

    /**
     * Refreshes the session to reset inactivity timeout.
     * POST /api/session/refresh
     */
    @PostMapping("/refresh")
    public ResponseEntity<?> refreshSession(@RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Session refresh skipped; connection does not require strict verification"));
        }

        Optional<Session> sessionOpt = sessionService.refreshSession(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Session refreshed",
                    "sessionId", session.getSessionId(),
                    "lastActivity", session.getLastActivityAt()));
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Session not found; continuing without strict verification"));
    }

    /**
     * Closes a session explicitly.
     * POST /api/session/close
     */
    @PostMapping("/close")
    public ResponseEntity<?> closeSession(@RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "No session to close; connection is not blocked by session verification"));
        }

        try {
            sessionService.closeSession(sessionId);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Session closed successfully"));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Session cleanup skipped after error: " + e.getMessage()));
        }
    }

    /**
     * Gets current session status.
     * GET /api/session/status
     */
    @GetMapping("/status")
    public ResponseEntity<?> getSessionStatus(
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId == null || sessionId.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "No session header; status check is informational only"));
        }

        Optional<Session> sessionOpt = sessionService.refreshSession(sessionId);
        if (sessionOpt.isPresent()) {
            Session session = sessionOpt.get();
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "sessionId", session.getSessionId(),
                    "active", session.isActive(),
                    "activeTransfers", session.getActiveTransfers(),
                    "lastActivity", session.getLastActivityAt(),
                    "createdAt", session.getCreatedAt()));
        }

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Session not found; status is non-blocking"));
    }
}
