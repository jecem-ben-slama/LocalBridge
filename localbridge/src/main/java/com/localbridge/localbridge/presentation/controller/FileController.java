package com.localbridge.localbridge.presentation.controller;

import com.localbridge.localbridge.application.port.inbound.BrowseFilesUseCase;
import com.localbridge.localbridge.application.service.BrowseFilesService;
import com.localbridge.localbridge.application.service.SessionService;
import com.localbridge.localbridge.domain.exception.PathTraversalException;
import com.localbridge.localbridge.domain.model.FileNode;
import com.localbridge.localbridge.presentation.dto.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/api/files")
@CrossOrigin(origins = "*")
public class FileController {

    private final BrowseFilesUseCase browseFilesUseCase;
    private final BrowseFilesService browseFilesService;
    private final SessionService sessionService;
    private final Path rootDir;

    public FileController(
            BrowseFilesUseCase browseFilesUseCase,
            BrowseFilesService browseFilesService,
            SessionService sessionService,
            @Value("${localbridge.storage.root:#{systemProperties['user.home']}}") String rootPath) {
        this.browseFilesUseCase = browseFilesUseCase;
        this.browseFilesService = browseFilesService;
        this.sessionService = sessionService;
        this.rootDir = Paths.get(rootPath).toAbsolutePath().normalize();
    }

    @GetMapping("/list")
    public ResponseEntity<ApiResponse<List<FileNode>>> listFiles(
            @RequestParam(required = false) String path) {
        try {
            List<FileNode> files = browseFilesUseCase.getDirectoryContents(path);
            return ResponseEntity.ok(ApiResponse.success("Directory listed successfully", files));
        } catch (PathTraversalException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IOException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @PostMapping("/upload")
    public ResponseEntity<ApiResponse<Void>> uploadFile(
            @RequestParam(required = false) String path,
            @RequestParam("file") MultipartFile file,
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId != null && !sessionId.isEmpty()) {
            try {
                sessionService.recordTransferStart(sessionId);
            } catch (Exception ignored) {
                // Session tracking is best-effort and must not block transfers.
            }
        }

        try {
            browseFilesService.uploadFile(path, file);
            return ResponseEntity.ok(ApiResponse.success("File uploaded successfully", null));
        } catch (PathTraversalException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IOException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        } finally {
            if (sessionId != null && !sessionId.isEmpty()) {
                try {
                    sessionService.recordTransferEnd(sessionId);
                } catch (Exception ignored) {
                    // Ignore stale/expired session IDs so transfers keep working.
                }
            }
        }
    }

    @GetMapping("/download")
    public ResponseEntity<Resource> downloadFile(
            @RequestParam String path,
            @RequestHeader(value = "X-Session-Id", required = false) String sessionId) {
        if (sessionId != null && !sessionId.isEmpty()) {
            try {
                sessionService.recordTransferStart(sessionId);
            } catch (Exception ignored) {
                // Session tracking is best-effort and must not block downloads.
            }
        }

        try {
            Path targetPath = resolveExistingPath(path);
            if (targetPath == null || Files.isDirectory(targetPath)) {
                return ResponseEntity.status(403).build();
            }

            Resource resource = new UrlResource(targetPath.toUri());
            if (resource.exists() && resource.isReadable()) {
                return ResponseEntity.ok()
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header(HttpHeaders.CONTENT_DISPOSITION,
                                "attachment; filename=\"" + targetPath.getFileName().toString() + "\"")
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        } finally {
            if (sessionId != null && !sessionId.isEmpty()) {
                try {
                    sessionService.recordTransferEnd(sessionId);
                } catch (Exception ignored) {
                    // Ignore stale/expired session IDs so downloads keep working.
                }
            }
        }
    }

    @GetMapping("/preview")
    public ResponseEntity<Resource> previewFile(@RequestParam String path) {
        try {
            Path targetPath = resolveExistingPath(path);
            if (targetPath == null || Files.isDirectory(targetPath)) {
                return ResponseEntity.notFound().build();
            }

            Resource resource = new UrlResource(targetPath.toUri());
            if (resource.exists() && resource.isReadable()) {
                String contentType = Files.probeContentType(targetPath);
                if (contentType == null) {
                    contentType = MediaType.APPLICATION_OCTET_STREAM_VALUE;
                }

                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(contentType))
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (IOException e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    private Path resolveExistingPath(String path) throws IOException {
        Path target = rootDir.resolve(path).normalize();
        if (!target.startsWith(rootDir) || !Files.exists(target, LinkOption.NOFOLLOW_LINKS))
            return null;
        Path realTarget = target.toRealPath();
        if (!realTarget.startsWith(rootDir.toRealPath()))
            return null;
        Path relative = rootDir.toRealPath().relativize(realTarget);
        for (Path part : relative) {
            if (isHiddenOrFilesEntry(part.toString()))
                return null;
        }
        return realTarget;
    }

    private boolean isHiddenOrFilesEntry(String name) {
        return name.startsWith(".") || name.equalsIgnoreCase(".files");
    }
}