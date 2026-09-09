package com.localbridge.localbridge.infrastructure.http;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PipedInputStream;
import java.io.PipedOutputStream;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;

@Service
public class PhoneHttpRelayService {
    private static final long PHONE_TIMEOUT_SECONDS = 90;
    private static final int PIPE_BUFFER_SIZE = 64 * 1024;

    private final BlockingQueue<PhoneCommand> commands = new LinkedBlockingQueue<>();
    private final Map<String, CompletableFuture<JsonNode>> pendingRequests = new ConcurrentHashMap<>();
    private final Map<String, PhoneDownloadSession> downloads = new ConcurrentHashMap<>();
    private volatile long lastPhonePoll;
    private volatile String phoneServerUrl;
    private volatile String phoneServerToken;

    public void connect() {
        lastPhonePoll = System.currentTimeMillis();
    }

    public void disconnect() {
        lastPhonePoll = 0;
        phoneServerUrl = null;
        phoneServerToken = null;
        commands.clear();
        pendingRequests.values().forEach(future -> future.completeExceptionally(
                new IllegalStateException("Phone disconnected")));
        pendingRequests.clear();
        downloads.values().forEach(session -> session.fail(new IOException("Phone disconnected")));
        downloads.clear();
    }

    public boolean isPhoneConnected() {
        boolean relayConnected = lastPhonePoll > 0
                && System.currentTimeMillis() - lastPhonePoll < TimeUnit.SECONDS.toMillis(PHONE_TIMEOUT_SECONDS);
        return relayConnected || phoneServerUrl != null;
    }

    public void registerPhoneServer(String url, String token) {
        if (url == null || url.isBlank() ||
                !(url.startsWith("http://") || url.startsWith("https://"))) {
            throw new IllegalArgumentException("Invalid phone server URL");
        }
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("Missing phone server token");
        }
        phoneServerUrl = url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
        phoneServerToken = token;
        lastPhonePoll = System.currentTimeMillis();
        clearRelayWork("Direct phone server mode enabled");
    }

    private void clearRelayWork(String reason) {
        commands.clear();
        pendingRequests.values().forEach(future -> future.completeExceptionally(
                new IllegalStateException(reason)));
        pendingRequests.clear();
        downloads.values().forEach(session -> session.fail(new IOException(reason)));
        downloads.clear();
    }

    public void unregisterPhoneServer() {
        phoneServerUrl = null;
        phoneServerToken = null;
    }

    public String getPhoneServerUrl() {
        return phoneServerUrl;
    }

    public String getPhoneServerToken() {
        return phoneServerToken;
    }

    public PhoneCommand pollCommand() throws InterruptedException {
        lastPhonePoll = System.currentTimeMillis();
        PhoneCommand command = commands.poll(35, TimeUnit.SECONDS);
        lastPhonePoll = System.currentTimeMillis();
        return command;
    }

    public JsonNode request(String type, String path) {
        if (!isPhoneConnected()) {
            throw new IllegalStateException("Phone is not connected");
        }
        String requestId = UUID.randomUUID().toString();
        CompletableFuture<JsonNode> future = new CompletableFuture<>();
        pendingRequests.put(requestId, future);
        commands.add(new PhoneCommand(requestId, type, path == null ? "" : path));
        try {
            return future.get(60, TimeUnit.SECONDS);
        } catch (Exception exception) {
            pendingRequests.remove(requestId);
            throw new IllegalStateException("Phone did not respond", exception);
        }
    }

    public PhoneDownloadSession startDownload(String path) {
        if (!isPhoneConnected()) {
            throw new IllegalStateException("Phone is not connected");
        }
        String requestId = UUID.randomUUID().toString();
        PhoneDownloadSession session = new PhoneDownloadSession(requestId);
        downloads.put(requestId, session);
        commands.add(new PhoneCommand(requestId, "download_phone_file", path == null ? "" : path));
        return session;
    }

    public void complete(JsonNode message) {
        String requestId = message.path("requestId").asText("");
        PhoneDownloadSession download = downloads.get(requestId);
        if (download != null) {
            if (message.has("error")) {
                download.fail(new IllegalStateException(message.path("error").asText()));
            }
            return;
        }

        CompletableFuture<JsonNode> future = pendingRequests.remove(requestId);
        if (future != null) {
            future.complete(message);
        }
    }

    public void acceptDownload(String requestId, String fileName, String contentType, InputStream input)
            throws IOException {
        PhoneDownloadSession session = downloads.get(requestId);
        if (session == null) {
            throw new IllegalArgumentException("Unknown phone download request");
        }
        session.setMetadata(fileName, contentType);
        try (InputStream source = input; OutputStream target = session.output()) {
            source.transferTo(target);
        } catch (IOException exception) {
            session.fail(exception);
            throw exception;
        } finally {
            downloads.remove(requestId);
        }
    }

    public record PhoneCommand(String requestId, String type, String path) {
    }

    public final class PhoneDownloadSession {
        private final PipedInputStream input;
        private final PipedOutputStream output;
        private final CompletableFuture<PhoneFileMetadata> metadata = new CompletableFuture<>();
        private final String requestId;

        private PhoneDownloadSession(String requestId) {
            this.requestId = requestId;
            try {
                output = new PipedOutputStream();
                input = new PipedInputStream(output, PIPE_BUFFER_SIZE);
            } catch (IOException exception) {
                throw new IllegalStateException("Could not create phone download stream", exception);
            }
        }

        public PhoneFileMetadata awaitMetadata() throws Exception {
            return metadata.get(60, TimeUnit.SECONDS);
        }

        public void writeTo(OutputStream target) throws IOException {
            try (InputStream source = input) {
                source.transferTo(target);
            } finally {
                downloads.remove(requestId);
            }
        }

        private OutputStream output() {
            return output;
        }

        private void setMetadata(String fileName, String contentType) {
            metadata.complete(new PhoneFileMetadata(
                    decodeHeader(fileName, "download"),
                    contentType == null || contentType.isBlank()
                            ? "application/octet-stream"
                            : contentType));
        }

        private void fail(Throwable error) {
            metadata.completeExceptionally(error);
            try {
                output.close();
            } catch (IOException ignored) {
            }
        }
    }

    public record PhoneFileMetadata(String fileName, String contentType) {
    }

    private String decodeHeader(String value, String fallback) {
        if (value == null || value.isBlank()) {
            return fallback;
        }
        try {
            return URLDecoder.decode(value, StandardCharsets.UTF_8);
        } catch (IllegalArgumentException exception) {
            return value;
        }
    }
}
