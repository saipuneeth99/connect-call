import 'dart:typed_data';
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
      final fileExt = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final path = '$userId/avatar.$fileExt';

      await _client.storage.from(_bucketName).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$fileExt',
            ),
          );

      final publicUrl =
          _client.storage.from(_bucketName).getPublicUrl(path);

      // Add a cache-busting timestamp
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
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
