import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/asset_reference_library_repository.dart';
import '../domain/reference_library_models.dart';
import '../domain/reference_library_repository.dart';

final referenceLibraryRepositoryProvider = Provider<ReferenceLibraryRepository>(
  (ref) => AssetReferenceLibraryRepository(),
);

final referenceLibraryProvider = FutureProvider<ReferenceLibrary>(
  (ref) => ref.watch(referenceLibraryRepositoryProvider).load(),
);
