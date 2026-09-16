package com.localbridge.localbridge.application.port.outbound;

import com.localbridge.localbridge.domain.model.FileNode;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.List;

public interface FileStoragePort {
    List<FileNode> listRootDrives() throws IOException;

    List<FileNode> listDirectory(String subPath) throws IOException;

    void saveFile(String subPath, MultipartFile file) throws IOException;
}