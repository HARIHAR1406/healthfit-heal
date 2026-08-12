import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:healthfit_heal/features/nutrition/data/services/image_processing_service.dart';
import 'package:healthfit_heal/features/nutrition/domain/entities/detected_food.dart';

void main() {
  late ImageProcessingService service;

  setUp(() {
    service = ImageProcessingService();
  });

  group('ImageProcessingService.validate', () {
    test('returns failure for empty bytes', () {
      final result = service.validate(Uint8List(0));
      expect(result.isValid, isFalse);
      expect(result.error, ImageValidationError.emptyFile);
    });

    test('returns failure for oversized file', () {
      // 11 MB of data
      final oversized = Uint8List(11 * 1024 * 1024);
      final result = service.validate(oversized);
      expect(result.isValid, isFalse);
      expect(result.error, ImageValidationError.tooLarge);
    });

    test('returns failure for unsupported format', () {
      final garbage = Uint8List.fromList([0x00, 0x11, 0x22, 0x33]);
      final result = service.validate(garbage);
      expect(result.isValid, isFalse);
      expect(result.error, ImageValidationError.unsupportedFormat);
    });

    test('accepts valid JPEG magic bytes', () {
      // FF D8 FF (JPEG magic bytes)
      final jpeg = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, // JFIF header start
        ...List.filled(100, 0x00), // dummy payload
      ]);
      final result = service.validate(jpeg);
      expect(result.isValid, isTrue);
      expect(result.bytes, isNotNull);
    });

    test('accepts valid PNG magic bytes', () {
      // 89 50 4E 47 (PNG signature)
      final png = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, // PNG signature
        ...List.filled(100, 0x00),
      ]);
      final result = service.validate(png);
      expect(result.isValid, isTrue);
    });

    test('accepts valid WEBP magic bytes', () {
      // RIFF....WEBP
      final webp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, // RIFF
        0x00, 0x00, 0x00, 0x00, // file size (placeholder)
        0x57, 0x45, 0x42, 0x50, // WEBP
        ...List.filled(100, 0x00),
      ]);
      final result = service.validate(webp);
      expect(result.isValid, isTrue);
    });

    test('errorMessage is not null on failure', () {
      final result = service.validate(Uint8List(0));
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, isNotEmpty);
    });
  });

  group('ImageProcessingService.prepareForRecognition', () {
    test('returns bytes unchanged when within AI budget', () async {
      // 1 MB image — well within the 4 MB budget
      final smallImage = Uint8List(1 * 1024 * 1024);
      final result = await service.prepareForRecognition(smallImage);
      // Same object returned when no recompression needed
      expect(result, same(smallImage));
    });

    test('returns bytes when oversized (graceful passthrough)', () async {
      // 5 MB — above 4 MB AI budget
      final bigImage = Uint8List(5 * 1024 * 1024);
      final result = await service.prepareForRecognition(bigImage);
      // Phase 13 returns original bytes as-is when cannot compress
      expect(result, isNotNull);
      expect(result.length, bigImage.length);
    });
  });

  group('ImagePickResult', () {
    test('cancelled factory sets isCancelled', () {
      const result = ImagePickResult.cancelled();
      expect(result.isCancelled, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
    });

    test('error factory sets isError and isPermissionDenied', () {
      const result = ImagePickResult.error(
        error: ImagePickError.permissionDenied,
        userMessage: 'Camera access denied',
      );
      expect(result.isError, isTrue);
      expect(result.isPermissionDenied, isTrue);
      expect(result.userMessage, 'Camera access denied');
    });

    test('success factory sets isSuccess and bytes', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
      final result = ImagePickResult.success(
        bytes: bytes,
        source: ImageSource.camera,
        mimeType: 'image/jpeg',
      );
      expect(result.isSuccess, isTrue);
      expect(result.bytes, bytes);
      expect(result.mimeType, 'image/jpeg');
    });

    test('non-permission error isPermissionDenied is false', () {
      const result = ImagePickResult.error(
        error: ImagePickError.invalidImage,
        userMessage: 'Bad image',
      );
      expect(result.isPermissionDenied, isFalse);
    });
  });

  group('ImageValidationResult', () {
    test('valid result has bytes and detectedFormat', () {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final result = service.validate(bytes);
      // JPEG header is valid — will be valid
      expect(result.isValid, isTrue);
    });

    test('failure result has error and errorMessage', () {
      final result = service.validate(Uint8List(0));
      expect(result.isValid, isFalse);
      expect(result.error, isNotNull);
      expect(result.errorMessage, isNotNull);
    });
  });
}
