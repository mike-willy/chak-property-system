import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MpesaService {
  // TODO: Move these to remote config or environment variables in production
  final String _consumerKey = 'YOUR_CONSUMER_KEY'; // Replace with Sandbox/Prod Key
  final String _consumerSecret = 'YOUR_CONSUMER_SECRET'; // Replace with Sandbox/Prod Secret
  final String _passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; // Sandbox Passkey
  
  final String _baseUrl = 'https://sandbox.safaricom.co.ke'; // Change to https://api.safaricom.co.ke for PROD
  
  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<String> getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    try {
      final String basicAuth = 'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';
      
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final int expiresIn = int.tryParse(data['expires_in'].toString()) ?? 3599;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
        return _accessToken!;
      } else {
        throw Exception('Failed to generate access token: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating M-Pesa access token: $e');
    }
  }

  Future<Map<String, dynamic>> initiateStkPush({
    required String phoneNumber,
    required double amount,
    required String accountReference,
    required String transactionDesc,
  }) async {
    try {
      final token = await getAccessToken();
      final timestamp = _getTimestamp();
      final password = base64Encode(utf8.encode('174379$_passkey$timestamp'));

      final Map<String, dynamic> requestBody = {
        "BusinessShortCode": 174379,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount.toInt(), // M-Pesa expects integer
        "PartyA": phoneNumber,
        "PartyB": 174379,
        "PhoneNumber": phoneNumber,
        "CallBackURL": "https://us-central1-chak-property-system.cloudfunctions.net/mpesaCallback", // Placeholder
        "AccountReference": accountReference,
        "TransactionDesc": transactionDesc
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception('STK Push failed: ${data['errorMessage'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error initiating STK Push: $e');
    }
  }

  Future<Map<String, dynamic>> queryTransactionStatus(String checkoutRequestId) async {
    try {
      final token = await getAccessToken();
      final timestamp = _getTimestamp();
      final password = base64Encode(utf8.encode('174379$_passkey$timestamp'));

      final Map<String, dynamic> requestBody = {
        "BusinessShortCode": 174379,
        "Password": password,
        "Timestamp": timestamp,
        "CheckoutRequestID": checkoutRequestId
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpushquery/v1/query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      return json.decode(response.body);
    } catch (e) {
      throw Exception('Error querying status: $e');
    }
  }

  String _getTimestamp() {
    return DateFormat('yyyyMMddHHmmss').format(DateTime.now());
  }
}

// Helper for formatting specifically for M-Pesa
class DateFormat {
  final String pattern;
  DateFormat(this.pattern);
  
  String format(DateTime date) {
    // Simple implementation for yyyyMMddHHmmss
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$y$m$d$h$min$s';
  }
}
