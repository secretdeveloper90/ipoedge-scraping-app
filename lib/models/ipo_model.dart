class IpoModel {
  final String? id;
  final String companyId;
  final String? companyName;
  final Map<String, dynamic>? additionalData;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Document links
  final String? drhpLink;
  final String? rhpLink;
  final String? anchorLink;
  // Expected premium
  final String? expectedPremium;
  // Company logo
  final String? companyLogo;

  IpoModel({
    this.id,
    required this.companyId,
    this.companyName,
    this.additionalData,
    this.createdAt,
    this.updatedAt,
    this.drhpLink,
    this.rhpLink,
    this.anchorLink,
    this.expectedPremium,
    this.companyLogo,
  });

  factory IpoModel.fromJson(Map<String, dynamic> json) {
    // Extract company headers if available (from company API)
    final companyHeaders = json['company_headers'] as Map<String, dynamic>?;

    return IpoModel(
      id: json['id']?.toString() ??
          json['ipo_id']?.toString() ??
          json['ipoID']?.toString() ??
          companyHeaders?['ipo_id']?.toString(),
      companyId: json['companyId']?.toString() ??
          json['company_id']?.toString() ??
          json['ipo_id']?.toString() ??
          json['ipoID']?.toString() ??
          json['slug']?.toString() ??
          json['company_slug_name']?.toString() ??
          companyHeaders?['ipo_id']?.toString() ??
          companyHeaders?['company_slug_name']?.toString() ??
          '',
      companyName: json['companyName']?.toString() ??
          json['company_name']?.toString() ??
          companyHeaders?['company_name']?.toString() ??
          companyHeaders?['company_short_name']?.toString(),
      additionalData: json['additionalData'] ?? json['additional_data'] ?? json,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      // Extract document links from API response
      drhpLink: json['drhpLink']?.toString() ??
          json['DRHPDraft']?.toString() ??
          json['document_links']?['drhp']?.toString(),
      rhpLink: json['rhpLink']?.toString() ??
          json['RHPDraft']?.toString() ??
          json['document_links']?['rhp']?.toString(),
      anchorLink: json['anchorLink']?.toString() ??
          json['AnchorInvestors']?.toString() ??
          json['document_links']?['anchor']?.toString(),
      expectedPremium:
          json['expectedPremium']?.toString() ?? json['GMP']?.toString(),
      companyLogo: json['file']?.toString(), // Extract company logo from API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'additionalData': additionalData,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'drhpLink': drhpLink,
      'rhpLink': rhpLink,
      'anchorLink': anchorLink,
      'expectedPremium': expectedPremium,
      'companyLogo': companyLogo,
    };
  }

  Map<String, dynamic> toFirestore() {
    // Store the complete original response, excluding only the specified fields
    Map<String, dynamic> firestoreData = {};

    if (additionalData != null) {
      try {
        // Use _sanitizeData to exclude the specified fields and handle complex data
        firestoreData = _sanitizeData(additionalData!);
      } catch (e) {
        // If serialization fails, store a simplified version
        firestoreData = {
          'error': 'Data too complex to serialize',
          'originalKeys': additionalData!.keys.toList(),
          'dataType': additionalData.runtimeType.toString(),
        };
      }
    }

    // Add Firebase metadata fields
    firestoreData['_firebaseCreatedAt'] = createdAt ?? DateTime.now();
    firestoreData['_firebaseUpdatedAt'] = DateTime.now();

    // Store specific fields from API response
    if (additionalData != null) {
      // Store IPOstatus, peersComparison, financialLotsize at root level
      if (additionalData!['IPOstatus'] != null) {
        firestoreData['IPOstatus'] = additionalData!['IPOstatus'];
      }
      if (additionalData!['peersComparison'] != null) {
        firestoreData['peersComparison'] = additionalData!['peersComparison'];
      }
      if (additionalData!['financialLotsize'] != null) {
        firestoreData['financialLotsize'] = additionalData!['financialLotsize'];

        // Generate and store lot details message
        final lotDetailsMessage = generateLotDetailsMessage(additionalData!);
        if (lotDetailsMessage.isNotEmpty) {
          firestoreData['lot_details_message'] = lotDetailsMessage;
        }
      }
    }

    // Store document_links as nested object
    final documentLinksData = <String, String?>{};
    if (drhpLink != null && drhpLink!.isNotEmpty) {
      documentLinksData['DRHPDraft'] = drhpLink;
    }
    if (rhpLink != null && rhpLink!.isNotEmpty) {
      documentLinksData['RHPDraft'] = rhpLink;
    }
    if (anchorLink != null && anchorLink!.isNotEmpty) {
      documentLinksData['AnchorInvestors'] = anchorLink;
    }

    if (documentLinksData.isNotEmpty) {
      firestoreData['document_links'] = documentLinksData;
    }

    // Store registrar_details as nested object
    if (additionalData != null) {
      final registrarDetails = <String, dynamic>{};
      if (additionalData!['registerName'] != null) {
        registrarDetails['registerName'] = additionalData!['registerName'];
      }
      if (additionalData!['registerPhone'] != null) {
        registrarDetails['registerPhone'] = additionalData!['registerPhone'];
      }
      if (additionalData!['registerEmail'] != null) {
        registrarDetails['registerEmail'] = additionalData!['registerEmail'];
      }
      if (additionalData!['registerWebsite'] != null) {
        registrarDetails['registerWebsite'] =
            additionalData!['registerWebsite'];
      }

      if (registrarDetails.isNotEmpty) {
        firestoreData['registrar_details'] = registrarDetails;
      }
    }

    // Store company_details as nested object
    if (additionalData != null) {
      final companyDetails = <String, dynamic>{};
      if (additionalData!['companyName'] != null) {
        companyDetails['companyName'] = additionalData!['companyName'];
      }
      if (additionalData!['address'] != null) {
        companyDetails['address'] = additionalData!['address'];
      }
      if (additionalData!['companyPhone'] != null) {
        companyDetails['companyPhone'] = additionalData!['companyPhone'];
      }
      if (additionalData!['email'] != null) {
        companyDetails['email'] = additionalData!['email'];
      }
      if (additionalData!['website'] != null) {
        companyDetails['website'] = additionalData!['website'];
      }

      if (companyDetails.isNotEmpty) {
        firestoreData['company_details'] = companyDetails;
      }
    }

    // Add expected premium at root level
    if (expectedPremium != null && expectedPremium!.isNotEmpty) {
      firestoreData['expectedPremium'] = expectedPremium;
    }

    // Add company logo to company_headers
    if (companyLogo != null && companyLogo!.isNotEmpty) {
      // Ensure company_headers exists
      if (firestoreData['company_headers'] == null) {
        firestoreData['company_headers'] = <String, dynamic>{};
      }
      firestoreData['company_headers']['company_logo'] = companyLogo;
    }

    return firestoreData;
  }

  // Helper method to safely serialize complex data structures
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data,
      {int depth = 0}) {
    const maxDepth = 10; // Prevent infinite recursion
    const maxStringLength = 10000; // Limit string length

    // Fields to exclude from Firebase storage
    const excludedFields = {
      'peerData',
      'metadata',
      'insight',
      'research_reports',
      'post_page_link',
      'post_analysis',
      'company_events',
      'tableData',
      'ipo_rhp_document',
      'ipo_drhp_document',
      'rhp_external_document',
      'stock_page_url',
      'subscription_modified',
      'company_logo'
    };

    if (depth > maxDepth) {
      return {'_truncated': 'Max depth reached'};
    }

    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;

      // Skip excluded fields
      if (excludedFields.contains(key)) {
        continue;
      }

      try {
        final value = entry.value;

        if (value == null) {
          sanitized[key] = null;
        } else if (value is String) {
          sanitized[key] = value.length > maxStringLength
              ? '${value.substring(0, maxStringLength)}...[truncated]'
              : value;
        } else if (value is num || value is bool) {
          sanitized[key] = value;
        } else if (value is List) {
          sanitized[key] = _sanitizeList(value, depth + 1);
        } else if (value is Map<String, dynamic>) {
          sanitized[key] = _sanitizeData(value, depth: depth + 1);
        } else if (value is Map) {
          // Convert other map types to Map<String, dynamic>
          final convertedMap = <String, dynamic>{};
          for (final mapEntry in value.entries) {
            convertedMap[mapEntry.key.toString()] = mapEntry.value;
          }
          sanitized[key] = _sanitizeData(convertedMap, depth: depth + 1);
        } else {
          // For other types, convert to string
          sanitized[key] = value.toString();
        }
      } catch (e) {
        sanitized[key] = 'Error serializing: ${e.toString()}';
      }
    }

    return sanitized;
  }

  List<dynamic> _sanitizeList(List<dynamic> list, int depth) {
    const maxDepth = 10;
    const maxListLength = 100;

    if (depth > maxDepth) {
      return ['_truncated: Max depth reached'];
    }

    final sanitized = <dynamic>[];
    final itemsToProcess =
        list.length > maxListLength ? maxListLength : list.length;

    for (int i = 0; i < itemsToProcess; i++) {
      final item = list[i];

      if (item == null) {
        sanitized.add(null);
      } else if (item is String || item is num || item is bool) {
        sanitized.add(item);
      } else if (item is Map<String, dynamic>) {
        // Apply the same filtering logic to maps within lists
        sanitized.add(_sanitizeData(item, depth: depth + 1));
      } else if (item is Map) {
        final convertedMap = <String, dynamic>{};
        for (final entry in item.entries) {
          convertedMap[entry.key.toString()] = entry.value;
        }
        // Apply the same filtering logic to converted maps within lists
        sanitized.add(_sanitizeData(convertedMap, depth: depth + 1));
      } else if (item is List) {
        sanitized.add(_sanitizeList(item, depth + 1));
      } else {
        sanitized.add(item.toString());
      }
    }

    if (list.length > maxListLength) {
      sanitized.add('_truncated: ${list.length - maxListLength} more items');
    }

    return sanitized;
  }

  factory IpoModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    // Create a copy of the data without Firebase metadata fields
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('_firebaseCreatedAt');
    cleanData.remove('_firebaseUpdatedAt');

    // Use the existing fromJson method to parse the data
    final ipo = IpoModel.fromJson(cleanData);

    // Return with the document ID and Firebase timestamps
    return ipo.copyWith(
      id: documentId,
      createdAt: data['_firebaseCreatedAt']?.toDate(),
      updatedAt: data['_firebaseUpdatedAt']?.toDate(),
    );
  }

  IpoModel copyWith({
    String? id,
    String? companyId,
    String? companyName,
    Map<String, dynamic>? additionalData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? drhpLink,
    String? rhpLink,
    String? anchorLink,
    String? expectedPremium,
    String? companyLogo,
  }) {
    return IpoModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      drhpLink: drhpLink ?? this.drhpLink,
      rhpLink: rhpLink ?? this.rhpLink,
      anchorLink: anchorLink ?? this.anchorLink,
      expectedPremium: expectedPremium ?? this.expectedPremium,
      companyLogo: companyLogo ?? this.companyLogo,
    );
  }

  // Get category from additionalData
  String? get category {
    return additionalData?['category']?.toString();
  }

  // Get category-specific display name
  String get displayName {
    return (companyName?.isNotEmpty == true)
        ? companyName!
        : (companyId.isNotEmpty ? companyId : 'Unknown Company');
  }

  // Document links validation methods
  bool get hasAnyDocumentLink =>
      (drhpLink?.isNotEmpty ?? false) ||
      (rhpLink?.isNotEmpty ?? false) ||
      (anchorLink?.isNotEmpty ?? false);

  bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return true; // Empty is valid
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool get hasValidDocumentLinks =>
      isValidUrl(drhpLink) && isValidUrl(rhpLink) && isValidUrl(anchorLink);

  // Generate lot details message from financialLotsize data
  String generateLotDetailsMessage(Map<String, dynamic> data) {
    try {
      final companyName = data['companyName']?.toString() ?? 'IPO';
      final lotSize = data['lotSize']?.toString();
      final financialLotsize = data['financialLotsize'] as List<dynamic>?;

      if (financialLotsize == null ||
          financialLotsize.isEmpty ||
          lotSize == null) {
        return '';
      }

      // Find retail min, retail max, and HNI data
      Map<String, dynamic>? retailMin;
      Map<String, dynamic>? retailMax;
      Map<String, dynamic>? hniMin;

      for (final lot in financialLotsize) {
        if (lot is Map<String, dynamic>) {
          final application =
              lot['application']?.toString().toLowerCase() ?? '';
          if (application.contains('retail') && application.contains('min')) {
            retailMin = lot;
          } else if (application.contains('retail') &&
              application.contains('max')) {
            retailMax = lot;
          } else if ((application.contains('hni') ||
                  application.contains('b-hni')) &&
              application.contains('min')) {
            hniMin = lot;
          }
        }
      }

      if (retailMin == null || retailMax == null) {
        return '';
      }

      // Format amounts with Indian currency formatting
      final minAmount = _formatIndianCurrency(retailMin['amount']);
      final maxAmount = _formatIndianCurrency(retailMax['amount']);
      final hniAmount =
          hniMin != null ? _formatIndianCurrency(hniMin['amount']) : '';

      // Build the message
      final buffer = StringBuffer();
      buffer.write(
          'The $companyName minimum market lot is $lotSize shares with $minAmount application amount. ');
      buffer.write(
          'The retail investors can apply up-to ${retailMax['lots']} lots with ${retailMax['shares']} shares or $maxAmount amount.');

      if (hniMin != null) {
        buffer.write(
            ' The HNIs can apply up-to ${hniMin['lots']} lots with ${hniMin['shares']} shares or $hniAmount amount.');
      }

      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  // Helper method to format currency in Indian format
  String _formatIndianCurrency(dynamic amount) {
    if (amount == null) return '';

    try {
      final numAmount =
          amount is num ? amount : num.tryParse(amount.toString());
      if (numAmount == null) return amount.toString();

      // Convert to string and add commas in Indian format
      final amountStr = numAmount.toStringAsFixed(0);
      final reversed = amountStr.split('').reversed.join();
      final formatted = StringBuffer();

      for (int i = 0; i < reversed.length; i++) {
        if (i == 3) {
          formatted.write(',');
        } else if (i > 3 && (i - 3) % 2 == 0) {
          formatted.write(',');
        }
        formatted.write(reversed[i]);
      }

      return '₹${formatted.toString().split('').reversed.join()}';
    } catch (e) {
      return amount.toString();
    }
  }
}
