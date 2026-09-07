package com.localbridge.localbridge.application.port.outbound;

import com.localbridge.localbridge.domain.model.FileNode;
import java.io.IOException;
import java.util.List;

import org.springframework.web.multipart.MultipartFile;

public interface FileStoragePort {
    List<FileNode> listDirectory(String subPath) throws IOException;
    void saveFile(String subPath, MultipartFile file) throws IOException;
}