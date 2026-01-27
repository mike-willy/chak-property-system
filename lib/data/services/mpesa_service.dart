
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MpesaService {
  // Sandbox credentials - REPLACE WITH YOUR ACTUAL CREDENTIALS
  static const String consumerKey = '8FNIevuEJAJPEAXFMaDoOKA8zS0EybwYgJuzONHkvmUYEz03'; // Get from Daraja portal
  static const String consumerSecret = 'ej9egtGQrdrGeh4IMBAlCXDjCIyYc9wpxv24reU6O2gw5NblVv1m2PGGse2vCXzY'; // Get from Daraja portal
  static const String passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // Sandbox passkey
  static const String shortCode = '174379'; // Sandbox shortcode
  static const String callbackUrl = 'https://undegrading-marcelo-euphemistical.ngrok-free.dev'; // Your backend URL
  
  
  // Sandbox base URL
  static const String baseUrl = 'https://sandbox.safaricom.co.ke';
  
  /// Generate OAuth access token
  Future<String> getAccessToken() async {
    try {
      print('🔐 Generating M-Pesa access token...');
      
      final credentials = base64Encode(
        utf8.encode('$consumerKey:$consumerSecret'),
      );
      
      final url = Uri.parse('$baseUrl/oauth/v1/generate?grant_type=client_credentials');
      
      print('📡 Token URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 'User-Agent': 'FlutterApp/1.0', // Optional: Use a custom UA or let Dart set default
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Token request timeout - Check your internet connection');
        },
      );
      
      print('📥 Token Response Status: ${response.statusCode}');
      print('📥 Token Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        
        if (token == null || token.isEmpty) {
          throw Exception('Access token is null or empty');
        }
        
        print('✅ Access token generated successfully');
        return token;
      } else {
        final errorBody = response.body;
        print('❌ Token generation failed: $errorBody');
        throw Exception('Failed to generate access token: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('❌ Exception in getAccessToken: $e');
      rethrow;
    }
  }
  
  /// Initiate STK Push (Lipa Na M-Pesa Online)
  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    String? transactionDesc,
  }) async {
    try {
      print('🚀 Initiating STK Push...');
      print('📱 Phone: $phoneNumber');
      print('💰 Amount: $amount');
      print('📝 Reference: $accountReference');
      
      // Get access token
      final accessToken = await getAccessToken();
      
      // Format phone number (remove leading 0 or +254, ensure it starts with 254)
      String formattedPhone = phoneNumber.trim();
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '254${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('+254')) {
        formattedPhone = formattedPhone.substring(1);
      } else if (!formattedPhone.startsWith('254')) {
        formattedPhone = '254$formattedPhone';
      }
      
      print('📞 Formatted Phone: $formattedPhone');
      
      // Generate timestamp
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      
      // Generate password
      final password = base64Encode(
        utf8.encode('$shortCode$passkey$timestamp'),
      );
      
      // Prepare request body
      final requestBody = {
        'BusinessShortCode': shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toInt().toString(),
        'PartyA': formattedPhone,
        'PartyB': shortCode,
        'PhoneNumber': formattedPhone,
        'CallBackURL': callbackUrl,
        'AccountReference': accountReference,
        'TransactionDesc': transactionDesc ?? 'Rent Payment',
      };
      
      print('📤 Request Body: ${json.encode(requestBody)}');
      
      final url = Uri.parse('$baseUrl/mpesa/stkpush/v1/processrequest');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('STK Push request timeout - Please try again');
        },
      );
      
      print('📥 STK Push Response Status: ${response.statusCode}');
      print('📥 STK Push Response Body: ${response.body}');
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        if (responseData['ResponseCode'] == '0') {
          print('✅ STK Push initiated successfully');
          return {
            'success': true,
            'checkoutRequestId': responseData['CheckoutRequestID'],
            'merchantRequestId': responseData['MerchantRequestID'],
            'responseCode': responseData['ResponseCode'],
            'responseDescription': responseData['ResponseDescription'],
            'customerMessage': responseData['CustomerMessage'],
          };
        } else {
          print('⚠️ STK Push failed: ${responseData['ResponseDescription']}');
          return {
            'success': false,
            'error': responseData['ResponseDescription'] ?? 'Unknown error',
            'errorCode': responseData['ResponseCode'],
          };
        }
      } else {
        print('❌ STK Push request failed: ${response.statusCode}');
        throw Exception('STK Push failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in initiateStkPush: $e');
      rethrow;
    }
  }
  
  /// Query transaction status
  Future<Map<String, dynamic>> queryTransactionStatus({
    required String checkoutRequestId,
  }) async {
    try {
      print('🔍 Querying transaction status...');
      
      final accessToken = await getAccessToken();
      
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final password = base64Encode(
        utf8.encode('$shortCode$passkey$timestamp'),
      );
      
      final requestBody = {
        'BusinessShortCode': shortCode,
        'Password': password,
        'Timestamp': timestamp,
        'CheckoutRequestID': checkoutRequestId,
      };
      
      final url = Uri.parse('$baseUrl/mpesa/stkpushquery/v1/query');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      print('📥 Query Response Status: ${response.statusCode}');
      print('📥 Query Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Query failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in queryTransactionStatus: $e');
      rethrow;
    }
  }
}