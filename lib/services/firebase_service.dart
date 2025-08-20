import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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
      }
      return _firestore;
    } catch (e) {
      return null;
    }
  }

  static bool get isAvailable => firestore != null;

  // Check if Firebase is properly initialized
  static bool get isInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
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

  // Update only document links for an IPO
  static Future<void> updateIpoDocumentLinks(
    String id, {
    String? drhpLink,
    String? rhpLink,
    String? anchorLink,
    String? expectedPremium,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final updateData = <String, dynamic>{
        '_firebaseUpdatedAt': DateTime.now(),
      };

      // Create nested document_links object
      final documentLinksData = <String, String?>{};

      if (drhpLink != null) {
        if (drhpLink.isNotEmpty) {
          documentLinksData['drhp'] = drhpLink;
        }
      }

      if (rhpLink != null) {
        if (rhpLink.isNotEmpty) {
          documentLinksData['rhp'] = rhpLink;
        }
      }

      if (anchorLink != null) {
        if (anchorLink.isNotEmpty) {
          documentLinksData['anchor'] = anchorLink;
        }
      }

      // If we have any document links, update the nested object
      if (documentLinksData.isNotEmpty) {
        updateData['document_links'] = documentLinksData;
      } else {
        // If all links are empty, remove the document_links field
        updateData['document_links'] = FieldValue.delete();
      }

      // Handle expected premium at root level
      if (expectedPremium != null) {
        if (expectedPremium.isNotEmpty) {
          updateData['expectedPremium'] = expectedPremium;
        } else {
          updateData['expectedPremium'] = FieldValue.delete();
        }
      }

      await db.collection(iposCollectionName).doc(id).update(updateData);
    } catch (e) {
      throw Exception('Error updating IPO document links: $e');
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

        if (apiId != null && apiId.isNotEmpty && !seenIds.contains(apiId)) {
          seenIds.add(apiId);
          options.add(IpoOption(
            companyId: apiId, // Use the API-compatible ID
            companyName: companyName,
            category: category,
          ));
        }
      }

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

  // Get existing IPOs with their document IDs for updating
  static Future<Map<String, String>> getExistingIpoIdsWithDocIds(
      List<String> companyIds) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final existingIpos = <String, String>{}; // companyId -> documentId

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
            existingIpos[companyId] = doc.id;
          }
        }
      }

      return existingIpos;
    } catch (e) {
      throw Exception('Error checking existing IPO IDs with doc IDs: $e');
    }
  }

  // Update IPO with category
  static Future<void> updateIpoWithCategory(String id, IpoModel ipo,
      {String? category}) async {
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

      await db.collection(iposCollectionName).doc(id).update(firestoreData);
    } catch (e) {
      throw Exception('Error updating IPO with category: $e');
    }
  }

  // Add or update IPO with category (upsert operation)
  static Future<String> addOrUpdateIpo(IpoModel ipo, {String? category}) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Check if IPO already exists
      final existingIpo = await getIpoByCompanyId(ipo.companyId);

      if (existingIpo != null && existingIpo.id != null) {
        // Update existing IPO with new data and category
        await updateIpoWithCategory(existingIpo.id!, ipo, category: category);
        return existingIpo.id!;
      } else {
        // Add new IPO
        return await addIpo(ipo, category: category);
      }
    } catch (e) {
      throw Exception('Error adding or updating IPO: $e');
    }
  }

  // Bulk update multiple IPOs using batch operations
  static Future<Map<String, dynamic>> bulkUpdateIpos(
    List<Map<String, dynamic>> ipoUpdates,
  ) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = db.batch();
      int successCount = 0;
      int failureCount = 0;
      final List<String> failedCompanies = [];

      for (final update in ipoUpdates) {
        try {
          final String docId = update['docId'] as String;
          final IpoModel ipo = update['ipo'] as IpoModel;

          final docRef = db.collection(iposCollectionName).doc(docId);
          batch.update(docRef, ipo.toFirestore());
          successCount++;
        } catch (e) {
          failureCount++;
          final companyName = (update['ipo'] as IpoModel).companyName ??
              (update['ipo'] as IpoModel).companyId;
          failedCompanies.add(companyName);
        }
      }

      if (successCount > 0) {
        await batch.commit();
      }

      return {
        'successCount': successCount,
        'failureCount': failureCount,
        'failedCompanies': failedCompanies,
      };
    } catch (e) {
      throw Exception('Error during bulk update: $e');
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
