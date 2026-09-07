package com.localbridge.localbridge.presentation.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.localbridge.localbridge.infrastructure.security.TokenManager;

import java.net.InetAddress;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final TokenManager tokenManager;

    public AuthController(TokenManager tokenManager) {
        this.tokenManager = tokenManager;
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyToken(@RequestBody Map<String, String> payload) {
        String token = payload.get("token");
        if (tokenManager.validateToken(token)) {
            return ResponseEntity.ok(Map.of("success", true, "message", "Token verified successfully"));
        }
        return ResponseEntity.status(401).body(Map.of("success", false, "message", "Invalid or expired token"));
    }

    @GetMapping("/pairing-url")
    public ResponseEntity<?> getPairingUrl(HttpServletRequest request) {
        try {
            String pairingToken = tokenManager.generatePairingToken();
            String hostIp = InetAddress.getLocalHost().getHostAddress();
            int port = request.getServerPort();

            // Build URL that phones on the same Wi-Fi can scan
            String pairingUrl = String.format("http://%s:%d/?pairing_token=%s", hostIp, port, pairingToken);

            return ResponseEntity.ok(Map.of("pairingUrl", pairingUrl));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Could not generate pairing URL"));
        }
    }
}