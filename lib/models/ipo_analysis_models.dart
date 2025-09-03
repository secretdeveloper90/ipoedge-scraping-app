// IPO Analysis Models for different categories
// Based on the API response structure from /api/ipos/listing-details

/// Base class for all IPO analysis models
abstract class BaseIpoAnalysisModel {
  final String companyName;
  final int ipoId;
  final String companySlugName;
  final String category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BaseIpoAnalysisModel({
    required this.companyName,
    required this.ipoId,
    required this.companySlugName,
    required this.category,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore();

  static BaseIpoAnalysisModel fromJson(
      Map<String, dynamic> json, String category) {
    switch (category) {
      case 'upcoming_open':
        return UpcomingOpenIpo.fromJson(json);
      case 'gain_loss_analysis':
        return GainLossAnalysisIpo.fromJson(json);
      case 'recently_listed':
        return RecentlyListedIpo.fromJson(json);
      case 'listing_soon':
        return ListingSoonIpo.fromJson(json);
      case 'draft_issues':
        return DraftIssuesIpo.fromJson(json);
      default:
        throw Exception('Unknown category: $category');
    }
  }
}

/// Model for upcoming_open category
class UpcomingOpenIpo extends BaseIpoAnalysisModel {
  final String bidStartDate;
  final String bidEndDate;
  final int strengthCount;
  final int riskCount;
  final double priceRangeMin;
  final double priceRangeMax;
  final String? subscriptionModified;
  final double subscriptionValue;
  final String subscriptionText;
  final String subscriptionColor;
  final List<SubscriptionDataKey> subscriptionDataKeys;
  final double qib;
  final double hni;
  final double retail;
  final int lotSize;
  final String? ipoDrhpDocument;
  final String? rhpExternalDocument;
  final bool isOpenNow;
  final bool isSme;
  final String exchangeFlags;
  final double issueSize;
  final double mcapQ;
  final double applicationAmountMin;
  final RetailData retailData;

  UpcomingOpenIpo({
    required super.companyName,
    required super.ipoId,
    required super.companySlugName,
    required this.bidStartDate,
    required this.bidEndDate,
    required this.strengthCount,
    required this.riskCount,
    required this.priceRangeMin,
    required this.priceRangeMax,
    this.subscriptionModified,
    required this.subscriptionValue,
    required this.subscriptionText,
    required this.subscriptionColor,
    required this.subscriptionDataKeys,
    required this.qib,
    required this.hni,
    required this.retail,
    required this.lotSize,
    this.ipoDrhpDocument,
    this.rhpExternalDocument,
    required this.isOpenNow,
    required this.isSme,
    required this.exchangeFlags,
    required this.issueSize,
    required this.mcapQ,
    required this.applicationAmountMin,
    required this.retailData,
    super.createdAt,
    super.updatedAt,
  }) : super(category: 'upcoming_open');

  factory UpcomingOpenIpo.fromJson(Map<String, dynamic> json) {
    return UpcomingOpenIpo(
      companyName: json['company_name']?.toString() ?? '',
      ipoId: json['ipo_id'] ?? 0,
      companySlugName: json['company_slug_name']?.toString() ?? '',
      bidStartDate: json['bid_start_date']?.toString() ?? '',
      bidEndDate: json['bid_end_date']?.toString() ?? '',
      strengthCount: json['strength_count'] ?? 0,
      riskCount: json['risk_count'] ?? 0,
      priceRangeMin: (json['price_range_min'] ?? 0).toDouble(),
      priceRangeMax: (json['price_range_max'] ?? 0).toDouble(),
      subscriptionModified: json['subscription_modified']?.toString(),
      subscriptionValue: (json['subscription_value'] ?? 0).toDouble(),
      subscriptionText: json['subscription_text']?.toString() ?? '',
      subscriptionColor: json['subscription_color']?.toString() ?? '',
      subscriptionDataKeys: (json['subscription_data_keys'] as List<dynamic>?)
              ?.map((e) => SubscriptionDataKey.fromJson(e))
              .toList() ??
          [],
      qib: (json['qib'] ?? 0).toDouble(),
      hni: (json['hni'] ?? 0).toDouble(),
      retail: (json['retail'] ?? 0).toDouble(),
      lotSize: json['lot_size'] ?? 0,
      ipoDrhpDocument: json['ipo_drhp_document']?.toString(),
      rhpExternalDocument: json['rhp_external_document']?.toString(),
      isOpenNow: json['is_open_now'] ?? false,
      isSme: json['is_sme'] ?? false,
      exchangeFlags: json['exchange_flags']?.toString() ?? '',
      issueSize: (json['issue_size'] ?? 0).toDouble(),
      mcapQ: (json['mcap_q'] ?? 0).toDouble(),
      applicationAmountMin: (json['application_amount_min'] ?? 0).toDouble(),
      retailData: RetailData.fromJson(json['retail_data'] ?? {}),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'company_name': companyName,
      'ipo_id': ipoId,
      'company_slug_name': companySlugName,
      'category': category,
      'bid_start_date': bidStartDate,
      'bid_end_date': bidEndDate,
      'strength_count': strengthCount,
      'risk_count': riskCount,
      'price_range_min': priceRangeMin,
      'price_range_max': priceRangeMax,
      'subscription_modified': subscriptionModified,
      'subscription_value': subscriptionValue,
      'subscription_text': subscriptionText,
      'subscription_color': subscriptionColor,
      'subscription_data_keys':
          subscriptionDataKeys.map((e) => e.toJson()).toList(),
      'qib': qib,
      'hni': hni,
      'retail': retail,
      'lot_size': lotSize,
      'ipo_drhp_document': ipoDrhpDocument,
      'rhp_external_document': rhpExternalDocument,
      'is_open_now': isOpenNow,
      'is_sme': isSme,
      'exchange_flags': exchangeFlags,
      'issue_size': issueSize,
      'mcap_q': mcapQ,
      'application_amount_min': applicationAmountMin,
      'retail_data': retailData.toJson(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

/// Model for gain_loss_analysis category
class GainLossAnalysisIpo extends BaseIpoAnalysisModel {
  final double listingGainP;
  final double currentGainP;
  final double issueSize;
  final double totalSubscription;

  GainLossAnalysisIpo({
    required super.companyName,
    required super.ipoId,
    required super.companySlugName,
    required this.listingGainP,
    required this.currentGainP,
    required this.issueSize,
    required this.totalSubscription,
    super.createdAt,
    super.updatedAt,
  }) : super(category: 'gain_loss_analysis');

  factory GainLossAnalysisIpo.fromJson(Map<String, dynamic> json) {
    return GainLossAnalysisIpo(
      companyName: json['company_name']?.toString() ?? '',
      ipoId: json['ipo_id'] ?? 0,
      companySlugName: json['company_slug_name']?.toString() ?? '',
      listingGainP: (json['listing_gainP'] ?? 0).toDouble(),
      currentGainP: (json['current_gainP'] ?? 0).toDouble(),
      issueSize: (json['issue_size'] ?? 0).toDouble(),
      totalSubscription: (json['total_subscription'] ?? 0).toDouble(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'company_name': companyName,
      'ipo_id': ipoId,
      'company_slug_name': companySlugName,
      'category': category,
      'listing_gainP': listingGainP,
      'current_gainP': currentGainP,
      'issue_size': issueSize,
      'total_subscription': totalSubscription,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

/// Supporting models
class SubscriptionDataKey {
  final String name;
  final String accessor;

  SubscriptionDataKey({
    required this.name,
    required this.accessor,
  });

  factory SubscriptionDataKey.fromJson(Map<String, dynamic> json) {
    return SubscriptionDataKey(
      name: json['name']?.toString() ?? '',
      accessor: json['accessor']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'accessor': accessor,
    };
  }
}

/// Model for recently_listed category
class RecentlyListedIpo extends BaseIpoAnalysisModel {
  final String? stockCode;
  final String? isin;
  final String listingDate;
  final double issueSize;
  final double issuePrice;
  final double qib;
  final double hni;
  final double retail;
  final double totalSubscription;
  final double listingOpenPrice;
  final double? listingClosePrice;
  final double listingGainP;
  final double currentPrice;
  final double currentGainP;
  final bool isSme;
  final String exchangeFlags;
  final double mcapQ;

  RecentlyListedIpo({
    required super.companyName,
    required super.ipoId,
    required super.companySlugName,
    this.stockCode,
    this.isin,
    required this.listingDate,
    required this.issueSize,
    required this.issuePrice,
    required this.qib,
    required this.hni,
    required this.retail,
    required this.totalSubscription,
    required this.listingOpenPrice,
    this.listingClosePrice,
    required this.listingGainP,
    required this.currentPrice,
    required this.currentGainP,
    required this.isSme,
    required this.exchangeFlags,
    required this.mcapQ,
    super.createdAt,
    super.updatedAt,
  }) : super(category: 'recently_listed');

  factory RecentlyListedIpo.fromJson(Map<String, dynamic> json) {
    return RecentlyListedIpo(
      companyName: json['company_name']?.toString() ?? '',
      ipoId: json['ipo_id'] ?? 0,
      companySlugName: json['company_slug_name']?.toString() ?? '',
      stockCode: json['stock_code']?.toString(),
      isin: json['isin']?.toString(),
      listingDate: json['listing_date']?.toString() ?? '',
      issueSize: (json['issue_size'] ?? 0).toDouble(),
      issuePrice: (json['issue_price'] ?? 0).toDouble(),
      qib: (json['qib'] ?? 0).toDouble(),
      hni: (json['hni'] ?? 0).toDouble(),
      retail: (json['retail'] ?? 0).toDouble(),
      totalSubscription: (json['total_subscription'] ?? 0).toDouble(),
      listingOpenPrice: (json['listing_open_price'] ?? 0).toDouble(),
      listingClosePrice: json['listing_close_price'] != null
          ? (json['listing_close_price']).toDouble()
          : null,
      listingGainP: (json['listing_gainP'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      currentGainP: (json['current_gainP'] ?? 0).toDouble(),
      isSme: json['is_sme'] ?? false,
      exchangeFlags: json['exchange_flags']?.toString() ?? '',
      mcapQ: (json['mcap_q'] ?? 0).toDouble(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'company_name': companyName,
      'ipo_id': ipoId,
      'company_slug_name': companySlugName,
      'category': category,
      'stock_code': stockCode,
      'isin': isin,
      'listing_date': listingDate,
      'issue_size': issueSize,
      'issue_price': issuePrice,
      'qib': qib,
      'hni': hni,
      'retail': retail,
      'total_subscription': totalSubscription,
      'listing_open_price': listingOpenPrice,
      'listing_close_price': listingClosePrice,
      'listing_gainP': listingGainP,
      'current_price': currentPrice,
      'current_gainP': currentGainP,
      'is_sme': isSme,
      'exchange_flags': exchangeFlags,
      'mcap_q': mcapQ,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

/// Model for listing_soon category
class ListingSoonIpo extends BaseIpoAnalysisModel {
  final double issueSize;
  final double issuePrice;
  final double qib;
  final double hni;
  final double retail;
  final double totalSubscription;
  final String openDate;
  final String closeDate;
  final String allotmentDate;
  final String refundDate;
  final String dematCreditDate;
  final String listingDate;
  final bool isSme;
  final String exchangeFlags;
  final double mcapQ;
  final String? allotmentStatus;
  final double applicationAmountMin;

  ListingSoonIpo({
    required super.companyName,
    required super.ipoId,
    required super.companySlugName,
    required this.issueSize,
    required this.issuePrice,
    required this.qib,
    required this.hni,
    required this.retail,
    required this.totalSubscription,
    required this.openDate,
    required this.closeDate,
    required this.allotmentDate,
    required this.refundDate,
    required this.dematCreditDate,
    required this.listingDate,
    required this.isSme,
    required this.exchangeFlags,
    required this.mcapQ,
    this.allotmentStatus,
    required this.applicationAmountMin,
    super.createdAt,
    super.updatedAt,
  }) : super(category: 'listing_soon');

  factory ListingSoonIpo.fromJson(Map<String, dynamic> json) {
    return ListingSoonIpo(
      companyName: json['company_name']?.toString() ?? '',
      ipoId: json['ipo_id'] ?? 0,
      companySlugName: json['company_slug_name']?.toString() ?? '',
      issueSize: (json['issue_size'] ?? 0).toDouble(),
      issuePrice: (json['issue_price'] ?? 0).toDouble(),
      qib: (json['qib'] ?? 0).toDouble(),
      hni: (json['hni'] ?? 0).toDouble(),
      retail: (json['retail'] ?? 0).toDouble(),
      totalSubscription: (json['total_subscription'] ?? 0).toDouble(),
      openDate: json['open_date']?.toString() ?? '',
      closeDate: json['close_date']?.toString() ?? '',
      allotmentDate: json['allotment_date']?.toString() ?? '',
      refundDate: json['refund_date']?.toString() ?? '',
      dematCreditDate: json['demat_credit_date']?.toString() ?? '',
      listingDate: json['listing_date']?.toString() ?? '',
      isSme: json['is_sme'] ?? false,
      exchangeFlags: json['exchange_flags']?.toString() ?? '',
      mcapQ: (json['mcap_q'] ?? 0).toDouble(),
      allotmentStatus: json['allotment_status']?.toString(),
      applicationAmountMin: (json['application_amount_min'] ?? 0).toDouble(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'company_name': companyName,
      'ipo_id': ipoId,
      'company_slug_name': companySlugName,
      'category': category,
      'issue_size': issueSize,
      'issue_price': issuePrice,
      'qib': qib,
      'hni': hni,
      'retail': retail,
      'total_subscription': totalSubscription,
      'open_date': openDate,
      'close_date': closeDate,
      'allotment_date': allotmentDate,
      'refund_date': refundDate,
      'demat_credit_date': dematCreditDate,
      'listing_date': listingDate,
      'is_sme': isSme,
      'exchange_flags': exchangeFlags,
      'mcap_q': mcapQ,
      'allotment_status': allotmentStatus,
      'application_amount_min': applicationAmountMin,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

/// Model for draft_issues category
class DraftIssuesIpo extends BaseIpoAnalysisModel {
  final double? preIpoPlacementInCr;
  final String? bidOpenDate;
  final String? bidCloseDate;
  final double issueSize;
  final double? priceRangeMin;
  final double? priceRangeMax;
  final String drhpFilingDate;
  final String? ipoDrhpDocument;
  final String? rhpExternalDocument;
  final String? companyLogo;

  DraftIssuesIpo({
    required super.companyName,
    required super.ipoId,
    required super.companySlugName,
    this.preIpoPlacementInCr,
    this.bidOpenDate,
    this.bidCloseDate,
    required this.issueSize,
    this.priceRangeMin,
    this.priceRangeMax,
    required this.drhpFilingDate,
    this.ipoDrhpDocument,
    this.rhpExternalDocument,
    this.companyLogo,
    super.createdAt,
    super.updatedAt,
  }) : super(category: 'draft_issues');

  factory DraftIssuesIpo.fromJson(Map<String, dynamic> json) {
    return DraftIssuesIpo(
      companyName: json['company_name']?.toString() ?? '',
      ipoId: json['ipo_id'] ?? 0,
      companySlugName: json['company_slug_name']?.toString() ?? '',
      preIpoPlacementInCr: json['pre_ipo_placement_in_cr'] != null
          ? (json['pre_ipo_placement_in_cr']).toDouble()
          : null,
      bidOpenDate: json['bid_open_date']?.toString(),
      bidCloseDate: json['bid_close_date']?.toString(),
      issueSize: (json['issue_size'] ?? 0).toDouble(),
      priceRangeMin: json['price_range_min'] != null
          ? (json['price_range_min']).toDouble()
          : null,
      priceRangeMax: json['price_range_max'] != null
          ? (json['price_range_max']).toDouble()
          : null,
      drhpFilingDate: json['drhp_filing_date']?.toString() ?? '',
      ipoDrhpDocument: json['ipo_drhp_document']?.toString(),
      rhpExternalDocument: json['rhp_external_document']?.toString(),
      companyLogo: json['company_logo']?.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'company_name': companyName,
      'ipo_id': ipoId,
      'company_slug_name': companySlugName,
      'category': category,
      'pre_ipo_placement_in_cr': preIpoPlacementInCr,
      'bid_open_date': bidOpenDate,
      'bid_close_date': bidCloseDate,
      'issue_size': issueSize,
      'price_range_min': priceRangeMin,
      'price_range_max': priceRangeMax,
      'drhp_filing_date': drhpFilingDate,
      'ipo_drhp_document': ipoDrhpDocument,
      'rhp_external_document': rhpExternalDocument,
      'company_logo': companyLogo,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}

class RetailData {
  final int applicationLotSizeMin;
  final int applicationLotSizeMax;
  final int applicationShareSizeMin;
  final int applicationShareSizeMax;

  RetailData({
    required this.applicationLotSizeMin,
    required this.applicationLotSizeMax,
    required this.applicationShareSizeMin,
    required this.applicationShareSizeMax,
  });

  factory RetailData.fromJson(Map<String, dynamic> json) {
    return RetailData(
      applicationLotSizeMin: json['application_lot_size_min'] ?? 0,
      applicationLotSizeMax: json['application_lot_size_max'] ?? 0,
      applicationShareSizeMin: json['application_share_size_min'] ?? 0,
      applicationShareSizeMax: json['application_share_size_max'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'application_lot_size_min': applicationLotSizeMin,
      'application_lot_size_max': applicationLotSizeMax,
      'application_share_size_min': applicationShareSizeMin,
      'application_share_size_max': applicationShareSizeMax,
    };
  }
}
