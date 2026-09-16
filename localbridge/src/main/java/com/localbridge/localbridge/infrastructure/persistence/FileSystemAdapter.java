package com.localbridge.localbridge.infrastructure.persistence;

import com.localbridge.localbridge.application.port.outbound.FileStoragePort;
import com.localbridge.localbridge.domain.exception.PathTraversalException;
import com.localbridge.localbridge.domain.model.FileNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

@Component
public class FileSystemAdapter implements FileStoragePort {

    private final Path fallbackRootDir;

    public FileSystemAdapter(
            @Value("${localbridge.storage.root:#{systemProperties['user.home'] + '/LocalBridge'}}") String rootPath) {
        this.fallbackRootDir = Paths.get(rootPath).toAbsolutePath().normalize();
    }

    @Override
    public List<FileNode> listRootDrives() throws IOException {
        List<FileNode> nodes = new ArrayList<>();
        File[] roots = File.listRoots(); // Gets C:\, D:\ on Windows, or / on Linux/Mac

        if (roots != null) {
            for (File root : roots) {
                try {
                    Path path = root.toPath();
                    // Exclude drives that aren't ready or readable
                    if (!Files.exists(path) || !Files.isReadable(path)) {
                        continue;
                    }
                    BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
                    String name = root.getAbsolutePath();

                    nodes.add(new FileNode(
                            name, // The display name (e.g. C:\)
                            name, // The path to send back for the next request
                            true,
                            0,
                            attrs.lastModifiedTime().toMillis()));
                } catch (Exception e) {
                    // Quietly skip drives that throw security/access exceptions
                }
            }
        }
        return nodes;
    }

    @Override
    public List<FileNode> listDirectory(String subPath) throws IOException {
        Path targetPath;

        // Resolve default/root directory requests to the fallback root
        // (C:\Users\lenovo\LocalBridge)
        if (subPath == null || subPath.trim().isEmpty() || subPath.equalsIgnoreCase("LocalBridge")
                || subPath.equalsIgnoreCase("ROOT")) {
            targetPath = fallbackRootDir;
        } else {
            targetPath = Paths.get(subPath).normalize();
        }

        if (!Files.exists(targetPath) || !Files.isDirectory(targetPath)) {
            throw new IllegalArgumentException("Directory does not exist or is not a folder.");
        }

        if (!targetPath.isAbsolute()) {
            throw new PathTraversalException("Access denied: Absolute path required.");
        }

        List<FileNode> nodes = new ArrayList<>();
        try (Stream<Path> stream = Files.list(targetPath)) {
            stream.forEach(path -> {
                try {
                    String name = path.getFileName().toString();

                    if (isHiddenOrFilesEntry(name) || Files.isHidden(path) || !Files.isReadable(path)) {
                        return;
                    }

                    BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
                    String absolutePathStr = path.toAbsolutePath().toString().replace("\\", "/");

                    nodes.add(new FileNode(
                            name,
                            absolutePathStr,
                            attrs.isDirectory(),
                            attrs.isDirectory() ? 0 : attrs.size(),
                            attrs.lastModifiedTime().toMillis()));
                } catch (IOException | SecurityException e) {
                    // Skip unreadable files gracefully
                }
            });
        } catch (AccessDeniedException e) {
            throw new IllegalArgumentException("Access denied to folder: " + targetPath.toString());
        }

        return nodes;
    }
    @Override
    public void saveFile(String subPath, MultipartFile file) throws IOException {
        Path targetDir;

        // If uploading to "This PC" directly (or ROOT), store in default
        // C:\Users\lenovo\LocalBridge
        if (subPath == null || subPath.trim().isEmpty() || subPath.equals("/") || subPath.equalsIgnoreCase("ROOT")) {
            targetDir = fallbackRootDir;
        } else {
            targetDir = Paths.get(subPath).normalize();
            if (!targetDir.isAbsolute()) {
                throw new PathTraversalException("Access denied: Invalid target directory.");
            }
        }

        if (!Files.exists(targetDir)) {
            Files.createDirectories(targetDir);
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.trim().isEmpty()) {
            throw new IllegalArgumentException("Invalid file name.");
        }

        String safeName = Paths.get(originalFilename).getFileName().toString();
        if (isHiddenOrFilesEntry(safeName)) {
            throw new IllegalArgumentException("Hidden files are not allowed.");
        }

        Path destinationFile = targetDir.resolve(safeName).normalize();

        // Ensure the resolved destination file hasn't traversed out of the target
        // directory
        if (!destinationFile.getParent().normalize().equals(targetDir.normalize())) {
            throw new PathTraversalException("Access denied: Invalid target file path.");
        }

        try (var input = file.getInputStream()) {
            Files.copy(input, destinationFile, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private boolean isHiddenOrFilesEntry(String name) {
        return name.startsWith(".") || name.equalsIgnoreCase(".files");
    }
}