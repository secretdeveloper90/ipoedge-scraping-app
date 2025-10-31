import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/ipo_model.dart';
import '../models/ipo_analysis_models.dart';
import 'api_service.dart';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  static const String collectionName = 'ipo_analysis';
  static const String iposCollectionName = 'ipos';
  static const String ipoManagementCollectionName = 'ipo_management';
  static const String ipoRemainingDataCollectionName = 'ipo_remaining_data';

  static FirebaseFirestore? get firestore {
    try {
      _firestore ??= FirebaseFirestore.instance;
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

  // Find IPO by slug
  static Future<IpoModel?> findIpoBySlug(String slug) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // First try to find by slug field
      final slugQuery = await db
          .collection(iposCollectionName)
          .where('slug', isEqualTo: slug)
          .limit(1)
          .get();

      if (slugQuery.docs.isNotEmpty) {
        final doc = slugQuery.docs.first;
        return IpoModel.fromFirestore(doc.data(), doc.id);
      }

      // If not found by slug, try to find by company name derived from slug
      final companyName = slug
          .replaceAll('-', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');

      final nameQuery = await db
          .collection(iposCollectionName)
          .where('companyName', isEqualTo: companyName)
          .limit(1)
          .get();

      if (nameQuery.docs.isNotEmpty) {
        final doc = nameQuery.docs.first;
        return IpoModel.fromFirestore(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      throw Exception('Error finding IPO by slug: $e');
    }
  }

  // Add IPO with specific data fields only
  static Future<String> addIpoWithSpecificData(
      Map<String, dynamic> apiData, String slug) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final firestoreData = _extractSpecificFields(apiData, slug);
      final docRef = await db.collection(iposCollectionName).add(firestoreData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding IPO with specific data: $e');
    }
  }

  // Update existing IPO with specific data fields only (MERGE, don't overwrite)
  static Future<void> updateIpoWithSpecificData(
      String docId, Map<String, dynamic> apiData, String slug) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final updateData = _extractSpecificFieldsForUpdate(apiData, slug);
      updateData['_firebaseUpdatedAt'] = DateTime.now();

      // Use set with merge: true to merge data instead of overwriting
      await db.collection(iposCollectionName).doc(docId).set(
            updateData,
            SetOptions(
                merge:
                    true), // This preserves existing data and only updates/adds new fields
          );
    } catch (e) {
      throw Exception('Error updating IPO with specific data: $e');
    }
  }

  // Extract only the specific fields you want to store
  static Map<String, dynamic> _extractSpecificFields(
      Map<String, dynamic> apiData, String? slug) {
    final firestoreData = <String, dynamic>{};

    // Add Firebase metadata
    firestoreData['_firebaseCreatedAt'] = DateTime.now();
    firestoreData['_firebaseUpdatedAt'] = DateTime.now();

    // Add slug if provided (for new documents)
    if (slug != null) {
      firestoreData['slug'] = slug;
    }

    // Store root level fields: IPOstatus, peersComparison, financialLotsize
    if (apiData['IPOstatus'] != null) {
      firestoreData['IPOstatus'] = apiData['IPOstatus'];
    }
    if (apiData['peersComparison'] != null) {
      firestoreData['peersComparison'] = apiData['peersComparison'];
    }
    if (apiData['financialLotsize'] != null) {
      firestoreData['financialLotsize'] = apiData['financialLotsize'];
      // Note: lot_details_message generation removed - will be handled on frontend
    }

    // Store document_links: {DRHPDraft, RHPDraft, AnchorInvestors}
    final documentLinks = <String, dynamic>{};
    if (apiData['DRHPDraft'] != null) {
      documentLinks['DRHPDraft'] = apiData['DRHPDraft'];
    }
    if (apiData['RHPDraft'] != null) {
      documentLinks['RHPDraft'] = apiData['RHPDraft'];
    }
    if (apiData['AnchorInvestors'] != null) {
      documentLinks['AnchorInvestors'] = apiData['AnchorInvestors'];
    }
    if (documentLinks.isNotEmpty) {
      firestoreData['document_links'] = documentLinks;
    }

    // Store registrar_details: {registerName, registerPhone, registerEmail, registerWebsite}
    final registrarDetails = <String, dynamic>{};
    if (apiData['registerName'] != null) {
      registrarDetails['registerName'] = apiData['registerName'];
    }
    if (apiData['registerPhone'] != null) {
      registrarDetails['registerPhone'] = apiData['registerPhone'];
    }
    if (apiData['registerEmail'] != null) {
      registrarDetails['registerEmail'] = apiData['registerEmail'];
    }
    if (apiData['registerWebsite'] != null) {
      registrarDetails['registerWebsite'] = apiData['registerWebsite'];
    }
    if (registrarDetails.isNotEmpty) {
      firestoreData['registrar_details'] = registrarDetails;
    }

    // Store company_details: {companyName, address, companyPhone, email, website}
    final companyDetails = <String, dynamic>{};
    if (apiData['companyName'] != null) {
      companyDetails['companyName'] = apiData['companyName'];
    }
    if (apiData['address'] != null) {
      companyDetails['address'] = apiData['address'];
    }
    if (apiData['companyPhone'] != null) {
      companyDetails['companyPhone'] = apiData['companyPhone'];
    }
    if (apiData['email'] != null) {
      companyDetails['email'] = apiData['email'];
    }
    if (apiData['website'] != null) {
      companyDetails['website'] = apiData['website'];
    }
    if (companyDetails.isNotEmpty) {
      firestoreData['company_details'] = companyDetails;
    }

    return firestoreData;
  }

  // Extract ONLY the specific fields you requested for updating existing documents
  static Map<String, dynamic> _extractSpecificFieldsForUpdate(
      Map<String, dynamic> apiData, String slug) {
    final updateData = <String, dynamic>{};

    // Store the slug for easy future updates
    updateData['slug'] = slug;

    // Store ONLY these root level fields: IPOstatus, peersComparison, financialLotsize, GMP
    if (apiData.containsKey('IPOstatus')) {
      updateData['IPOstatus'] = apiData['IPOstatus'];
    }
    if (apiData.containsKey('peersComparison')) {
      updateData['peersComparison'] = apiData['peersComparison'];
    }
    if (apiData.containsKey('GMP')) {
      updateData['GMP'] = apiData['GMP'];
    }
    if (apiData.containsKey('financialLotsize')) {
      updateData['financialLotsize'] = apiData['financialLotsize'];
    }

    // Note: lot_details_message generation removed - will be handled on frontend

    // Store document_links ONLY if the specific fields exist: {DRHPDraft, RHPDraft, AnchorInvestors}
    final documentLinks = <String, dynamic>{};
    if (apiData.containsKey('DRHPDraft')) {
      documentLinks['DRHPDraft'] = apiData['DRHPDraft'];
    }
    if (apiData.containsKey('RHPDraft')) {
      documentLinks['RHPDraft'] = apiData['RHPDraft'];
    }
    if (apiData.containsKey('AnchorInvestors')) {
      documentLinks['AnchorInvestors'] = apiData['AnchorInvestors'];
    }
    if (documentLinks.isNotEmpty) {
      updateData['document_links'] = documentLinks;
    }

    // Store registrar_details ONLY if the specific fields exist: {registerName, registerPhone, registerEmail, registerWebsite}
    final registrarDetails = <String, dynamic>{};
    if (apiData.containsKey('registerName')) {
      registrarDetails['registerName'] = apiData['registerName'];
    }
    if (apiData.containsKey('registerPhone')) {
      registrarDetails['registerPhone'] = apiData['registerPhone'];
    }
    if (apiData.containsKey('registerEmail')) {
      registrarDetails['registerEmail'] = apiData['registerEmail'];
    }
    if (apiData.containsKey('registerWebsite')) {
      registrarDetails['registerWebsite'] = apiData['registerWebsite'];
    }
    if (registrarDetails.isNotEmpty) {
      updateData['registrar_details'] = registrarDetails;
    }

    // Store company_details ONLY if the specific fields exist: {companyName, address, companyPhone, email, website}
    final companyDetails = <String, dynamic>{};
    if (apiData.containsKey('companyName')) {
      companyDetails['companyName'] = apiData['companyName'];
    }
    if (apiData.containsKey('address')) {
      companyDetails['address'] = apiData['address'];
    }
    if (apiData.containsKey('companyPhone')) {
      companyDetails['companyPhone'] = apiData['companyPhone'];
    }
    if (apiData.containsKey('email')) {
      companyDetails['email'] = apiData['email'];
    }
    if (apiData.containsKey('website')) {
      companyDetails['website'] = apiData['website'];
    }
    if (companyDetails.isNotEmpty) {
      updateData['company_details'] = companyDetails;
    }

    return updateData;
  }

  // Extract IPO Trend specific fields (gmp, key_performance_indicator, ipo_reservation, ipo_image)
  static Map<String, dynamic> _extractIpoTrendFields(
      Map<String, dynamic> apiData, String symbol) {
    final updateData = <String, dynamic>{};

    // Store the IPO Trend symbol for reference
    updateData['ipo_trend_symbol'] = symbol;

    // Extract data from nested structure: data.data
    final nestedData = apiData['data']?['data'] as Map<String, dynamic>?;

    if (nestedData != null) {
      // Store gmp
      if (nestedData.containsKey('gmp')) {
        updateData['gmp'] = nestedData['gmp'];
      }

      // Store key_performance_indicator
      if (nestedData.containsKey('key_performance_indicator')) {
        updateData['key_performance_indicator'] =
            nestedData['key_performance_indicator'];
      }

      // Store ipo_reservation
      if (nestedData.containsKey('ipo_reservation')) {
        updateData['ipo_reservation'] = nestedData['ipo_reservation'];
      }

      // Store ipo_image
      if (nestedData.containsKey('ipo_image')) {
        updateData['ipo_image'] = nestedData['ipo_image'];
      }
    }

    return updateData;
  }

  // Update existing IPO with IPO Trend specific data fields
  static Future<void> updateIpoWithTrendData(
      String docId, Map<String, dynamic> apiData, String symbol) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final updateData = _extractIpoTrendFields(apiData, symbol);
      updateData['_firebaseUpdatedAt'] = DateTime.now();

      // Use set with merge: true to merge data instead of overwriting
      await db.collection(iposCollectionName).doc(docId).set(
            updateData,
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Error updating IPO with trend data: $e');
    }
  }

  // Get slug for a specific IPO by ID
  static Future<String?> getSlugForIpo(String ipoId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot =
          await db.collection(iposCollectionName).doc(ipoId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?['slug']?.toString();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching slug for IPO: $e');
    }
  }

  // Get BSEScriptCode from stock_data for a specific IPO by ID
  static Future<String?> getBSEScriptCodeForIpo(String ipoId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot =
          await db.collection(iposCollectionName).doc(ipoId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?['stock_data']?['BSEScriptCode']?.toString();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching BSEScriptCode for IPO: $e');
    }
  }

  // Get image URL for a specific IPO by ID
  static Future<String?> getImageUrlForIpo(String ipoId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot =
          await db.collection(iposCollectionName).doc(ipoId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?['company_headers']?['company_logo']?.toString();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching image URL for IPO: $e');
    }
  }

  // Save image URL for a specific IPO by ID
  static Future<void> saveImageUrl(String ipoId, String imageUrl) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db.collection(iposCollectionName).doc(ipoId).set(
        {
          'company_headers': {
            'company_logo': imageUrl,
          },
          '_firebaseUpdatedAt': DateTime.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error saving image URL: $e');
    }
  }

  // Get expected premium for a specific IPO by ID
  static Future<String?> getExpectedPremiumForIpo(String ipoId) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot =
          await db.collection(iposCollectionName).doc(ipoId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        return data?['expected_premium']?.toString();
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching expected premium for IPO: $e');
    }
  }

  // Save expected premium for a specific IPO by ID
  static Future<void> saveExpectedPremium(
      String ipoId, String expectedPremium) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db.collection(iposCollectionName).doc(ipoId).set(
        {
          'expected_premium': expectedPremium,
          '_firebaseUpdatedAt': DateTime.now(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Error saving expected premium: $e');
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

  // Update company logo and expected premium for an IPO
  static Future<void> updateIpoCompanyInfo(
    String id, {
    String? expectedPremium,
    String? companyLogo,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final updateData = <String, dynamic>{
        '_firebaseUpdatedAt': DateTime.now(),
      };

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

      // Only update if there are fields to update
      if (updateData.length > 1) {
        // More than just the timestamp
        await db.collection(iposCollectionName).doc(id).update(updateData);
      }
    } catch (e) {
      throw Exception('Error updating IPO company info: $e');
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
        final querySnapshot = await db
            .collection(collectionName)
            .where(fieldName, isEqualTo: companyId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final category = data['category']?.toString();
          // Only return category if it's in the allowed list
          if (category != null && allowedCategories.contains(category)) {
            return category;
          }
        }
      }

      // If exact match fails, try partial matching within allowed categories only

      // Query only documents with allowed categories
      for (final allowedCategory in allowedCategories) {
        final categoryDocs = await db
            .collection(collectionName)
            .where('category', isEqualTo: allowedCategory)
            .limit(50)
            .get();

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

                return category;
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
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
        throw Exception(
            'Category not found in IPO analysis for company: $companyId');
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

  // Update all IPO analysis data using new comprehensive models
  static Future<void> updateAllIpoAnalysisData() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Fetch all categorized IPOs with complete data models
      final categorizedIpos = await ApiService.getCategorizedIposWithModels();

      // Clear existing data in ipo_analysis collection
      final existingDocs = await db.collection(collectionName).get();
      final batch = db.batch();

      // Delete existing documents
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add all new IPO analysis data with complete object data
      for (final category in categorizedIpos.entries) {
        for (final ipo in category.value) {
          final docRef = db.collection(collectionName).doc();
          final firestoreData = ipo.toFirestore();
          batch.set(docRef, firestoreData);
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error updating all IPO analysis data: $e');
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

  // Get all IPO analysis data from Firebase using new models
  static Future<Map<String, List<BaseIpoAnalysisModel>>>
      getAllIpoAnalysisData() async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      final Map<String, List<BaseIpoAnalysisModel>> categorizedIpos = {
        'draft_issues': <BaseIpoAnalysisModel>[],
        'upcoming_open': <BaseIpoAnalysisModel>[],
        'listing_soon': <BaseIpoAnalysisModel>[],
        'recently_listed': <BaseIpoAnalysisModel>[],
        'gain_loss_analysis': <BaseIpoAnalysisModel>[],
      };

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['category']?.toString();

        if (category != null && categorizedIpos.containsKey(category)) {
          try {
            final ipo = BaseIpoAnalysisModel.fromJson(data, category);
            categorizedIpos[category]!.add(ipo);
          } catch (e) {
            // Skip invalid documents
            continue;
          }
        }
      }

      return categorizedIpos;
    } catch (e) {
      throw Exception('Error fetching IPO analysis data: $e');
    }
  }

  // ==================== IPO MANAGEMENT COLLECTION METHODS ====================

  /// Add IPO to ipo_management collection with hierarchical structure
  /// Path: ipo_management/{ipoType}/{category}/{docId}
  /// ipoType: 'mainboard' or 'sme'
  /// category: 'live', 'upcoming', or 'listed'
  /// orderIndex: Position in the list to maintain API order
  static Future<String> addIpoToManagement({
    required Map<String, dynamic> ipoData,
    required String ipoType, // 'mainboard' or 'sme'
    required String category, // 'live', 'upcoming', or 'listed'
    int? orderIndex, // Position in the list
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate ipoType
      if (ipoType != 'mainboard' && ipoType != 'sme') {
        throw Exception('Invalid ipoType. Must be "mainboard" or "sme"');
      }

      // Validate category
      if (category != 'live' &&
          category != 'upcoming' &&
          category != 'listed') {
        throw Exception(
            'Invalid category. Must be "live", "upcoming", or "listed"');
      }

      // Add Firebase metadata and exclude fields managed separately
      final dataToStore = Map<String, dynamic>.from(ipoData);

      // Remove fields that are managed separately
      dataToStore.remove('slug');
      dataToStore.remove('financialLotsize');
      dataToStore.remove('document_links');
      dataToStore.remove('registrar_details');
      dataToStore.remove('company_details');
      dataToStore.remove('ObjectOfIssue');
      dataToStore.remove('promotersName');
      dataToStore.remove('important_dates');
      dataToStore.remove('quota');
      dataToStore.remove('_docId');

      dataToStore['_firebaseCreatedAt'] = DateTime.now();
      dataToStore['_firebaseUpdatedAt'] = DateTime.now();
      dataToStore['ipoType'] = ipoType;
      dataToStore['_orderIndex'] = orderIndex ?? 0;

      // Create document in hierarchical structure
      final docRef = await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .add(dataToStore);

      return docRef.id;
    } catch (e) {
      throw Exception('Error adding IPO to management: $e');
    }
  }

  /// Update IPO in ipo_management collection
  static Future<void> updateIpoInManagement({
    required String docId,
    required Map<String, dynamic> ipoData,
    required String ipoType,
    required String category,
    int? orderIndex,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate ipoType and category
      if (ipoType != 'mainboard' && ipoType != 'sme') {
        throw Exception('Invalid ipoType. Must be "mainboard" or "sme"');
      }
      if (category != 'live' &&
          category != 'upcoming' &&
          category != 'listed') {
        throw Exception(
            'Invalid category. Must be "live", "upcoming", or "listed"');
      }

      // Add update timestamp
      final dataToUpdate = Map<String, dynamic>.from(ipoData);
      dataToUpdate['_firebaseUpdatedAt'] = DateTime.now();
      if (orderIndex != null) {
        dataToUpdate['_orderIndex'] = orderIndex;
      }

      // Update document
      await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .doc(docId)
          .set(dataToUpdate, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating IPO in management: $e');
    }
  }

  /// Update IPO in ipo_management collection with IPO Dekho data
  static Future<void> updateIpoInManagementWithDekhoData({
    required int ipoId,
    required String ipoType,
    required String category,
    required Map<String, dynamic> apiData,
    required String slug,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate ipoType and category
      if (ipoType != 'mainboard' && ipoType != 'sme') {
        throw Exception('Invalid ipoType. Must be "mainboard" or "sme"');
      }
      if (category != 'live' &&
          category != 'upcoming' &&
          category != 'listed') {
        throw Exception(
            'Invalid category. Must be "live", "upcoming", or "listed"');
      }

      // Find the document with the matching IPO id
      final querySnapshot = await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .where('id', isEqualTo: ipoId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('IPO not found in management collection');
      }

      final docId = querySnapshot.docs.first.id;

      // Extract the specific fields from API data
      final updateData = _extractIpoDekhoFieldsForManagement(apiData, slug);
      updateData['_firebaseUpdatedAt'] = DateTime.now();

      // Update document with merge
      await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .doc(docId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error updating IPO in management with Dekho data: $e');
    }
  }

  /// Extract IPO Dekho fields for management collection
  static Map<String, dynamic> _extractIpoDekhoFieldsForManagement(
      Map<String, dynamic> apiData, String slug) {
    final updateData = <String, dynamic>{};

    try {
      // Store the slug
      updateData['slug'] = slug;

      // Store root level fields: financialLotsize (can be Map or List)
      if (apiData['financialLotsize'] != null) {
        // Store as-is without type casting
        updateData['financialLotsize'] = apiData['financialLotsize'];
      }

      // Store root level fields: ObjectOfIssue, faceValue, issueType, promotersName
      // These can be String or List, store as-is
      if (apiData['ObjectOfIssue'] != null) {
        updateData['ObjectOfIssue'] = apiData['ObjectOfIssue'];
      }
      if (apiData['faceValue'] != null) {
        updateData['faceValue'] = apiData['faceValue'];
      }
      if (apiData['issueType'] != null) {
        updateData['issueType'] = apiData['issueType'];
      }
      if (apiData['promotersName'] != null) {
        updateData['promotersName'] = apiData['promotersName'];
      }

      // Store document_links: {DRHPDraft, RHPDraft, AnchorInvestors}
      final documentLinks = <String, dynamic>{};
      if (apiData['DRHPDraft'] != null) {
        documentLinks['DRHPDraft'] = apiData['DRHPDraft'];
      }
      if (apiData['RHPDraft'] != null) {
        documentLinks['RHPDraft'] = apiData['RHPDraft'];
      }
      if (apiData['AnchorInvestors'] != null) {
        documentLinks['AnchorInvestors'] = apiData['AnchorInvestors'];
      }
      if (documentLinks.isNotEmpty) {
        updateData['document_links'] = documentLinks;
      }

      // Store important_dates: {IPOAllotmentDate, IPOCloseDate, IPODematTransfer, IPOListingDate, IPOOpenDate, IPORefundsInitiation}
      final importantDates = <String, dynamic>{};
      if (apiData['IPOAllotmentDate'] != null) {
        importantDates['IPOAllotmentDate'] = apiData['IPOAllotmentDate'];
      }
      if (apiData['IPOCloseDate'] != null) {
        importantDates['IPOCloseDate'] = apiData['IPOCloseDate'];
      }
      if (apiData['IPODematTransfer'] != null) {
        importantDates['IPODematTransfer'] = apiData['IPODematTransfer'];
      }
      if (apiData['IPOListingDate'] != null) {
        importantDates['IPOListingDate'] = apiData['IPOListingDate'];
      }
      if (apiData['IPOOpenDate'] != null) {
        importantDates['IPOOpenDate'] = apiData['IPOOpenDate'];
      }
      if (apiData['IPORefundsInitiation'] != null) {
        importantDates['IPORefundsInitiation'] =
            apiData['IPORefundsInitiation'];
      }
      if (importantDates.isNotEmpty) {
        updateData['important_dates'] = importantDates;
      }

      // Store quota: {nilQuota, qibQuota, retailQuota}
      // These can be String, Map, or List, store as-is
      if (apiData['nilQuota'] != null ||
          apiData['qibQuota'] != null ||
          apiData['retailQuota'] != null) {
        final quota = <String, dynamic>{};
        if (apiData['nilQuota'] != null) {
          quota['nilQuota'] = apiData['nilQuota'];
        }
        if (apiData['qibQuota'] != null) {
          quota['qibQuota'] = apiData['qibQuota'];
        }
        if (apiData['retailQuota'] != null) {
          quota['retailQuota'] = apiData['retailQuota'];
        }
        if (quota.isNotEmpty) {
          updateData['quota'] = quota;
        }
      }

      // Store registrar_details: {registerName, registerPhone, registerEmail, registerWebsite}
      final registrarDetails = <String, dynamic>{};
      if (apiData['registerName'] != null) {
        registrarDetails['registerName'] = apiData['registerName'];
      }
      if (apiData['registerPhone'] != null) {
        registrarDetails['registerPhone'] = apiData['registerPhone'];
      }
      if (apiData['registerEmail'] != null) {
        registrarDetails['registerEmail'] = apiData['registerEmail'];
      }
      if (apiData['registerWebsite'] != null) {
        registrarDetails['registerWebsite'] = apiData['registerWebsite'];
      }
      if (registrarDetails.isNotEmpty) {
        updateData['registrar_details'] = registrarDetails;
      }

      // Store company_details: {companyName, address, companyPhone, email, website}
      final companyDetails = <String, dynamic>{};
      if (apiData['companyName'] != null) {
        companyDetails['companyName'] = apiData['companyName'];
      }
      if (apiData['address'] != null) {
        companyDetails['address'] = apiData['address'];
      }
      if (apiData['companyPhone'] != null) {
        companyDetails['companyPhone'] = apiData['companyPhone'];
      }
      if (apiData['email'] != null) {
        companyDetails['email'] = apiData['email'];
      }
      if (apiData['website'] != null) {
        companyDetails['website'] = apiData['website'];
      }
      if (companyDetails.isNotEmpty) {
        updateData['company_details'] = companyDetails;
      }
    } catch (e) {
      // Silently handle error - return whatever data we could extract
    }

    return updateData;
  }

  /// Get all IPOs from a specific category in ipo_management
  /// Returns IPOs ordered by _orderIndex to maintain API order
  static Future<List<Map<String, dynamic>>> getIposFromManagement({
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .orderBy('_orderIndex', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_docId'] = doc.id; // Store Firebase doc ID separately
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching IPOs from management: $e');
    }
  }

  /// Delete IPO from ipo_management collection
  static Future<void> deleteIpoFromManagement({
    required String docId,
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting IPO from management: $e');
    }
  }

  /// Clear all IPOs from a specific category in ipo_management collection
  /// This is used when replacing all data with fresh API data
  static Future<void> clearAllIposFromManagement({
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Get all documents in the category
      final querySnapshot = await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .get();

      // Delete all documents using batch operation
      if (querySnapshot.docs.isNotEmpty) {
        final batch = db.batch();
        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      throw Exception('Error clearing IPOs from management: $e');
    }
  }

  /// Check if IPO exists in ipo_management by company ID
  static Future<Map<String, dynamic>?> findIpoInManagement({
    required int companyId,
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final querySnapshot = await db
          .collection(ipoManagementCollectionName)
          .doc(ipoType)
          .collection(category)
          .where('id', isEqualTo: companyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        data['docId'] = querySnapshot.docs.first.id;
        return data;
      }

      return null;
    } catch (e) {
      throw Exception('Error finding IPO in management: $e');
    }
  }

  // ==================== IPO Remaining Data Methods ====================

  /// Add or update IPO remaining data (IPO Dekho data) in Firebase
  /// Structure: ipo_remaining_data/{ipoType}/{ipoId}
  static Future<void> addOrUpdateIpoRemainingData({
    required int ipoId,
    required String companyName,
    required Map<String, dynamic> remainingData,
    required String ipoType, // 'mainboard' or 'sme'
    required String category, // 'live', 'upcoming', or 'listed'
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      // Use ipoId as document ID for easy lookup
      // Structure: ipo_remaining_data/{ipoType}/{ipoId}
      final docRef = db
          .collection(ipoRemainingDataCollectionName)
          .doc(ipoType)
          .collection('ipos')
          .doc(ipoId.toString());

      // Add metadata (category is not stored in the document)
      final dataToStore = {
        ...remainingData,
        'ipoId': ipoId,
        'companyName': companyName,
        'ipoType': ipoType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if document exists
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Update existing document (merge to preserve existing data)
        await docRef.update(dataToStore);
      } else {
        // Create new document
        dataToStore['createdAt'] = FieldValue.serverTimestamp();
        await docRef.set(dataToStore);
      }
    } catch (e) {
      throw Exception('Error adding/updating IPO remaining data: $e');
    }
  }

  /// Get IPO remaining data by IPO ID
  static Future<Map<String, dynamic>?> getIpoRemainingData({
    required int ipoId,
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      final docSnapshot = await db
          .collection(ipoRemainingDataCollectionName)
          .doc(ipoType)
          .collection('ipos')
          .doc(ipoId.toString())
          .get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      throw Exception('Error getting IPO remaining data: $e');
    }
  }

  /// Delete IPO remaining data
  static Future<void> deleteIpoRemainingData({
    required int ipoId,
    required String ipoType,
    required String category,
  }) async {
    final db = firestore;
    if (db == null) {
      throw Exception('Firebase not available');
    }

    try {
      await db
          .collection(ipoRemainingDataCollectionName)
          .doc(ipoType)
          .collection('ipos')
          .doc(ipoId.toString())
          .delete();
    } catch (e) {
      throw Exception('Error deleting IPO remaining data: $e');
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
