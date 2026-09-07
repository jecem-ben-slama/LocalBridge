package com.localbridge.localbridge.application.port.outbound;

public interface TokenManagerPort {
    boolean validateToken(String token);

    String generatePairingToken();
}