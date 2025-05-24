import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final String uploadPreset;
  
  CloudinaryService({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
    required this.uploadPreset,
  });
  
  factory CloudinaryService.fromEnv() {
    return CloudinaryService(
      cloudName: dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '',
      apiKey: dotenv.env['CLOUDINARY_API_KEY'] ?? '',
      apiSecret: dotenv.env['CLOUDINARY_API_SECRET'] ?? '',
      uploadPreset: dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'ml_default',
    );
  }
  
  // Método para subir imagen
  Future<String?> uploadImage(File imageFile, String folder) async {
    return await _uploadFile(imageFile, folder, 'image');
  }
  
  // Método para subir video
  Future<String?> uploadVideo(File videoFile, String folder) async {
    return await _uploadFile(videoFile, folder, 'video');
  }
  
  // Método general para subidas
  Future<String?> _uploadFile(File file, String folder, String resourceType) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
      );
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);
      
      if (response.statusCode == 200) {
        return jsonData['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}