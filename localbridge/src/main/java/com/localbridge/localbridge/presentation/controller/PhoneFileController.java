package com.localbridge.localbridge.presentation.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.localbridge.localbridge.application.service.SessionService;
import com.localbridge.localbridge.infrastructure.http.PhoneHttpRelayService;
import com.localbridge.localbridge.domain.exception.PathTraversalException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.StreamingResponseBody;
import jakarta.servlet.http.HttpServletRequest;

import java.util.Map;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.nio.file.StandardCopyOption;

@RestController
@RequestMapping("/api/phone")
public class PhoneFileController {
    private final PhoneHttpRelayService relayService;
    private final SessionService sessionService;
    private final Path uploadedPhoneRoot;

    public PhoneFileController(
            PhoneHttpRelayService relayService,
            SessionService sessionService,
            @Value("${localbridge.storage.root:#{systemProperties['user.home']}}") String rootPath,
            @Value("${localbridge.storage.phone-root:}") String phoneRootPath) {
        this.relayService = relayService;
        this.sessionService = sessionService;
        Path root = Paths.get(rootPath).toAbsolutePath().normalize();
        uploadedPhoneRoot = phoneRootPath == null || phoneRootPath.isBlank()
                ? root.resolve("LocalBridge").normalize()
                : Paths.get(phoneRootPath).toAbsolutePath().normalize();
    }

    @GetMapping("/status")
    public ResponseEntity<?> status() {
        Map<String, Object> status = new LinkedHashMap<>();
        status.put("connected", relayService.isPhoneConnected());
        status.put("phoneServerUrl", relayService.getPhoneServerUrl());
        status.put("phoneServerToken", relayService.getPhoneServerToken());
        return ResponseEntity.ok(status);
    }

