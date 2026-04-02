// IPFS клиент через Pinata
// Загрузка и скачивание .bin файлов

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IPFSError implements Exception {
  final String message;
  IPFSError(this.message);
  @override
  String toString() => 'IPFSError: $message';
}

class IPFSClient {
  final String jwt;
  static const String uploadUrl = 'https://api.pinata.cloud/pinning/pinFileToIPFS';
  static const String gatewayUrl = 'https://gateway.pinata.cloud/ipfs';

  IPFSClient({required this.jwt});

  /// Загрузить .bin файл в IPFS
  /// Возвращает CID хэш
  Future<String> upload(
    Uint8List data, {
    String filename = 'message.bin',
    int? expiresAt,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.headers['Authorization'] = 'Bearer $jwt';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        data,
        filename: filename,
      ));

      if (expiresAt != null) {
        request.fields['pinataMetadata'] = jsonEncode({
          'name': filename,
          'keyvalues': {'expires_at': expiresAt.toString()},
        });
      } else {
        request.fields['pinataMetadata'] = jsonEncode({'name': filename});
      }

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final body = await response.stream.bytesToString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        throw IPFSError('Ошибка загрузки: ${response.statusCode} $body');
      }

      final cid = json['IpfsHash'] as String?;
      if (cid == null) {
        throw IPFSError('CID не найден в ответе: $body');
      }
      return cid;

    } catch (e) {
      if (e is IPFSError) rethrow;
      throw IPFSError('Ошибка загрузки в IPFS: $e');
    }
  }

  /// Скачать .bin файл из IPFS по CID
  Future<Uint8List> download(String cid) async {
    try {
      final url = '$gatewayUrl/$cid';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw IPFSError('Ошибка скачивания: ${response.statusCode}');
      }
      return response.bodyBytes;

    } catch (e) {
      if (e is IPFSError) rethrow;
      throw IPFSError('Ошибка скачивания из IPFS: $e');
    }
  }
}
