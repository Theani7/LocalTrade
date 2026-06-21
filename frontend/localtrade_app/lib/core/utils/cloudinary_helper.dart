class CloudinaryHelper {
  /// Transforms a Cloudinary URL to include optimization and resizing parameters.
  /// Example: https://res.cloudinary.com/demo/image/upload/sample.jpg
  /// Becomes: https://res.cloudinary.com/demo/image/upload/q_auto,f_auto,w_500,c_limit/sample.jpg
  static String getOptimizedUrl(String url, {int? width, int? height}) {
    if (url.isEmpty || !url.contains('cloudinary.com')) return url;
    
    final String transformBase = 'q_auto,f_auto,c_limit';
    String transformations = transformBase;
    
    if (width != null) transformations += ',w_$width';
    if (height != null) transformations += ',h_$height';

    // Cloudinary URLs usually have /upload/ in them. We insert transformations after it.
    if (url.contains('/upload/')) {
      return url.replaceFirst('/upload/', '/upload/$transformations/');
    }
    
    return url;
  }
}
