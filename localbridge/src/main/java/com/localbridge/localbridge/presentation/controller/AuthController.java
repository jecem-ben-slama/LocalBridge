package com.localbridge.localbridge.presentation.controller;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.localbridge.localbridge.infrastructure.security.TokenManager;

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Enumeration;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    private final TokenManager tokenManager;

    public AuthController(TokenManager tokenManager) {
        this.tokenManager = tokenManager;
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyToken(@RequestBody Map<String, String> payload) {
        String token = payload.get("token");
        if (tokenManager.validateToken(token)) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Token verified successfully"));
        }
        return ResponseEntity.status(401).body(Map.of(
                "success", false,
                "message", "Invalid or expired token"));
    }

    @GetMapping("/pairing-url")
    public ResponseEntity<?> getPairingUrl(HttpServletRequest request) {
        try {
            // Generate a short pairing code for manual entry and QR scanning.
            String pairingCode = tokenManager.generatePairingToken();

            // Resolve host LAN IP accurately
            String hostIp = getBestLanIp(request);
            int port = request.getServerPort();

            // Build URL that mobile app can scan.
            String pairingUrl = String.format("http://%s:%d/?pairing_token=%s", hostIp, port, pairingCode);

            return ResponseEntity.ok(Map.of(
                    "pairingUrl", pairingUrl,
                    "pairingToken", pairingCode,
                    "pairingCode", pairingCode,
                    "hostIp", hostIp,
                    "port", port));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("error", "Could not generate pairing URL"));
        }
    }

    /**
     * Finds the real LAN IPv4 address (e.g. 192.168.x.x) avoiding loopback or
     * virtual adapters.
     */
    private String getBestLanIp(HttpServletRequest request) {
        try {
            Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
            while (interfaces.hasMoreElements()) {
                NetworkInterface ni = interfaces.nextElement();
                String name = ni.getDisplayName().toLowerCase();

                // Ignore loopback, down, and virtual adapters (WSL, Hyper-V, Docker, VMware)
                if (!ni.isUp() || ni.isLoopback() || ni.isVirtual() ||
                        name.contains("wsl") || name.contains("vethernet") ||
                        name.contains("hyper-v") || name.contains("docker") ||
                        name.contains("vmnet") || name.contains("virtualbox")) {
                    continue;
                }

                Enumeration<InetAddress> addresses = ni.getInetAddresses();
                while (addresses.hasMoreElements()) {
                    InetAddress addr = addresses.nextElement();
                    if (addr instanceof Inet4Address && !addr.isLoopbackAddress()) {
                        String ip = addr.getHostAddress();
                        // Prefer standard home LAN IP ranges (192.168.x.x or 10.x.x.x)
                        if (ip.startsWith("192.168.") || ip.startsWith("10.")) {
                            return ip;
                        }
                    }
                }
            }
        } catch (Exception ignored) {
        }

        // Fallback if request contains valid IP
        String localAddr = request.getLocalAddr();
        if (localAddr != null && !localAddr.startsWith("127.") && !localAddr.startsWith("172.")) {
            return localAddr;
        }

        return "127.0.0.1";
    }
}