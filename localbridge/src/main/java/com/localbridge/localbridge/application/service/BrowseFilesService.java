package com.localbridge.localbridge.application.service;

import com.localbridge.localbridge.application.port.inbound.BrowseFilesUseCase;
import com.localbridge.localbridge.application.port.outbound.FileStoragePort;
import com.localbridge.localbridge.domain.model.FileNode;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.List;

@Service
public class BrowseFilesService implements BrowseFilesUseCase {

    private final FileStoragePort fileStoragePort;

    public BrowseFilesService(FileStoragePort fileStoragePort) {
        this.fileStoragePort = fileStoragePort;
    }

    @Override
    public List<FileNode> getDirectoryContents(String subPath) throws IOException {
        // Intercept root requests to show "This PC" (machine drives)
        if (subPath == null || subPath.trim().isEmpty() || subPath.equals("/") || subPath.equalsIgnoreCase("ROOT")) {
            return fileStoragePort.listRootDrives();
        }
        return fileStoragePort.listDirectory(subPath);
    }

    @Override
    public void uploadFile(String subPath, MultipartFile file) throws IOException {
        fileStoragePort.saveFile(subPath, file);
    }
}