import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/reference_library_models.dart';
import '../domain/reference_library_repository.dart';

typedef ReferenceAssetLoader = Future<String> Function();

class AssetReferenceLibraryRepository implements ReferenceLibraryRepository {
  AssetReferenceLibraryRepository({ReferenceAssetLoader? loader})
    : _loader = loader ?? _loadBundledAsset;

  final ReferenceAssetLoader _loader;
  ReferenceLibrary? _cache;

  @override
  Future<ReferenceLibrary> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _loader();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('La biblioteca académica no es válida.');
    }
    final library = ReferenceLibrary.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    _cache = library;
    return library;
  }
}

Future<String> _loadBundledAsset() =>
    rootBundle.loadString('assets/data/reference_library.json');
