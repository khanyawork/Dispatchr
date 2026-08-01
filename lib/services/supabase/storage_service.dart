import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

/// One file to upload via [StorageService.uploadJobPhotos].
typedef PhotoUpload = ({String fileName, Uint8List bytes});

/// Photo upload/download helpers for `jobs.photo_urls` proof-of-work
/// attachments (README 8.1: "optional photos of the issue"; 8.2: "attach
/// one or more before/after photos"). `FileManifest.md`:
/// `lib/services/supabase/storage_service.dart`.
///
/// Assumes a Supabase Storage bucket named `job-photos` — not named
/// anywhere in README, so create it (with a storage policy scoping
/// uploads/reads appropriately, per README Section 15's troubleshooting
/// note on storage policies) before wiring this up against a real
/// project.
class StorageService {
  StorageService({SupabaseClient? client})
    : _client = client ?? AppSupabase.client;

  final SupabaseClient _client;

  static const String _bucket = 'job-photos';

  StorageFileApi get _bucketApi => _client.storage.from(_bucket);

  /// Uploads one photo for [jobId] and returns its public URL, ready to be
  /// appended to `jobs.photo_urls` (see `technician_repository.dart`'s
  /// `attachPhotos` and `client_repository.dart`'s `createRequest`).
  /// [fileName] should include an extension (e.g. `before.jpg`).
  Future<String> uploadJobPhoto({
    required String jobId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$jobId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _bucketApi.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: false),
    );
    return _bucketApi.getPublicUrl(path);
  }

  /// Uploads several photos for [jobId] in one call, returning their
  /// public URLs in the same order as [files].
  Future<List<String>> uploadJobPhotos({
    required String jobId,
    required List<PhotoUpload> files,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(
        await uploadJobPhoto(
          jobId: jobId,
          fileName: file.fileName,
          bytes: file.bytes,
        ),
      );
    }
    return urls;
  }

  /// Downloads a photo's raw bytes given its storage path (not its public
  /// URL) — e.g. for caching or re-processing before display.
  Future<Uint8List> downloadJobPhoto(String path) {
    return _bucketApi.download(path);
  }

  /// Deletes one or more previously uploaded photos by storage path.
  Future<void> deleteJobPhotos(List<String> paths) {
    return _bucketApi.remove(paths);
  }
}
