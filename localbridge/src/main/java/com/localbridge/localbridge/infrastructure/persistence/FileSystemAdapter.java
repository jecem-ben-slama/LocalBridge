package com.localbridge.localbridge.infrastructure.persistence;

import com.localbridge.localbridge.application.port.outbound.FileStoragePort;
import com.localbridge.localbridge.domain.exception.PathTraversalException;
import com.localbridge.localbridge.domain.model.FileNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.*;
import java.nio.file.attribute.BasicFileAttributes;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

@Component
public class FileSystemAdapter implements FileStoragePort {

    private final Path rootDir;

    public FileSystemAdapter(@Value("${localbridge.storage.root:#{systemProperties['user.home']}}") String rootPath) {
        this.rootDir = Paths.get(rootPath).toAbsolutePath().normalize();
    }

    @Override
    public List<FileNode> listDirectory(String subPath) throws IOException {
        Path targetPath;

        if (subPath == null || subPath.trim().isEmpty() || subPath.equals("/")) {
            targetPath = rootDir;
        } else {
            targetPath = rootDir.resolve(subPath).normalize();
        }

        if (!targetPath.startsWith(rootDir)) {
            throw new PathTraversalException("Access denied: Path traversal attempt detected.");
        }

        if ("LocalBridge".equals(subPath) && !Files.exists(targetPath)) {
            Files.createDirectories(targetPath);
        }

        if (!Files.exists(targetPath) || !Files.isDirectory(targetPath)) {
            throw new IllegalArgumentException("Directory does not exist or is not a folder.");
        }

        List<FileNode> nodes = new ArrayList<>();
        try (Stream<Path> stream = Files.list(targetPath)) {
            stream.forEach(path -> {
                try {
                    BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
                    String name = path.getFileName().toString();
                    if (isHiddenOrFilesEntry(name))
                        return;
                    String relativePath = rootDir.relativize(path).toString().replace("\\", "/");

                    nodes.add(new FileNode(
                            name,
                            relativePath,
                            attrs.isDirectory(),
                            attrs.isDirectory() ? 0 : attrs.size(),
                            attrs.lastModifiedTime().toMillis()));
                } catch (IOException e) {
                    // Skip unreadable files
                }
            });
        }

        return nodes;
    }

    @Override
    public void saveFile(String subPath, MultipartFile file) throws IOException {
        Path targetDir = (subPath == null || subPath.trim().isEmpty() || subPath.equals("/"))
                ? rootDir.resolve("LocalBridge")
                : rootDir.resolve(subPath).normalize();

        if (!targetDir.startsWith(rootDir) || !isWithinRealRoot(targetDir, true)) {
            throw new PathTraversalException("Access denied: Path traversal attempt detected.");
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
        if (!destinationFile.startsWith(rootDir) || !isWithinRealRoot(destinationFile, true)) {
            throw new PathTraversalException("Access denied: Invalid target file path.");
        }

        try (var input = file.getInputStream()) {
            Files.copy(input, destinationFile, StandardCopyOption.REPLACE_EXISTING);
        }
    }

    private boolean isWithinRealRoot(Path path, boolean allowMissingLeaf) throws IOException {
        Path realRoot = rootDir.toRealPath();
        Path realPath;
        if (allowMissingLeaf && !Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
            Path parent = path.getParent();
            realPath = parent.toRealPath().resolve(path.getFileName()).normalize();
        } else {
            realPath = path.toRealPath();
        }
        return realPath.startsWith(realRoot);
    }

    private boolean isHiddenOrFilesEntry(String name) {
        return name.startsWith(".") || name.equalsIgnoreCase(".files");
    }
}