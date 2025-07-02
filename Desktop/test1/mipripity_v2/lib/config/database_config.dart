class DatabaseConfig {
  // Neon Database Configuration
  static const String projectId = 'square-moon-79559388';
  static const String apiKey = 'napi_ey0x7whnbwh6024joqs9d81tptipkqb1v7kuscv3vv1bnts2gg7mt27nnngh083h';
  
  // API Base URL - This will be your Vercel deployment URL
  // After deploying to Vercel, update this with your deployment URL
  static const String apiBaseUrl = 'https://mipripity-api.vercel.app/api';
  
  // API Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
