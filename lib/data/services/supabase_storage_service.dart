import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import '../../core/errors/app_exception.dart';
import 'storage_service.dart';

class SupabaseStorageService implements StorageService {
  final SupabaseClient _client;
  static const String _bucketName = 'avatars';

  SupabaseStorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<String?> uploadAvatar(
    String userId,
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final rawExt = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
      final fileExt = (rawExt == 'jpeg' || rawExt == 'jpg') ? 'jpg' : rawExt;
      final mimeType = (rawExt == 'jpg' || rawExt == 'jpeg') ? 'image/jpeg' : 'image/$rawExt';
      final path = '$userId/avatar.$fileExt';

      debugPrint('SupabaseStorageService: uploading ${bytes.length} bytes to $_bucketName at $path (type $mimeType)');
      await _client.storage.from(_bucketName).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      final publicUrl =
          _client.storage.from(_bucketName).getPublicUrl(path);

      debugPrint('SupabaseStorageService: got publicUrl $publicUrl');
      // Add a cache-busting timestamp
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e, s) {
      debugPrint('SupabaseStorageService error: $e\n$s');
      throw StorageException('Failed to upload avatar: $e');
    }
  }

  @override
  Future<String?> getAvatarUrl(String userId) async {
    try {
      final files = await _client.storage.from(_bucketName).list(path: userId);
      if (files.isEmpty) return null;
      final fileName = files.first.name;
      return _client.storage.from(_bucketName).getPublicUrl('$userId/$fileName');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteAvatar(String userId) async {
    try {
      final files = await _client.storage.from(_bucketName).list(path: userId);
      if (files.isNotEmpty) {
        await _client.storage
            .from(_bucketName)
            .remove(files.map((f) => '$userId/${f.name}').toList());
      }
    } catch (e) {
      throw StorageException('Failed to delete avatar: $e');
    }
  }
}
