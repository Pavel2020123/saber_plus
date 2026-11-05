import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../app/theme.dart';
import '../domain/private_profile_photo.dart';
import 'private_profile_photo_board.dart';

class _PreviewPhotoRepository implements PrivateProfilePhotoRepository {
  @override
  Future<PrivateProfilePhoto> load() async =>
      const PrivateProfilePhoto(revision: 0);
  @override
  Future<Uint8List> content(PrivateProfilePhoto photo) async =>
      throw StateError('Preview has no private bytes');
  @override
  Future<PrivatePhotoReceipt> upload(
    String operation,
    int revision,
    Uint8List bytes,
  ) async => throw StateError('Preview never uploads');
  @override
  Future<PrivatePhotoReceipt> operation(String operation) async =>
      throw StateError('Preview never requests receipts');
  @override
  Future<PrivatePhotoReceipt> cancel(String operation) async =>
      throw StateError('Preview never cancels remotely');
  @override
  Future<PrivatePhotoRemoval> remove(int revision) async =>
      throw StateError('Preview never deletes');
}

@Preview(name: 'Foto privada · teléfono', group: 'C5', size: Size(375, 812))
Widget privatePhotoPhonePreview() => MaterialApp(
  theme: SaberPlusTheme.light,
  home: PrivateProfilePhotoBoard(
    userId: 'preview-only',
    repository: _PreviewPhotoRepository(),
    pick: () async => null,
  ),
);

@Preview(
  name: 'Foto privada · texto grande',
  group: 'C5',
  size: Size(812, 375),
  brightness: Brightness.dark,
  textScaleFactor: 2.5,
)
Widget privatePhotoLandscapePreview() => MaterialApp(
  theme: SaberPlusTheme.dark,
  home: PrivateProfilePhotoBoard(
    userId: 'preview-only',
    repository: _PreviewPhotoRepository(),
    pick: () async => null,
  ),
);
