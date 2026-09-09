package com.localbridge.localbridge.infrastructure.security;

import com.localbridge.localbridge.application.port.outbound.TokenManagerPort;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class TokenManager implements TokenManagerPort {
    private static final String CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int PAIRING_CODE_LENGTH = 6;
    private static final SecureRandom RANDOM = new SecureRandom();

    private final String serverToken;
    // Map storing token -> expiration timestamp (null/0 = non-expiring paired
    // device)
    private final ConcurrentHashMap<String, Long> activeTokens = new ConcurrentHashMap<>();

    public TokenManager() {
        this.serverToken = UUID.randomUUID().toString();
    }

    @Override
    public boolean validateToken(String token) {
        if (token == null || token.isBlank()) {
            return false;
        }

        if (token.equals(serverToken)) {
            return true;
        }

        Long expiry = activeTokens.get(token);
        if (expiry == null) {
            return false;
        }

        if (expiry == Long.MAX_VALUE || System.currentTimeMillis() < expiry) {
            activeTokens.put(token, Long.MAX_VALUE);
            return true;
        }

        activeTokens.remove(token);
        return false;
    }

    @Override
    public String generatePairingToken() {
        activeTokens.entrySet().removeIf(entry -> entry.getValue() != Long.MAX_VALUE
                && System.currentTimeMillis() >= entry.getValue());

        String pairingCode;
        do {
            pairingCode = generatePairingCode();
        } while (activeTokens.containsKey(pairingCode));

        // 5-minute window to complete initial scan
        activeTokens.put(pairingCode, System.currentTimeMillis() + 300000);
        return pairingCode;
    }

    public String getServerToken() {
        return serverToken;
    }

    private String generatePairingCode() {
        StringBuilder code = new StringBuilder(PAIRING_CODE_LENGTH);
        for (int i = 0; i < PAIRING_CODE_LENGTH; i++) {
            int index = RANDOM.nextInt(CODE_ALPHABET.length());
            code.append(CODE_ALPHABET.charAt(index));
        }
        return code.toString();
    }
}