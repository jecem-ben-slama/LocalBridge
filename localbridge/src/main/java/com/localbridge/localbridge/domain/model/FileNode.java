package com.localbridge.localbridge.domain.model;

public record FileNode(
        String name,
        String path,
        boolean isDirectory,
        long size,
        long lastModified) {
}