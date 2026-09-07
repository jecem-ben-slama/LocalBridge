import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:localbridge_mobile/data/services/api_services.dart';
import 'package:open_filex/open_filex.dart';
import '../../domain/models/file_node.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [const PcExplorerTab(), const PhoneExplorerTab()];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.computer),
            label: 'PC Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: 'Phone Files',
          ),
        ],
      ),
    );
  }
}

/// TAB 1: Explore PC Files (Download / Upload to PC)
class PcExplorerTab extends StatefulWidget {
  const PcExplorerTab({super.key});

  @override
  State<PcExplorerTab> createState() => _PcExplorerTabState();
}

class _PcExplorerTabState extends State<PcExplorerTab> {
  final ApiService _apiService = ApiService();
  List<FileNode> _files = [];
  String? _currentPath;
  final List<String?> _pathHistory = [];
  bool _isLoading = false;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadingFileName = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles([String? path]) async {
    setState(() => _isLoading = true);
    try {
      final files = await _apiService.fetchPcDirectory(path);
      setState(() {
        _files = files;
        _currentPath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadFile() async {
    // file_picker ^12.0.0+: Use FilePicker.pickFile() directly
    // instead of FilePicker.platform
    final PlatformFile? picked = await FilePicker.pickFile();

    if (picked != null && picked.path != null) {
      File file = File(picked.path!);
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
        _uploadingFileName = picked.name;
      });

      try {
        await _apiService.uploadFileToPc(
          currentPath: _currentPath,
          file: file,
          onProgress: (sent, total) {
            setState(() => _uploadProgress = sent / total);
          },
        );
        setState(() => _isUploading = false);
        _loadFiles(_currentPath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploaded to PC successfully!')),
          );
        }
      } catch (e) {
        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'PC Storage (${_currentPath ?? "/"})',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        leading: _pathHistory.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  _loadFiles(_pathHistory.removeLast());
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.blueAccent),
            onPressed: _isUploading ? null : _uploadFile,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) ...[
            LinearProgressIndicator(
              value: _uploadProgress,
              color: Colors.blueAccent,
              backgroundColor: Colors.black,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Uploading $_uploadingFileName...',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return ListTile(
                        leading: Icon(
                          file.isDirectory
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          color: file.isDirectory ? Colors.amber : Colors.blue,
                        ),
                        title: Text(
                          file.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          if (file.isDirectory) {
                            _pathHistory.add(_currentPath);
                            _loadFiles(file.path);
                          } else {
                            _apiService
                                .downloadFileFromPc(file.path, file.name)
                                .then((path) {
                                  OpenFilex.open(path);
                                });
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// TAB 2: Explore Local Phone Files (Select & Send to PC)
class PhoneExplorerTab extends StatelessWidget {
  const PhoneExplorerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Phone Local Storage',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      body: Center(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.send),
          label: const Text('Pick Phone File & Send to PC'),
          onPressed: () async {
            // file_picker ^12.0.0+: Use FilePicker.pickFile() directly
            final PlatformFile? picked = await FilePicker.pickFile();

            if (picked != null && picked.path != null) {
              File file = File(picked.path!);
              try {
                await apiService.uploadFileToPc(
                  currentPath: null,
                  file: file,
                  onProgress: (sent, total) {},
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File sent to PC successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
                }
              }
            }
          },
        ),
      ),
    );
  }
}
