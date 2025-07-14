import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_config.dart';

// Result class to provide more detailed upload results
class UploadResult {
  final List<String> successUrls;
  final List<String> failedPaths;
  final String? errorMessage;
  final bool hasBlobs;

  UploadResult({
    required this.successUrls,
    required this.failedPaths,
    this.errorMessage,
    this.hasBlobs = false,
  });

  bool get isSuccess => failedPaths.isEmpty && errorMessage == null;
  bool get isPartialSuccess => successUrls.isNotEmpty && failedPaths.isNotEmpty;
  bool get isFailure => successUrls.isEmpty && (failedPaths.isNotEmpty || errorMessage != null);
}

class ImageUploadService {
  // List to store uploaded image URLs
  static List<String> uploadedImageUrls = [];
  
  // Pick and upload image to backend method
  static Future<void> pickAndUploadImageToBackend() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      final url = await uploadImage(imageFile);
      
      if (url != null) {
        uploadedImageUrls.add(url);
        print('✅ Image uploaded and enhanced: $url');
      } else {
        print('❌ Upload failed');
      }
    } else {
      print("No image selected");
    }
  }
  
  // Upload a single image to the backend with authentication
  static Future<String?> uploadImage(File imageFile, {String? authToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload');

    // Create multipart request
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    
    // Add authentication headers if token is provided
    if (authToken != null && authToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $authToken';
    } else {
      // Try to get token from secure storage or other auth service
      try {
        final token = await _getAuthToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('Error retrieving auth token: $e');
      }
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['url']; // Enhanced Cloudinary image URL
      } else if (response.statusCode == 401) {
        print("Authentication failed: Please log in again");
        return null;
      } else {
        final errorResp = await response.stream.bytesToString();
        print("Upload failed: ${response.statusCode}, Error: $errorResp");
        return null;
      }
    } catch (e) {
      print("Upload exception: $e");
      return null;
    }
  }
  
  // Helper method to get auth token from secure storage or other service
  static Future<String?> _getAuthToken() async {
    // Implement based on your app's authentication system
    // For example, you might use flutter_secure_storage to get the token
    // This is a placeholder implementation
    try {
      // TODO: Replace with your actual token retrieval logic
      // Example:
      // final storage = FlutterSecureStorage();
      // return await storage.read(key: 'auth_token');
      return null;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }
  
  // Upload multiple images with comprehensive error handling
  static Future<UploadResult> uploadMultipleToCloudinary(List<String> filePaths, {int maxRetries = 2}) async {
    try {
      // Safety check - return empty result if paths is null or empty
      if (filePaths.isEmpty) {
        print('No images to upload');
        return UploadResult(
          successUrls: [],
          failedPaths: [],
          errorMessage: 'No images provided for upload',
        );
      }
      
      // Track blob URLs to report back to the caller
      bool hasBlobUrls = false;
      List<String> failedPaths = [];
      List<Future<String?>> uploadFutures = [];
      List<String> existingUrls = [];
      
      for (String path in filePaths) {
        // Detect blob URLs
        if (path.startsWith('blob:')) {
          print('Skipping blob URL: $path - cannot be processed directly');
          hasBlobUrls = true;
          failedPaths.add(path);
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
            failedPaths.add(path);
          }
        } catch (e) {
          print('Error checking file: $path - $e - skipping');
          failedPaths.add(path);
        }
      }
      
      // Safety check - return with appropriate status if no files to upload
      if (uploadFutures.isEmpty) {
        print('No valid files to upload, returning ${existingUrls.length} existing URLs');
        
        // If we have existing URLs, that's at least a partial success
        if (existingUrls.isNotEmpty) {
          return UploadResult(
            successUrls: existingUrls,
            failedPaths: failedPaths,
            hasBlobs: hasBlobUrls,
          );
        } else {
          return UploadResult(
            successUrls: [],
            failedPaths: failedPaths,
            errorMessage: 'No valid files to upload',
            hasBlobs: hasBlobUrls,
          );
        }
      }
      
      // Upload all files concurrently
      List<String?> results = await Future.wait(uploadFutures);
      
      // Process results to separate successes and failures
      List<String> successfulUploads = [];
      for (int i = 0; i < results.length; i++) {
        if (results[i] != null) {
          successfulUploads.add(results[i]!);
        } else {
          // Track which file paths failed
          failedPaths.add(filePaths[i]);
        }
      }
      
      // Combine successful uploads with existing URLs
      List<String> allSuccessUrls = [...existingUrls, ...successfulUploads];
      
      print('Uploaded ${allSuccessUrls.length}/${filePaths.length} images successfully');
      
      // Return comprehensive result
      return UploadResult(
        successUrls: allSuccessUrls,
        failedPaths: failedPaths,
        hasBlobs: hasBlobUrls,
      );
      
    } catch (e) {
      print('Exception in uploadMultipleImages: $e');
      // Return any existing URLs on error and detailed error information
      return UploadResult(
        successUrls: filePaths.where((path) => 
          path.startsWith('http') && !path.startsWith('blob:')
        ).toList(),
        failedPaths: filePaths.where((path) => 
          !path.startsWith('http') || path.startsWith('blob:')
        ).toList(),
        errorMessage: 'Upload failed: $e',
        hasBlobs: filePaths.any((path) => path.startsWith('blob:')),
      );
    }
  }

  // Helper method to handle retries for a single file upload
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
      
      // Validate file size
      if (!await isValidFileSize(fileToUpload)) {
        print('File too large: ${fileToUpload.path}');
        return null;
      }
    } catch (e) {
      print('Error preparing file for upload: $filePath - $e');
      return null;
    }
    
    while (attempts <= maxRetries) {
      try {
        // Attempt to upload
        final url = await uploadImage(fileToUpload);
        if (url != null) {
          return url;
        }
        
        // If we reached here, the upload failed but didn't throw an exception
        print('Upload returned null without exception');
        attempts++;
        await Future.delayed(Duration(seconds: 1 * attempts)); // Increasing delay for each retry
        
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
  
  // Public method to validate image files
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