import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/ipo_model.dart';
import 'api_service.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static const String collectionName = 'ipo_analysis';
  static const String iposCollectionName = 'ipos';

  static FirebaseFirestore? get firestore {
    try {
      if (_firestore == null) {
        _firestore = FirebaseFirestore.instance;
        debugPrint('Firebase Firestore instance created successfully');
      }
      return _firestore;
    } catch (e) {
      debugPrint('Firebase Firestore not available: $e');
      return null;
    }
  }

  static bool get isAvailable => firestore != null;

  // Check if Firebase is properly initialized
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking Firebase initialization: $e');
      return false;
    }
  }

  // Add a new IPO to Firebase
  static Future<String> addIpo(IpoModel ipo, {String? category}) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final firestoreData = ipo.toFirestore();

      // Add category if provided
      if (category != null) {
        firestoreData['category'] = category;
      }

      final docRef = await db.collection(iposCollectionName).add(firestoreData);

      return docRef.id;
    } catch (e) {
      throw Exception('Error adding IPO: $e');
    }
  }

  // Get all IPOs from Firebase
  static Future<List<IpoModel>> getAllIpos() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(iposCollectionName)
          .orderBy('_firebaseCreatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => IpoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching IPOs: $e');
    }
  }

  // Get all IPOs from Firebase ipo_analysis collection
  static Future<List<IpoModel>> getAllIposFromAnalysis() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(collectionName)
          .orderBy('_firebaseCreatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => IpoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error getting IPOs from analysis collection: $e');
    }
  }

  // Get IPO by document ID
  static Future<IpoModel?> getIpoById(String id) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot = await db.collection(iposCollectionName).doc(id).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        return IpoModel.fromFirestore(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching IPO: $e');
    }
  }

  // Get IPO by company ID
  static Future<IpoModel?> getIpoByCompanyId(String companyId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(iposCollectionName)
          .where('companyId', isEqualTo: companyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return IpoModel.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching IPO by company ID: $e');
    }
  }

  // Update an existing IPO
  static Future<void> updateIpo(String id, IpoModel ipo) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db.collection(iposCollectionName).doc(id).update(ipo.toFirestore());
    } catch (e) {
      throw Exception('Error updating IPO: $e');
    }
  }

  // Delete an IPO
  static Future<void> deleteIpo(String id) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db.collection(iposCollectionName).doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting IPO: $e');
    }
  }

  // Check if IPO with company ID already exists
  static Future<bool> ipoExistsByCompanyId(String companyId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(iposCollectionName)
          .where('companyId', isEqualTo: companyId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking IPO existence: $e');
    }
  }

  // Get IPOs stream for real-time updates
  static Stream<List<IpoModel>> getIposStream() {
    final db = firestore;
    if (db == null) {
      return Stream.value([]);
    }

    return db
        .collection(iposCollectionName)
        .orderBy('_firebaseCreatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IpoModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Search IPOs by company name
  static Future<List<IpoModel>> searchIposByCompanyName(
      String searchTerm) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(iposCollectionName)
          .where('companyName', isGreaterThanOrEqualTo: searchTerm)
          .where('companyName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      return querySnapshot.docs
          .map((doc) => IpoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error searching IPOs: $e');
    }
  }

  // Get IPOs by year (from listing date)
  static Future<List<IpoModel>> getIposByYear(int year) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year + 1, 1, 1);

      final querySnapshot = await db
          .collection(iposCollectionName)
          .where('_firebaseCreatedAt', isGreaterThanOrEqualTo: startDate)
          .where('_firebaseCreatedAt', isLessThan: endDate)
          .orderBy('_firebaseCreatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => IpoModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching IPOs by year: $e');
    }
  }

  // Batch operations for multiple IPOs
  static Future<void> addMultipleIpos(List<IpoModel> ipos,
      {String? category}) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = db.batch();

      for (final ipo in ipos) {
        final docRef = db.collection(iposCollectionName).doc();
        final firestoreData = ipo.toFirestore();

        // Add category if provided
        if (category != null) {
          firestoreData['category'] = category;
        }

        batch.set(docRef, firestoreData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error adding multiple IPOs: $e');
    }
  }

  // Update all IPO data from API to Firebase ipo_analysis collection
  static Future<void> updateAllIpoData() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Fetch all categorized IPOs from API
      final categorizedIpos = await ApiService.getCategorizedIpos();

      // Clear existing data in ipo_analysis collection
      final existingDocs = await db.collection(collectionName).get();
      final batch = db.batch();

      // Delete existing documents
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add all new IPO data
      for (final category in categorizedIpos.entries) {
        for (final ipo in category.value) {
          final docRef = db.collection(collectionName).doc();
          final firestoreData = ipo.toFirestore();
          // Add category information
          firestoreData['category'] = category.key;
          batch.set(docRef, firestoreData);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error updating all IPO data: $e');
    }
  }

  // Get available IPO options for dropdown selection
  static Future<List<IpoOption>> getAvailableIpoOptions() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot =
          await db.collection(collectionName).orderBy('companyName').get();

      final seenIds = <String>{};
      final options = <IpoOption>[];

      debugPrint(
          'DEBUG: Total documents in Firebase: ${querySnapshot.docs.length}');

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Try to get the correct API identifier
        // Priority: ipo_id (numeric) > company_id > companyId > company_slug_name
        String? apiId;
        String? displayId;

        // For API calls, prefer numeric ipo_id
        if (data['ipo_id'] != null) {
          apiId = data['ipo_id'].toString();
        } else if (data['company_id'] != null) {
          apiId = data['company_id'].toString();
        } else if (data['companyId'] != null) {
          apiId = data['companyId'].toString();
        } else if (data['company_slug_name'] != null) {
          apiId = data['company_slug_name'].toString();
        }

        // For display, prefer company_slug_name or companyId
        if (data['company_slug_name'] != null) {
          displayId = data['company_slug_name'].toString();
        } else if (data['companyId'] != null) {
          displayId = data['companyId'].toString();
        } else if (data['ipo_id'] != null) {
          displayId = data['ipo_id'].toString();
        }

        final companyName = data['companyName']?.toString() ??
            data['company_name']?.toString() ??
            displayId ??
            apiId ??
            '';

        final category = data['category']?.toString() ?? 'unknown';

        debugPrint(
            'DEBUG: Processing IPO - ID: $apiId, Name: $companyName, Category: $category, Seen: ${seenIds.contains(apiId)}');

        if (apiId != null && apiId.isNotEmpty && !seenIds.contains(apiId)) {
          seenIds.add(apiId);
          options.add(IpoOption(
            companyId: apiId, // Use the API-compatible ID
            companyName: companyName,
            category: category,
          ));
          debugPrint(
              'DEBUG: Added IPO option - ID: $apiId, Name: $companyName');
        } else if (apiId != null && seenIds.contains(apiId)) {
          debugPrint(
              'DEBUG: Skipped duplicate IPO - ID: $apiId, Name: $companyName, Category: $category');
        }
      }

      debugPrint('DEBUG: Final unique IPO options count: ${options.length}');
      debugPrint(
          'DEBUG: Unique IPO IDs: ${options.map((o) => o.companyId).toList()}');

      return options;
    } catch (e) {
      throw Exception('Error fetching available IPO options: $e');
    }
  }

  // Check if multiple IPOs exist by company IDs
  static Future<List<String>> getExistingIpoIds(List<String> companyIds) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final existingIds = <String>[];

      // Check in batches to avoid Firestore query limitations
      const batchSize = 10;
      for (int i = 0; i < companyIds.length; i += batchSize) {
        final batch = companyIds.skip(i).take(batchSize).toList();

        final querySnapshot = await db
            .collection(iposCollectionName)
            .where('companyId', whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final companyId = data['companyId']?.toString();
          if (companyId != null) {
            existingIds.add(companyId);
          }
        }
      }

      return existingIds;
    } catch (e) {
      throw Exception('Error checking existing IPO IDs: $e');
    }
  }
}

// Data class for IPO dropdown options
class IpoOption {
  final String companyId;
  final String companyName;
  final String? category;

  IpoOption({
    required this.companyId,
    required this.companyName,
    this.category,
  });

  String get displayName {
    if (category != null) {
      return '$companyName ($companyId) - ${_formatCategory(category!)}';
    }
    return '$companyName ($companyId)';
  }

  String _formatCategory(String category) {
    switch (category) {
      case 'draft_issues':
        return 'Draft';
      case 'upcoming_open':
        return 'Upcoming';
      case 'listing_soon':
        return 'Listing Soon';
      case 'recently_listed':
        return 'Recently Listed';
      case 'gain_loss_analysis':
        return 'Gain/Loss';
      default:
        return category;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IpoOption &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId;

  @override
  int get hashCode => companyId.hashCode;
}
