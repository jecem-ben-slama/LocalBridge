import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_recent_shared_files.dart';
import 'shared_files_state.dart';

class SharedFilesCubit extends Cubit<SharedFilesState> {
  final LoadRecentSharedFiles _loadRecentSharedFiles;

  SharedFilesCubit(this._loadRecentSharedFiles)
    : super(const SharedFilesState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final files = await _loadRecentSharedFiles();
      emit(state.copyWith(files: files, isLoading: false));
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          error: error is String ? error : 'Could not load shared files.',
        ),
      );
    }
  }
}
