import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import 'storage_service.dart';

/// Firebase Storage implementation of [StorageService].
///
/// Storage structure:
///   avatars/{userId}/avatar.{ext}
///   reports/{userId}/{reportType}_{timestamp}.{ext}
///   progress/{userId}/{date}.{ext}
///
/// ── Firebase Storage security rules ──────────────────────────────────────────
/// rules_version = '2';
/// service firebase.storage {
///   match /b/{bucket}/o {
///     match /avatars/{userId}/{allPaths=**} {
///       allow read, write: if request.auth != null && request.auth.uid == userId;
///     }
///     match /reports/{userId}/{allPaths=**} {
///       allow read, write: if request.auth != null && request.auth.uid == userId;
///     }
///     match /progress/{userId}/{allPaths=**} {
///       allow read, write: if request.auth != null && request.auth.uid == userId;
///     }
///   }
/// }
class FirebaseStorageService implements StorageService {
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  // ── Avatar ────────────────────────────────────────────────────────────────

  @override
  Future<String> uploadAvatar({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    _validateImageFile(file);
    _validateFileSize(file, maxBytes: 5 * 1024 * 1024); // 5MB limit

    final ext = path.extension(file.path).replaceFirst('.', '');
    final storagePath = 'avatars/$userId/avatar.$ext';
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

    return _upload(
      file: file,
      storagePath: storagePath,
      contentType: mimeType,
      onProgress: onProgress,
    );
  }

  // ── Medical Reports ───────────────────────────────────────────────────────

  @override
  Future<String> uploadMedicalReport({
    required String userId,
    required File file,
    required String reportType,
    void Function(double progress)? onProgress,
  }) async {
    _validateReportFile(file);
    _validateFileSize(file, maxBytes: 10 * 1024 * 1024); // 10MB limit

    final ext = path.extension(file.path).replaceFirst('.', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'reports/$userId/${reportType}_$timestamp.$ext';
    final mimeType = lookupMimeType(file.path) ?? 'application/pdf';

    return _upload(
      file: file,
      storagePath: storagePath,
      contentType: mimeType,
      onProgress: onProgress,
    );
  }

  // ── Progress Photos ───────────────────────────────────────────────────────

  @override
  Future<String> uploadProgressPhoto({
    required String userId,
    required File file,
    required DateTime date,
    void Function(double progress)? onProgress,
  }) async {
    _validateImageFile(file);
    _validateFileSize(file, maxBytes: 10 * 1024 * 1024); // 10MB limit

    final ext = path.extension(file.path).replaceFirst('.', '');
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final storagePath = 'progress/$userId/$dateStr.$ext';
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';

    return _upload(
      file: file,
      storagePath: storagePath,
      contentType: mimeType,
      onProgress: onProgress,
    );
  }

  // ── Delete & URL ──────────────────────────────────────────────────────────

  @override
  Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref(storagePath).delete();
      log.info('FirebaseStorage: deleted $storagePath');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return; // Already gone
      throw _mapFirebaseException(e);
    }
  }

  @override
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref(storagePath).getDownloadURL();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ── Internal Upload ───────────────────────────────────────────────────────

  Future<String> _upload({
    required File file,
    required String storagePath,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref(storagePath);
      final metadata = SettableMetadata(contentType: contentType);
      final uploadTask = ref.putFile(file, metadata);

      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      log.info(
        'FirebaseStorage: uploaded $storagePath '
        '(${file.lengthSync() ~/ 1024}KB) → $downloadUrl',
      );

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  void _validateImageFile(File file) {
    final ext = path.extension(file.path).toLowerCase();
    final allowed = {'.jpg', '.jpeg', '.png', '.webp', '.heic'};
    if (!allowed.contains(ext)) {
      throw ValidationException(
        message: 'Invalid image format. Allowed: ${allowed.join(', ')}',
      );
    }
  }

  void _validateReportFile(File file) {
    final ext = path.extension(file.path).toLowerCase();
    final allowed = {'.pdf', '.jpg', '.jpeg', '.png'};
    if (!allowed.contains(ext)) {
      throw ValidationException(
        message: 'Invalid file format. Allowed: ${allowed.join(', ')}',
      );
    }
  }

  void _validateFileSize(File file, {required int maxBytes}) {
    final size = file.lengthSync();
    if (size > maxBytes) {
      throw ValidationException(
        message:
            'File too large. Maximum size: ${maxBytes ~/ (1024 * 1024)}MB. '
            'File size: ${size ~/ (1024 * 1024)}MB.',
      );
    }
  }

  AppException _mapFirebaseException(FirebaseException e) {
    return switch (e.code) {
      'unauthorized' || 'permission-denied' => const ForbiddenException(
          message: 'Storage permission denied.',
        ),
      'object-not-found' => const NotFoundException(
          message: 'File not found.',
        ),
      'quota-exceeded' => const ServerException(
          message: 'Storage quota exceeded.',
          statusCode: 507,
        ),
      'canceled' => const UnknownException(message: 'Upload was cancelled.'),
      _ => UnknownException(
          message: 'Storage error: ${e.message ?? e.code}',
        ),
    };
  }
}

// ── Riverpod Provider ──────────────────────────────────────────────────────────

final storageServiceProvider = Provider<StorageService>(
  (_) => FirebaseStorageService(),
  name: 'storageServiceProvider',
);

