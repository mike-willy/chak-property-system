// lib/core/common/config.dart

class AppConfig {
  // Environment flags
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool isSandbox = !isProduction;
  
  // M-Pesa Configuration
  static const String mpesaEnvironment = isProduction ? 'production' : 'sandbox';


  // Sandbox credentials (current)
  static const String sandboxConsumerKey = '8FNIevuEJAJPEAXFMaDoOKA8zS0EybwYgJuzONHkvmUYEz03';
  static const String sandboxConsumerSecret = 'ej9egtGQrdrGeh4IMBAlCXDjCIyYc9wpxv24reU6O2gw5NblVv1m2PGGse2vCXzY';
  static const String sandboxPasskey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
  static const String sandboxShortCode = '174379';
  static const String sandboxCallbackUrl = 'https://undegrading-marcelo-euphemistical.ngrok-free.dev';
  
  // Production credentials (to be filled when going live)
  static const String prodConsumerKey = 'YOUR_PRODUCTION_CONSUMER_KEY';
  static const String prodConsumerSecret = 'YOUR_PRODUCTION_CONSUMER_SECRET';
  static const String prodPasskey = 'YOUR_PRODUCTION_PASSKEY';
  static const String prodShortCode = 'YOUR_PRODUCTION_SHORTCODE';
  static const String prodCallbackUrl = 'https://your-production-server.com/api/mpesa/callback';
  
  // Active configuration based on environment
  static String get mpesaConsumerKey => isProduction ? prodConsumerKey : sandboxConsumerKey;
  static String get mpesaConsumerSecret => isProduction ? prodConsumerSecret : sandboxConsumerSecret;
  static String get mpesaPasskey => isProduction ? prodPasskey : sandboxPasskey;
  static String get mpesaShortCode => isProduction ? prodShortCode : sandboxShortCode;
  static String get mpesaCallbackUrl => isProduction ? prodCallbackUrl : sandboxCallbackUrl;
  
  static String get mpesaBaseUrl => isProduction 
      ? 'https://api.safaricom.co.ke' 
      : 'https://sandbox.safaricom.co.ke';
}

