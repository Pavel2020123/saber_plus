import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_directory_repository.dart';
import '../domain/institution_directory.dart';

final institutionDirectoryRepositoryProvider =
    Provider<InstitutionDirectoryRepository>((ref) {
      // Cambiar de cuenta invalida también las consultas dependientes.
      final user = ref.watch(
        sessionControllerProvider.select((session) => session.user),
      );
      if (user?.isDemo ?? false) return DemoInstitutionDirectoryRepository();
      return RemoteInstitutionDirectoryRepository(ref.watch(dioProvider));
    });

typedef DirectoryQuery = ({String query, int page});
final institutionDirectoryProvider = FutureProvider.autoDispose
    .family<InstitutionDirectoryPageData, DirectoryQuery>(
      (ref, query) => ref
          .watch(institutionDirectoryRepositoryProvider)
          .search(query: query.query, page: query.page),
    );
final institutionDirectoryDetailProvider = FutureProvider.autoDispose
    .family<PublicInstitution, String>(
      (ref, id) => ref.watch(institutionDirectoryRepositoryProvider).detail(id),
    );
