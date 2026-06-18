class AppConstants {
  static const String appName = 'LocalTrade';
  
  // Choose the correct URL based on your environment
  // Original Production URL (Use this if you haven't renamed your Render service)
  static const String baseUrl = 'https://localtrade-backend.onrender.com/api/v1'; 
  
  // Local Testing URL (Android Emulator)
  // static const String baseUrl = 'http://10.0.2.2:5000/api/v1'; 
  
  // Storage keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'user_data';
}
