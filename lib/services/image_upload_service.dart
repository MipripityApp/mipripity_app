import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

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
  // ImgBB configuration for fallback
  static const String apiKey = '3d5860aa87a1edb40dead8debc3c983e'; // Get a free key from imgbb.com
  static const String uploadUrl = 'https://api.imgbb.com/1/upload';
  
  // Cloudinary configuration
  static final cloudinary = CloudinaryPublic(
    'dxhrlaz6j',
    'mipripity',
    cache: false,
  );

  // Backend API URL - update with your actual backend URL
  static const String backendUploadUrl = 'http://localhost:8080/upload';
  
  // List to store uploaded image URLs
  static List<String> uploadedImageUrls = [];
  
  // Pick and upload image to backend method (from task specification)
  static Future<void> pickAndUploadImageToBackend() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final String fileName = basename(imageFile.path);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(backendUploadUrl),
      );

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        final imageUrl = data['url'];
        uploadedImageUrls.add(imageUrl);
        print('✅ Image uploaded: $imageUrl');
      } else {
        print('❌ Upload failed: ${response.statusCode}');
      }
    } else {
      print("No image selected");
    }
  }
  
  // Upload a single image via backend with better error handling
  static Future<String?> uploadViaBackend(File imageFile) async {
    try {
      // Check file size before uploading
      if (!await isValidFileSize(imageFile)) {
        print('File too large: ${imageFile.path}');
        return null;
      }
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(backendUploadUrl));
      
      // Add file to request
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
        filename: basename(imageFile.path),
      ));
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        return data['url'];
      } else {
        print('Backend upload failed with status: ${response.statusCode}');
        // Fallback to direct Cloudinary upload
        return uploadToCloudinary(imageFile);
      }
    } catch (e) {
      print('Backend upload error: $e');
      // Fallback to direct Cloudinary upload
      return uploadToCloudinary(imageFile);
    }
  }
  
  // Direct upload to Cloudinary with better error handling (now used as fallback)
  static Future<String?> uploadToCloudinary(File imageFile) async {
    try {
      // Check file size before uploading
      if (!await isValidFileSize(imageFile)) {
        print('File too large: ${imageFile.path}');
        return null;
      }

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
  
  // Upload multiple images via backend with comprehensive error handling
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
      print('Exception in uploadMultipleToCloudinary: $e');
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

  // Helper method to handle retries for a single file upload - now using backend upload
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
        final url = await uploadViaBackend(fileToUpload);
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
        print('Image upload failed: ${jsonData['error']?['message'] ?? 'Unknown error'}');
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
