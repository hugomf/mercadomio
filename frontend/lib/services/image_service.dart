
class ImageService {
  static const String _baseUrl = 'http://localhost:8080';
  
  /// Returns the absolute URL for an image
  static String getImageUrl(String imagePath) {
    // Remove any leading slashes to avoid double slashes
    imagePath = imagePath.replaceFirst(RegExp(r'^/'), '');
    
    // If it's already an absolute URL, return it
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // If it's a relative path, convert to absolute
    return '$_baseUrl/images/$imagePath';
  }
  
  /// Returns the URL for a product image (via Cloudinary proxy)
  static String getProductImageUrl(String productCode, {String suffix = '_1', String transformation = 'f_auto,q_auto'}) {
    return '$_baseUrl/api/images/products/$productCode$suffix.jpg?t=$transformation';
  }
  
  /// Returns the base URL for images
  static String get baseUrl => _baseUrl;
}