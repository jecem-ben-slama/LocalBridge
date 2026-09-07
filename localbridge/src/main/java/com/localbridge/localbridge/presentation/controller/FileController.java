package com.localbridge.localbridge.presentation.controller;

import com.localbridge.localbridge.application.port.inbound.BrowseFilesUseCase;
import com.localbridge.localbridge.application.service.BrowseFilesService;
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
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

@RestController
@RequestMapping("/api/files")
public class FileController {

    private final BrowseFilesUseCase browseFilesUseCase;
    private final BrowseFilesService browseFilesService;
    private final Path rootDir;

    public FileController(
            BrowseFilesUseCase browseFilesUseCase,
            BrowseFilesService browseFilesService,
            @Value("${localbridge.storage.root:#{systemProperties['user.home']}}") String rootPath) {
        this.browseFilesUseCase = browseFilesUseCase;
        this.browseFilesService = browseFilesService;
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
            @RequestParam("file") MultipartFile file) {
        try {
            browseFilesService.uploadFile(path, file);
            return ResponseEntity.ok(ApiResponse.success("File uploaded successfully", null));
        } catch (PathTraversalException e) {
            return ResponseEntity.status(403).body(ApiResponse.error(e.getMessage()));
        } catch (IOException | IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(ApiResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/download")
    public ResponseEntity<Resource> downloadFile(@RequestParam String path) {
        try {
            Path targetPath = rootDir.resolve(path).normalize();
            if (!targetPath.startsWith(rootDir) || !Files.exists(targetPath) || Files.isDirectory(targetPath)) {
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
        }
    }

    @GetMapping("/preview")
    public ResponseEntity<Resource> previewFile(@RequestParam String path) {
        try {
            Path targetPath = rootDir.resolve(path).normalize();

            if (!targetPath.startsWith(rootDir)) {
                return ResponseEntity.status(403).build();
            }

            if (!Files.exists(targetPath) || Files.isDirectory(targetPath)) {
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
}