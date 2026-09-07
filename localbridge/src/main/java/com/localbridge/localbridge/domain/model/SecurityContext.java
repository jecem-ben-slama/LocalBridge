package com.localbridge.localbridge.domain.model;

public record SecurityContext(
        boolean isAuthenticated,
        boolean isLocalLoopback,
        String identifier) {
    public static SecurityContext unauthorized() {
        return new SecurityContext(false, false, null);
    }

    public static SecurityContext trustedLocal() {
        return new SecurityContext(true, true, "LOCALHOST_LOOPBACK");
    }

    public static SecurityContext trustedDevice(String tokenId) {
        return new SecurityContext(true, false, tokenId);
    }
}