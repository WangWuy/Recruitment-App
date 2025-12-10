import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../core/constants.dart';

class UploadService {
  Future<Map<String, dynamic>> uploadBytes(String token, List<int> bytes, String filename) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/api/upload');
    final req = http.MultipartRequest('POST', url);
    req.headers['Authorization'] = 'Bearer $token';
    final mime = lookupMimeType(filename) ?? 'application/octet-stream';
    final type = MediaType.parse(mime);
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: type));
    final resp = await http.Response.fromStream(await req.send());
    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) return data;
    throw Exception(data['message'] ?? 'Upload thất bại');
  }
}

