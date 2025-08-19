class IpoModel {
  final String? id;
  final String companyId;
  final String? companyName;
  final Map<String, dynamic>? additionalData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IpoModel({
    this.id,
    required this.companyId,
    this.companyName,
    this.additionalData,
    this.createdAt,
    this.updatedAt,
  });

  factory IpoModel.fromJson(Map<String, dynamic> json) {
    // Extract company headers if available (from company API)
    final companyHeaders = json['company_headers'] as Map<String, dynamic>?;

    return IpoModel(
      id: json['id']?.toString() ??
          json['ipo_id']?.toString() ??
          companyHeaders?['ipo_id']?.toString(),
      companyId: json['companyId']?.toString() ??
          json['company_id']?.toString() ??
          json['ipo_id']?.toString() ??
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

    // Add essential fields for querying (if not already present)
    firestoreData['companyId'] = companyId;
    if (companyName != null) {
      firestoreData['companyName'] = companyName;
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
  }) {
    return IpoModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get category from additionalData
  String? get category {
    return additionalData?['category']?.toString();
  }

  // Get category-specific display name
  String get displayName {
    return companyName ??
        (companyId.isNotEmpty ? companyId : 'Unknown Company');
  }
}
