// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all properties
  static Future<List<Map<String, dynamic>>> fetchProperties() async {
    try {
      final querySnapshot = await _firestore.collection('properties').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'createdAt': data['createdAt']?.toDate(),
          'updatedAt': data['updatedAt']?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching properties: $e');
      throw e;
    }
  }

  // Update property status
  static Future<void> updatePropertyStatus(String propertyId, String newStatus) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        'status': newStatus.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating property status: $e');
      throw e;
    }
  }

  // Add new property
  static Future<void> addProperty(Map<String, dynamic> propertyData) async {
    try {
      await _firestore.collection('properties').add({
        ...propertyData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding property: $e');
      throw e;
    }
  }

  // Update existing property
  static Future<void> updateProperty(String propertyId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating property: $e');
      throw e;
    }
  }

  // Delete property
  static Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
      print('Error deleting property: $e');
      throw e;
    }
  }
}