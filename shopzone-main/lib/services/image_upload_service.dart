import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class ImageUploadService {
  static Future<Map<String, dynamic>> uploadProductImage(
      String productId,
      File imageFile, {
        bool isPrimary = false,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/upload/product/$productId');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['is_primary'] = isPrimary.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> uploadProductImages(
      String productId,
      List<File> files,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/upload/product/$productId/batch');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath('images', file.path));
    }

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('$baseUrl/upload/avatar');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));

    final streamedRes = await request.send();
    final res = await http.Response.fromStream(streamedRes);

    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body);
  }
}