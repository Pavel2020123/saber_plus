import 'reference_library_models.dart';

abstract interface class ReferenceLibraryRepository {
  Future<ReferenceLibrary> load();
}
