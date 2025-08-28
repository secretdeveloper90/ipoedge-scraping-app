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
      // First try to get documents with ordering by _firebaseCreatedAt
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await db
            .collection(collectionName)
            .orderBy('_firebaseCreatedAt', descending: true)
            .get();
      } catch (orderError) {
        // If ordering fails (field doesn't exist), get all documents without ordering
        querySnapshot = await db.collection(collectionName).get();
      }

      final ipos = querySnapshot.docs
          .map((doc) => IpoModel.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      return ipos;
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
      // Get all documents and filter manually since nested field queries work better this way
      final allDocsSnapshot = await db.collection(iposCollectionName).get();

      for (final doc in allDocsSnapshot.docs) {
        final data = doc.data();
        String? ipoId;

        // Check nested company_headers.ipo_id first (this is where the ID is actually stored)
        if (data['company_headers'] != null) {
          final headers = data['company_headers'] as Map<String, dynamic>;
          ipoId = headers['ipo_id']?.toString();
        }

        // Fallback to other field names (though these likely don't exist)
        ipoId ??= data['ipo_id']?.toString() ??
            data['companyId']?.toString() ??
            data['company_id']?.toString();

        if (ipoId == companyId) {
          return IpoModel.fromFirestore(data, doc.id);
        }
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

  // Update company details and document links for an IPO
  static Future<void> updateIpoDocumentLinksAndCompanyDetails(
    String id, {
    String? drhpLink,
    String? rhpLink,
    String? anchorLink,
    String? expectedPremium,
    String? companyLogo,
    String? companyName,
    String? companyAddress,
    String? companyEmail,
    String? companyPhone,
    String? companyWebsite,
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

      // Handle company logo in company_headers
      if (companyLogo != null) {
        if (companyLogo.isNotEmpty) {
          updateData['company_headers.company_logo'] = companyLogo;
        } else {
          updateData['company_headers.company_logo'] = FieldValue.delete();
        }
      }

      // Handle company details in nested object
      final companyDetailsData = <String, dynamic>{};
      bool hasCompanyDetails = false;

      if (companyName != null && companyName.isNotEmpty) {
        companyDetailsData['company_name'] = companyName;
        hasCompanyDetails = true;
      }

      if (companyAddress != null) {
        if (companyAddress.isNotEmpty) {
          companyDetailsData['address'] = companyAddress;
          hasCompanyDetails = true;
        }
      }

      if (companyEmail != null) {
        if (companyEmail.isNotEmpty) {
          companyDetailsData['email'] = companyEmail;
          hasCompanyDetails = true;
        }
      }

      if (companyPhone != null) {
        if (companyPhone.isNotEmpty) {
          companyDetailsData['phone'] = companyPhone;
          hasCompanyDetails = true;
        }
      }

      if (companyWebsite != null) {
        if (companyWebsite.isNotEmpty) {
          companyDetailsData['website'] = companyWebsite;
          hasCompanyDetails = true;
        }
      }

      // If we have any company details, update the nested object
      if (hasCompanyDetails) {
        updateData['company_details'] = companyDetailsData;
      }

      await db.collection(iposCollectionName).doc(id).update(updateData);
    } catch (e) {
      throw Exception(
          'Error updating IPO document links and company details: $e');
    }
  }

  // Update only specific IPO fields (category, subscription data, listing data)
  static Future<void> updateIpoSpecificFields(
    String id, {
    String? category,
    bool? recentlyListed,
    String? subscriptionColor,
    String? subscriptionText,
    dynamic subscriptionValue,
    dynamic listingGains,
    dynamic sharesOnOffer,
    dynamic subscriptionRate,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final updateData = <String, dynamic>{};

      // Update Firebase timestamp
      updateData['_firebaseUpdatedAt'] = DateTime.now();

      // Update category field
      if (category != null) {
        updateData['category'] = category;
      }

      // Update recentlyListed field
      if (recentlyListed != null) {
        updateData['recentlyListed'] = recentlyListed;
      }

      // Update subscription-related fields
      if (subscriptionColor != null) {
        updateData['subscription_color'] = subscriptionColor;
      }
      if (subscriptionText != null) {
        updateData['subscription_text'] = subscriptionText;
      }
      if (subscriptionValue != null) {
        updateData['subscription_value'] = subscriptionValue;
      }

      // Update listing gains
      if (listingGains != null) {
        updateData['listing_gains'] = listingGains;
      }

      // Update shares on offer
      if (sharesOnOffer != null) {
        updateData['shares_on_offer'] = sharesOnOffer;
      }

      // Update subscription rate
      if (subscriptionRate != null) {
        updateData['subscription_rate'] = subscriptionRate;
      }

      // Only update if there are fields to update
      if (updateData.length > 1) {
        // More than just the timestamp
        await db.collection(iposCollectionName).doc(id).update(updateData);
      }
    } catch (e) {
      throw Exception('Error updating IPO specific fields: $e');
    }
  }

  // Get category from IPO analysis collection by company ID
  static Future<String?> getCategoryFromIpoAnalysis(String companyId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      print('Searching for company ID: $companyId in ipo_analysis collection');

      // Only check for these specific categories
      const allowedCategories = [
        'listing_soon',
        'recently_listed',
        'upcoming_open'
      ];

      // Try multiple field names that might contain the company identifier
      final searchFields = [
        'company_id',
        'ipo_id',
        'company_slug_name',
        'companyId',
        'company_name',
        'company_short_name',
      ];

      for (final fieldName in searchFields) {
        print('Trying field: $fieldName');

        final querySnapshot = await db
            .collection(collectionName)
            .where(fieldName, isEqualTo: companyId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final category = data['category']?.toString();
          print('Found match in field $fieldName, category: $category');

          // Only return category if it's in the allowed list
          if (category != null && allowedCategories.contains(category)) {
            return category;
          } else {
            print(
                'Category $category is not in allowed categories: $allowedCategories');
          }
        }
      }

      // If exact match fails, try partial matching within allowed categories only
      print(
          'Exact match failed, trying partial matching in allowed categories...');

      // Query only documents with allowed categories
      for (final allowedCategory in allowedCategories) {
        final categoryDocs = await db
            .collection(collectionName)
            .where('category', isEqualTo: allowedCategory)
            .limit(50)
            .get();

        print(
            'Checking ${categoryDocs.docs.length} documents in category: $allowedCategory');

        for (final doc in categoryDocs.docs) {
          final data = doc.data();

          // Check if any field contains the companyId as substring
          for (final fieldName in searchFields) {
            final fieldValue = data[fieldName]?.toString();
            if (fieldValue != null) {
              final lowerFieldValue = fieldValue.toLowerCase();
              final lowerCompanyId = companyId.toLowerCase();
              if (lowerFieldValue.contains(lowerCompanyId) ||
                  lowerCompanyId.contains(lowerFieldValue)) {
                final category = data['category']?.toString();
                print(
                    'Found partial match in field $fieldName: $fieldValue, category: $category');
                return category;
              }
            }
          }
        }
      }

      print(
          'No match found for company ID: $companyId in allowed categories: $allowedCategories');
      return null;
    } catch (e) {
      print('Error in getCategoryFromIpoAnalysis: $e');
      throw Exception('Error fetching category from IPO analysis: $e');
    }
  }

  // Debug method to see what's in IPO analysis collection
  static Future<List<Map<String, dynamic>>> debugIpoAnalysisCollection() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db.collection(collectionName).limit(10).get();
      final results = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        results.add({
          'docId': doc.id,
          'company_id': data['company_id'],
          'ipo_id': data['ipo_id'],
          'company_slug_name': data['company_slug_name'],
          'companyId': data['companyId'],
          'company_name': data['company_name'],
          'company_short_name': data['company_short_name'],
          'category': data['category'],
          'allKeys': data.keys.toList(),
        });
      }

      return results;
    } catch (e) {
      throw Exception('Error debugging IPO analysis collection: $e');
    }
  }

  // Update category in IPO management from IPO analysis
  static Future<void> updateCategoryFromAnalysis(
      String id, String companyId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Get category from IPO analysis collection
      final category = await getCategoryFromIpoAnalysis(companyId);

      if (category != null) {
        final updateData = <String, dynamic>{
          'category': category,
          '_firebaseUpdatedAt': DateTime.now(),
        };

        await db.collection(iposCollectionName).doc(id).update(updateData);
      } else {
        // Debug: Show what's available in the collection
        final debugData = await debugIpoAnalysisCollection();
        print('Available IPO analysis data:');
        for (final item in debugData) {
          print('Doc: ${item['docId']}, Company fields: ${item}');
        }
        throw Exception(
            'Category not found in IPO analysis for company: $companyId. Check debug output above.');
      }
    } catch (e) {
      throw Exception('Error updating category from analysis: $e');
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
      // Get all documents and filter manually since nested field queries work better this way
      final allDocsSnapshot = await db.collection(iposCollectionName).get();

      for (final doc in allDocsSnapshot.docs) {
        final data = doc.data();
        String? ipoId;

        // Check nested company_headers.ipo_id first (this is where the ID is actually stored)
        if (data['company_headers'] != null) {
          final headers = data['company_headers'] as Map<String, dynamic>;
          ipoId = headers['ipo_id']?.toString();
        }

        // Fallback to other field names (though these likely don't exist)
        ipoId ??= data['ipo_id']?.toString() ??
            data['companyId']?.toString() ??
            data['company_id']?.toString();

        if (ipoId == companyId) {
          return true;
        }
      }

      return false;
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
      // Define allowed categories
      const allowedCategories = [
        'listing_soon',
        'recently_listed',
        'upcoming_open'
      ];

      final querySnapshot =
          await db.collection(collectionName).orderBy('company_name').get();

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
        }

        final companyName = data['companyName']?.toString() ??
            data['company_name']?.toString() ??
            displayId ??
            apiId ??
            '';

        final category = data['category']?.toString() ?? 'unknown';

        // Only include IPOs from allowed categories
        if (allowedCategories.contains(category) &&
            apiId != null &&
            apiId.isNotEmpty &&
            !seenIds.contains(apiId)) {
          seenIds.add(apiId);
          options.add(IpoOption(
            companyId: apiId,
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

      // Get all documents and filter manually since nested field queries don't work well with whereIn
      final allDocsSnapshot = await db.collection(iposCollectionName).get();

      for (final doc in allDocsSnapshot.docs) {
        final data = doc.data();
        String? ipoId;

        // Check nested company_headers.ipo_id first (this is where the ID is actually stored)
        if (data['company_headers'] != null) {
          final headers = data['company_headers'] as Map<String, dynamic>;
          ipoId = headers['ipo_id']?.toString();
        }

        if (ipoId != null &&
            companyIds.contains(ipoId) &&
            !existingIds.contains(ipoId)) {
          existingIds.add(ipoId);
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
      final existingIpos = <String, String>{}; // ipoId -> documentId

      // Get all documents and filter manually since nested field queries don't work well with whereIn
      final allDocsSnapshot = await db.collection(iposCollectionName).get();

      for (final doc in allDocsSnapshot.docs) {
        final data = doc.data();
        String? ipoId;

        // Check nested company_headers.ipo_id first (this is where the ID is actually stored)
        if (data['company_headers'] != null) {
          final headers = data['company_headers'] as Map<String, dynamic>;
          ipoId = headers['ipo_id']?.toString();
        }

        // Fallback to other field names (though these likely don't exist)
        ipoId ??= data['ipo_id']?.toString() ??
            data['companyId']?.toString() ??
            data['company_id']?.toString();

        if (ipoId != null && companyIds.contains(ipoId)) {
          existingIpos[ipoId] = doc.id;
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

  // Bulk update multiple IPOs using batch operations (specific fields only)
  static Future<Map<String, dynamic>> bulkUpdateIposSpecificFields(
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
          final data = ipo.additionalData;

          final updateData = <String, dynamic>{};

          // Update Firebase timestamp
          updateData['_firebaseUpdatedAt'] = DateTime.now();

          // Extract and update only specific fields
          if (data != null) {
            if (data.containsKey('category')) {
              updateData['category'] = data['category'];
            }
            if (data.containsKey('recentlyListed')) {
              updateData['recentlyListed'] = data['recentlyListed'];
            }
            if (data.containsKey('subscription_color')) {
              updateData['subscription_color'] = data['subscription_color'];
            }
            if (data.containsKey('subscription_text')) {
              updateData['subscription_text'] = data['subscription_text'];
            }
            if (data.containsKey('subscription_value')) {
              updateData['subscription_value'] = data['subscription_value'];
            }
            if (data.containsKey('listing_gains')) {
              updateData['listing_gains'] = data['listing_gains'];
            }
            if (data.containsKey('shares_on_offer')) {
              updateData['shares_on_offer'] = data['shares_on_offer'];
            }
            if (data.containsKey('subscription_rate')) {
              updateData['subscription_rate'] = data['subscription_rate'];
            }
          }

          // Only update if there are fields to update
          if (updateData.length > 1) {
            // More than just the timestamp
            final docRef = db.collection(iposCollectionName).doc(docId);
            batch.update(docRef, updateData);
          }
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

  // Bulk update multiple IPOs using batch operations (full update - deprecated)
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
