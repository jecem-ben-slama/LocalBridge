import 'dart:io';

import '../repositories/phone_files_repository.dart';

class SendFileToPc {
  final PhoneFilesRepository _repository;

  SendFileToPc(this._repository);

  Future<void> call({
    required File file,
    required void Function(int sent, int total) onProgress,
  }) => _repository.sendToPc(file: file, onProgress: onProgress);
}
