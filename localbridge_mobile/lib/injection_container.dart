import 'package:get_it/get_it.dart';
import 'core/network/api_service.dart';
import 'core/services/pdf_service.dart';
import 'core/services/file_storage_service.dart';
import 'core/services/transfer_service.dart';
import 'core/services/session_service.dart';
import 'features/connection/data/repositories/connection_repository_impl.dart';
import 'features/connection/domain/repositories/connection_repository.dart';
import 'features/document_viewer/data/datasources/doc_remote_source.dart';
import 'features/document_viewer/data/repositories/document_repository_impl.dart';
import 'features/document_viewer/domain/repositories/document_repository.dart';
import 'features/document_viewer/domain/usecases/fetch_document_url.dart';
import 'features/document_viewer/domain/usecases/load_directory.dart';
import 'features/document_viewer/presentation/cubit/document_cubit.dart';
import 'features/connection/domain/usecases/check_pc_connectivity.dart';
import 'features/connection/presentation/cubit/connection_cubit.dart';
import 'features/navbar/presentation/cubit/navbar_cubit.dart';
import 'features/shared_files/domain/usecases/load_recent_shared_files.dart';
import 'features/shared_files/presentation/cubit/shared_files_cubit.dart';
import 'features/phone_files/domain/usecases/disconnect_phone_session.dart';
import 'features/phone_files/domain/usecases/get_phone_server_status.dart';
import 'features/phone_files/domain/usecases/get_web_connection_status.dart';
import 'features/phone_files/domain/usecases/send_file_to_pc.dart';
import 'features/phone_files/domain/usecases/toggle_phone_server.dart';
import 'features/phone_files/domain/usecases/watch_web_connection.dart';
import 'features/phone_files/presentation/cubit/phone_files_cubit.dart';
import 'features/phone_files/data/datasources/phone_files_remote_source.dart';
import 'features/phone_files/data/repositories/phone_files_repository_impl.dart';
import 'features/phone_files/domain/repositories/phone_files_repository.dart';
import 'features/phone_files/domain/services/phone_server.dart';
import 'features/phone_files/infrastructure/phone_http_server.dart';
import 'features/shared_files/data/datasources/shared_files_local_source.dart';
import 'features/shared_files/data/repositories/shared_files_repository_impl.dart';
import 'features/shared_files/domain/repositories/shared_files_repository.dart';
import 'infrastructure/services/file_storage_service_impl.dart';
import 'infrastructure/services/background_file_transfer_service.dart';
import 'infrastructure/services/pdf_service_adapter.dart';

final GetIt locator = GetIt.instance;

void setupDependencies() {
  if (locator.isRegistered<ApiService>()) return;

  locator.registerLazySingleton<ApiService>(ApiService.new);
  locator.registerLazySingleton<SessionService>(
    () => SessionService(locator<ApiService>()),
  );
  locator.registerLazySingleton<BackgroundFileTransferService>(
    BackgroundFileTransferService.new,
  );
  locator.registerLazySingleton<DocRemoteSource>(
    () => DocRemoteSourceImpl(
      locator<ApiService>(),
      locator<BackgroundFileTransferService>(),
    ),
  );
  locator.registerLazySingleton<PhoneFilesRemoteSource>(
    () => PhoneFilesRemoteSourceImpl(
      locator<ApiService>(),
      locator<PhoneServer>(),
      locator<BackgroundFileTransferService>(),
    ),
  );
  locator.registerLazySingleton<PhoneServer>(PhoneHttpServer.new);
  locator.registerLazySingleton<PhoneFilesRepository>(
    () => PhoneFilesRepositoryImpl(locator<PhoneFilesRemoteSource>()),
  );
  locator.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton<SharedFilesLocalSource>(
    SharedFilesLocalSourceImpl.new,
  );
  locator.registerLazySingleton<SharedFilesRepository>(
    () => SharedFilesRepositoryImpl(locator<SharedFilesLocalSource>()),
  );
  locator.registerLazySingleton<FileStorageService>(FileStorageServiceImpl.new);
  locator.registerLazySingleton<TransferService>(
    () => TransferService(locator<BackgroundFileTransferService>()),
  );
  locator.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      locator<DocRemoteSource>(),
      locator<FileStorageService>(),
    ),
  );
  locator.registerLazySingleton(
    () => FetchDocumentUrl(locator<DocumentRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadDirectory(locator<DocumentRepository>()),
  );
  locator.registerLazySingleton(
    () => LoadRecentSharedFiles(locator<SharedFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => CheckPcConnectivity(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => DisconnectPhoneSession(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => GetPhoneServerStatus(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => GetWebConnectionStatus(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => SendFileToPc(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => TogglePhoneServer(locator<PhoneFilesRepository>()),
  );
  locator.registerLazySingleton(
    () => WatchWebConnection(locator<PhoneFilesRepository>()),
  );
  locator.registerFactory(
    () =>
        DocumentCubit(locator<DocumentRepository>(), locator<LoadDirectory>()),
  );
  locator.registerFactory(
    () => SharedFilesCubit(locator<LoadRecentSharedFiles>()),
  );
  locator.registerFactory(
    () => ConnectionCubit(locator<CheckPcConnectivity>()),
  );
  locator.registerFactory(
    () => NavbarCubit(
      locator<CheckPcConnectivity>(),
      locator<GetPhoneServerStatus>(),
      locator<DisconnectPhoneSession>(),
    ),
  );
  locator.registerFactory(
    () => PhoneFilesCubit(
      locator<TransferService>(),
      locator<GetPhoneServerStatus>(),
      locator<GetWebConnectionStatus>(),
      locator<TogglePhoneServer>(),
      locator<WatchWebConnection>(),
      locator<SendFileToPc>(),
    ),
  );
  locator.registerLazySingleton<PdfService>(PdfServiceAdapter.new);
}
