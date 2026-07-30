import 'dart:io';

/// Abstract storage service — defines the contract for all file upload operations.
///
/// Implementations:
///   - [FirebaseStorageService] — production Firebase Storage
///   - (Future) S3StorageService, CloudinaryStorageService, etc.
abstract class StorageService {
  /// Uploads an avatar image for [userId].
  ///
  /// [file] — The image file to upload (JPEG/PNG).
  /// Returns the public download URL.
  Future<String> uploadAvatar({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  });

  /// Uploads a medical report document for [userId].
  ///
  /// [file] — PDF or image file.
  /// [reportType] — e.g. 'blood_work', 'ecg', 'xray'.
  /// Returns the download URL.
  Future<String> uploadMedicalReport({
    required String userId,
    required File file,
    required String reportType,
    void Function(double progress)? onProgress,
  });

  /// Uploads a progress photo for [userId].
  ///
  /// Returns the download URL.
  Future<String> uploadProgressPhoto({
    required String userId,
    required File file,
    required DateTime date,
    void Function(double progress)? onProgress,
  });

  /// Deletes a file by its storage path.
  Future<void> deleteFile(String storagePath);

  /// Returns a signed download URL for a storage path (if private).
  Future<String> getDownloadUrl(String storagePath);
}
