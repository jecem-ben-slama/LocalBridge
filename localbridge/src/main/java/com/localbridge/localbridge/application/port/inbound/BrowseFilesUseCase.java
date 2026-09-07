package com.localbridge.localbridge.application.port.inbound;

import com.localbridge.localbridge.domain.model.FileNode;
import java.io.IOException;
import java.util.List;

public interface BrowseFilesUseCase {
    List<FileNode> getDirectoryContents(String subPath) throws IOException;
}