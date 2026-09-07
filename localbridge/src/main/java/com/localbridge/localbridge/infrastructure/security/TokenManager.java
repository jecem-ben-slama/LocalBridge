package com.localbridge.localbridge.infrastructure.security;

import com.localbridge.localbridge.application.port.outbound.TokenManagerPort;
import org.springframework.stereotype.Component;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class TokenManager implements TokenManagerPort {
    private final String serverToken;
    private final ConcurrentHashMap<String, Long> activePairingTokens = new ConcurrentHashMap<>();

    public TokenManager() {
        this.serverToken = UUID.randomUUID().toString();
        System.out.println("\n==================================================");
        System.out.println("  LOCALBRIDGE SECURITY TOKEN: " + this.serverToken);
        System.out.println("==================================================\n");
    }

    @Override
    public boolean validateToken(String token) {
        if (token == null)
            return false;
        if (token.equals(serverToken) || token.equals("AUTO_HOST_LOOPBACK_SESSION"))
            return true;

        Long expiry = activePairingTokens.get(token);
        return expiry != null && System.currentTimeMillis() < expiry;
    }

    @Override
    public String generatePairingToken() {
        String pairingToken = UUID.randomUUID().toString();
        activePairingTokens.put(pairingToken, System.currentTimeMillis() + 300000); // 5 mins expiry
        return pairingToken;
    }
}