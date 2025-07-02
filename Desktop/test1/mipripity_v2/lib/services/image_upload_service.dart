import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ImageUploadService {
  // ImgBB configuration for fallback
  static const String apiKey = '3d5860aa87a1edb40dead8debc3c983e'; // Get a free key from imgbb.com
  static const String uploadUrl = 'https://api.imgbb.com/1/upload';
  
  // Cloudinary configuration
  static final cloudinary = CloudinaryPublic(
    'dxhrlaz6j',
    'mipripity',
    cache: false,
  );

  // Upload a single image to Cloudinary
  static Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'mipripity_listings',
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      // Fallback to ImgBB if Cloudinary fails
      return uploadImage(imageFile);
    }
  }
  
  // Upload multiple images to Cloudinary
  static Future<List<String>> uploadMultipleToCloudinary(List<String> filePaths) async {
    List<String> uploadedUrls = [];
    
    for (String path in filePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final url = await uploadToCloudinary(file);
          if (url != null) {
            uploadedUrls.add(url);
          }
        } else {
          // If it's already a URL, just add it
          if (path.startsWith('http')) {
            uploadedUrls.add(path);
          }
        }
      } catch (e) {
        print('Error uploading file at path $path: $e');
      }
    }
    
    return uploadedUrls;
  }

  // Legacy upload a single image to ImgBB
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final uri = Uri.parse('$uploadUrl?key=$apiKey');
      final request = http.MultipartRequest('POST', uri);
      
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: basename(imageFile.path),
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      
      if (response.statusCode == 200 && jsonData['success'] == true) {
        return jsonData['data']['url'];
      } else {
        print('Image upload failed: ${jsonData['error']['message']}');
        return null;
      }
    } catch (e) {
      print('Exception during image upload: $e');
      return null;
    }
  }

  // Upload multiple images
  static Future<List<String>> uploadImages(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];
    
    for (final imageFile in imageFiles) {
      final url = await uploadImage(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }
  
  // For demo purposes, return placeholder image URLs
  static List<String> getDemoImageUrls(int count) {
    return List.generate(
      count, 
      (index) => 'https://via.placeholder.com/800x600?text=Property+Image+${index + 1}'
    );
  }
}