    @PostMapping("/server")
    public ResponseEntity<?> registerPhoneServer(@RequestBody Map<String, String> payload) {
        try {
            relayService.registerPhoneServer(payload.get("url"), payload.get("token"));
            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false, "message", exception.getMessage()));
        }
    }

    @DeleteMapping("/server")
    public ResponseEntity<?> unregisterPhoneServer() {
        relayService.unregisterPhoneServer();
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/connect")
    public ResponseEntity<?> connectPhone() {
        relayService.connect();
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/disconnect")
    public ResponseEntity<?> disconnectPhone() {
        relayService.disconnect();
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/commands")
    public ResponseEntity<?> pollCommand() {
        try {
            PhoneHttpRelayService.PhoneCommand command = relayService.pollCommand();
            return command == null
                    ? ResponseEntity.noContent().build()
                    : ResponseEntity.ok(command);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return ResponseEntity.noContent().build();
        }
    }

    @PostMapping("/commands/{requestId}/result")
    public ResponseEntity<?> completeCommand(
            @PathVariable String requestId,
            @RequestBody JsonNode response) {
        if (!response.isObject()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false, "message", "Command result must be a JSON object."));
        }
        ((com.fasterxml.jackson.databind.node.ObjectNode) response).put("requestId", requestId);
        relayService.complete(response);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/downloads/{requestId}/stream")
    public ResponseEntity<?> receiveDownload(
            @PathVariable String requestId,
            @RequestHeader(value = "X-Phone-File-Name", required = false) String fileName,
            @RequestHeader(value = "Content-Type", required = false) String contentType,
            HttpServletRequest request) {
        try {
            relayService.acceptDownload(requestId, fileName, contentType, request.getInputStream());
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception exception) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", exception.getMessage() == null ? "Phone download failed" : exception.getMessage()));
        }
    }

    @GetMapping("/list")
    public ResponseEntity<?> listFiles(@RequestParam(required = false) String path) {
        try {
            JsonNode response = relayService.request("list_phone_directory", path);
            if (response.has("error")) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", response.path("error").asText()));
            }
            JsonNode filesNode = response.path("files");
            if (!filesNode.isArray()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Phone returned an invalid directory listing."));
            }
            List<Map<String, Object>> files = new ArrayList<>();
            filesNode.forEach(fileNode -> {
                String name = fileNode.path("name").asText("");
                if (name.startsWith(".") || name.equalsIgnoreCase(".files"))
                    return;
                Map<String, Object> file = new LinkedHashMap<>();
                file.put("name", name);
                file.put("path", fileNode.path("path").asText(""));
                file.put("isDirectory", fileNode.path("isDirectory").asBoolean(false));
                file.put("size", fileNode.path("size").asLong(0));
                file.put("lastModified", fileNode.path("lastModified").asLong(0));
                files.add(file);
            });
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Phone directory listed successfully",
                    "data", files));
        } catch (Exception exception) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", exception.getMessage() == null
                            ? "Phone is not connected"
                            : exception.getMessage()));
        }
    }

    @PostMapping("/upload")
    public ResponseEntity<?> uploadFile(
            @RequestParam(required = false) String path,
            @RequestParam("file") MultipartFile file,
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        // Validate session if provided
        if (sessionId != null && !sessionId.isEmpty()) {
            if (!sessionService.isSessionValid(sessionId)) {
                return ResponseEntity.status(401).body(Map.of(
                        "success", false, "message", "Session expired or invalid"));
            }
            sessionService.recordTransferStart(sessionId);
        }

        try {
            Path targetDirectory = path == null || path.isBlank()
                    ? uploadedPhoneRoot
                    : uploadedPhoneRoot.resolve(path).normalize();
            if (!targetDirectory.startsWith(uploadedPhoneRoot)) {
                throw new PathTraversalException("Access denied: invalid upload path.");
            }
            String fileName = file.getOriginalFilename();
            if (fileName == null || fileName.isBlank()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false, "message", "Invalid file name"));
            }
            Files.createDirectories(targetDirectory);
            if (!isWithinRealRoot(targetDirectory, false)) {
                throw new PathTraversalException("Access denied: invalid upload path.");
            }
            String safeName = Paths.get(fileName).getFileName().toString();
            if (safeName.startsWith(".") || safeName.equalsIgnoreCase(".files")) {
                throw new IllegalArgumentException("Hidden files are not allowed.");
            }
            Path destination = targetDirectory.resolve(safeName).normalize();
            if (!destination.startsWith(uploadedPhoneRoot)
                    || !isWithinRealRoot(destination, true)) {
                throw new PathTraversalException("Access denied: invalid file path.");
            }
            try (var input = file.getInputStream()) {
                Files.copy(input, destination, StandardCopyOption.REPLACE_EXISTING);
            }
            if (sessionId != null && !sessionId.isEmpty()) {
                sessionService.recordTransferEnd(sessionId);
            }
            return ResponseEntity.ok(Map.of(
                    "success", true, "message", "Phone file uploaded successfully"));
        } catch (PathTraversalException exception) {
            if (sessionId != null && !sessionId.isEmpty()) {
                sessionService.recordTransferEnd(sessionId);
            }
            return ResponseEntity.status(403).body(Map.of(
                    "success", false, "message", exception.getMessage()));
        } catch (Exception exception) {
            if (sessionId != null && !sessionId.isEmpty()) {
                sessionService.recordTransferEnd(sessionId);
            }
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false, "message", exception.getMessage()));
        }
    }

    private boolean isWithinRealRoot(Path path, boolean allowMissingLeaf) throws Exception {
        Path realRoot = uploadedPhoneRoot.toRealPath();
        Path realPath;
        if (allowMissingLeaf && !Files.exists(path, java.nio.file.LinkOption.NOFOLLOW_LINKS)) {
            realPath = path.getParent().toRealPath().resolve(path.getFileName()).normalize();
        } else {
            realPath = path.toRealPath();
        }
        return realPath.startsWith(realRoot);
    }

    @GetMapping("/download")
    public ResponseEntity<?> downloadFile(
            @RequestParam String path,
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        return streamPhoneFileWithSession(path, true, sessionId);
    }

    @GetMapping("/preview")
    public ResponseEntity<?> previewFile(
            @RequestParam String path,
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        return streamPhoneFileWithSession(path, false, sessionId);
    }

    private ResponseEntity<?> streamPhoneFileWithSession(
            String path,
            boolean attachment,
            String sessionId) {
        if (sessionId != null && !sessionId.isEmpty()) {
            try {
                sessionService.recordTransferStart(sessionId);
            } catch (Exception ignored) {
                // Session tracking is advisory only; do not block phone transfers.
            }
        }

        try {
            PhoneHttpRelayService.PhoneDownloadSession session = relayService.startDownload(path);
            PhoneHttpRelayService.PhoneFileMetadata metadata = session.awaitMetadata();
            StreamingResponseBody body = session::writeTo;
            ResponseEntity.BodyBuilder response = ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(metadata.contentType()));
            if (attachment) {
                response.header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + metadata.fileName() + "\"");
            }
            return response.body(body);
        } catch (Exception exception) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", exception.getMessage() == null
                            ? "Phone is not connected"
                            : exception.getMessage()));
        } finally {
            if (sessionId != null && !sessionId.isEmpty()) {
                try {
                    sessionService.recordTransferEnd(sessionId);
                } catch (Exception ignored) {
                    // Ignore stale/expired session IDs so phone downloads continue.
                }
            }
        }
    }
}
