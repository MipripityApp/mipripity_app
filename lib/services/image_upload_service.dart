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
  
  // Upload multiple images to Cloudinary with concurrent uploads
  static Future<List<String>> uploadMultipleToCloudinary(List<String> filePaths, {int maxRetries = 2}) async {
    try {
      // Safety check - return empty list if paths is null or empty
      if (filePaths.isEmpty) {
        print('No images to upload');
        return [];
      }
      
      // First, filter and prepare the files for upload
      List<Future<String?>> uploadFutures = [];
      List<String> existingUrls = [];
      
      for (String path in filePaths) {
        // Skip blob URLs completely as they cannot be processed
        if (path.startsWith('blob:')) {
          print('Skipping blob URL: $path - cannot be processed directly');
          continue;
        }
        
        if (path.startsWith('http')) {
          // If it's already a URL, just add it directly
          existingUrls.add(path);
          continue;
        }
        
        // Only process real file paths
        try {
          final file = File(path);
          if (await file.exists()) {
            // For file paths, create a future for each upload with retry logic
            uploadFutures.add(_uploadWithRetry(path, maxRetries));
          } else {
            print('File does not exist: $path - skipping');
          }
        } catch (e) {
          print('Error checking file: $path - $e - skipping');
        }
      }
      
      // Safety check - return existing URLs if no files to upload
      if (uploadFutures.isEmpty) {
        print('No valid files to upload, returning ${existingUrls.length} existing URLs');
        return existingUrls;
      }
      
      // Upload all files concurrently
      List<String?> results = await Future.wait(uploadFutures);
      
      // Filter out failed uploads (null results) and combine with existing URLs
      List<String> uploadedUrls = [
        ...existingUrls,
        ...results.where((url) => url != null).cast<String>()
      ];
      
      print('Uploaded ${uploadedUrls.length}/${filePaths.length} images successfully');
      return uploadedUrls;
    } catch (e) {
      print('Exception in uploadMultipleToCloudinary: $e');
      // Return any existing URLs on error
      return filePaths.where((path) => 
        path.startsWith('http') && !path.startsWith('blob:')
      ).toList();
    }
  }
  
  // We no longer try to handle blob URLs - they're skipped completely

  // Helper method to handle retries for a single file upload - simplified
  static Future<String?> _uploadWithRetry(String filePath, int maxRetries) async {
    int attempts = 0;
    
    // Safety check for the file path
    if (filePath.isEmpty || filePath.startsWith('blob:')) {
      print('Invalid file path: $filePath');
      return null;
    }
    
    File fileToUpload;
    try {
      // Regular file path
      fileToUpload = File(filePath);
      if (!await fileToUpload.exists()) {
        print('File does not exist: $filePath');
        return null;
      }
      
      // Validate the file is an image
      if (!_isValidImageFile(fileToUpload.path)) {
        print('Invalid image file format: ${fileToUpload.path}');
        return null;
      }
    } catch (e) {
      print('Error preparing file for upload: $filePath - $e');
      return null;
    }
    
    while (attempts <= maxRetries) {
      try {
        // Attempt to upload
        final url = await uploadToCloudinary(fileToUpload);
        if (url != null) {
          return url;
        }
        
        // If we reached here, the upload failed but didn't throw an exception
        print('Upload returned null without exception');
        attempts++;
        
      } catch (e) {
        attempts++;
        if (attempts <= maxRetries) {
          print('Retry attempt $attempts for ${fileToUpload.path} after error: $e');
          await Future.delayed(Duration(seconds: 1 * attempts)); // Increasing delay for each retry
        } else {
          print('Failed to upload ${fileToUpload.path} after $maxRetries retries: $e');
          return null;
        }
      }
    }
    
    return null;
  }
  
  // Helper to validate image file format (private implementation)
  static bool _isValidImageFile(String filePath) {
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'];
    final ext = extension(filePath).toLowerCase();
    return validExtensions.contains(ext);
  }
  
  // Public method to validate image files (used by ProfilePhotoScreen)
  static bool isValidImageFile(File imageFile) {
    final filePath = imageFile.path;
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'];
    final ext = extension(filePath).toLowerCase();
    return validExtensions.contains(ext);
  }
  
  // Check if file size is within acceptable limits
  static Future<bool> isValidFileSize(File imageFile, {int maxSizeInMB = 10}) async {
    try {
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024); // Convert bytes to MB
      return fileSizeInMB <= maxSizeInMB;
    } catch (e) {
      print('Error checking file size: $e');
      return false;
    }
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
