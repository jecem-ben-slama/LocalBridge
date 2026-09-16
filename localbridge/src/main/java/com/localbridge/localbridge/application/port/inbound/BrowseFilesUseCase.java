package com.localbridge.localbridge.application.port.inbound;

import com.localbridge.localbridge.domain.model.FileNode;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.List;

public interface BrowseFilesUseCase {
    List<FileNode> getDirectoryContents(String subPath) throws IOException;

    void uploadFile(String subPath, MultipartFile file) throws IOException;
}