class NewIpoModel {
  final int? id; // Company ID from API
  final String? docId; // Firebase document ID
  final String? companyName;
  final String? symbol;
  final String? securityType;
  final String? startDate;
  final String? endDate;
  final String? allotmentDate;
  final String? listingDate;
  final String? listingAtGroup;
  final String? faceValue;
  final String? priceRange;
  final String? leadManagers;
  final int? issueSize;
  final String? freshIssueSize;
  final int? freshIssueValue;
  final int? offerOfSale;
  final String? offerOfSaleValue;
  final String? issueAmount;
  final String? issueType;
  final int? bidLot;
  final int? ipoMaxValue;
  final int? ipoMinValue;
  final int? maxInvestment;
  final int? minInvestment;
  final int? subscription;
  final String? aboutTheCompany;
  final String? gmp;
  final String? status;
  final String? ipoImage;
  final String? recommendation;
  final String? updatedAt;
  final String? newSymbol;
  final IpoStatus? ipoStatus;

  // Additional fields
  final bool? isReview;
  final int? preIssueShareHolding;
  final int? postIssueShareHolding;
  final String? companyPromoter;
  final String? issueObjectives;
  final String? nii;
  final String? employee;
  final String? retail;
  final String? gibs;
  final int? sHniLotSize;
  final int? bHniLotSize;
  final String? sHniSubscription;
  final String? bHniSubscription;
  final String? retailPortion;
  final String? companyStrenght;
  final String? companyWeakness;
  final String? listedPrice;
  final bool? allotment;
  final bool? isFirstTimeUpdate;
  final bool? buySellNotification;
  final String? buyPrice;
  final String? sellPrice;
  final bool? isActive;
  final String? issuePrice;
  final String? currentPrice;
  final String? gainOrLose;
  final String? scripCode;
  final String? listingDayGain;
  final String? listingDayClose;
  final String? reason;
  final bool? isHold;
  final String? allotmentDateTime;
  final String? peerComparisonSource;
  final String? sector;
  final String? industry;
  final String? basicIndustry;
  final String? macroEconomicSector;
  final int? spreadxIpoId;
  final String? anchorInvestorBidDate;
  final String? anchorLockinDate50;
  final String? anchorLockinDateRemaining;
  final String? anchorInvestorAmount;
  final String? anchorInvestorFileUrl;
  final bool? isBuySellEnable;
  final bool? isSocialAccountEnable;
  final bool? isandroidsocial;
  final bool? isAvailableForApply;

  // Complex objects
  final Map<String, dynamic>? companyFinancialData;
  final List<dynamic>? keyPerformanceIndicator;
  final List<dynamic>? ipoReservation;
  final Map<String, dynamic>? appplicationWiseBreakup;
  final List<dynamic>? subscriptionDemand;
  final List<dynamic>? interestCostPerShare;
  final List<dynamic>? ipoSubscriptionDetail;
  final List<dynamic>? subscriptionHistory;
  final List<dynamic>? valuation;
  final List<dynamic>? financialPerformance;
  final List<dynamic>? categories;
  final List<dynamic>? merchantBankerData;

  // Offered fields
  final int? qibsOffered;
  final int? hnisOffered;
  final int? hnisTenPlusOffered;
  final int? hnisTwoPlusOffered;
  final int? retailOffered;
  final int? anchorOffered;
  final int? shareholderOffered;
  final int? marketMakerOffered;
  final int? employeesOffered;
  final int? otherInvestorsOffered;
  final int? institutionalInvestorsOffered;

  // IPO Dekho specific fields
  final String? slug;
  final dynamic financialLotsize; // Can be Map, List, or String
  final dynamic documentLinks; // Can be Map or List
  final dynamic registrarDetails; // Can be Map or List
  final dynamic companyDetails; // Can be Map or List
  final dynamic objectOfIssue; // Can be String or List
  final dynamic promotersName; // Can be String or List
  final dynamic importantDates; // Can be Map or List
  final dynamic quota; // Can be Map, List, or String

  NewIpoModel({
    this.id,
    this.docId,
    this.companyName,
    this.symbol,
    this.securityType,
    this.startDate,
    this.endDate,
    this.allotmentDate,
    this.listingDate,
    this.listingAtGroup,
    this.faceValue,
    this.priceRange,
    this.leadManagers,
    this.issueSize,
    this.freshIssueSize,
    this.freshIssueValue,
    this.offerOfSale,
    this.offerOfSaleValue,
    this.issueAmount,
    this.issueType,
    this.bidLot,
    this.ipoMaxValue,
    this.ipoMinValue,
    this.maxInvestment,
    this.minInvestment,
    this.subscription,
    this.aboutTheCompany,
    this.gmp,
    this.status,
    this.ipoImage,
    this.recommendation,
    this.updatedAt,
    this.newSymbol,
    this.ipoStatus,
    this.isReview,
    this.preIssueShareHolding,
    this.postIssueShareHolding,
    this.companyPromoter,
    this.issueObjectives,
    this.nii,
    this.employee,
    this.retail,
    this.gibs,
    this.sHniLotSize,
    this.bHniLotSize,
    this.sHniSubscription,
    this.bHniSubscription,
    this.retailPortion,
    this.companyStrenght,
    this.companyWeakness,
    this.listedPrice,
    this.allotment,
    this.isFirstTimeUpdate,
    this.buySellNotification,
    this.buyPrice,
    this.sellPrice,
    this.isActive,
    this.issuePrice,
    this.currentPrice,
    this.gainOrLose,
    this.scripCode,
    this.listingDayGain,
    this.listingDayClose,
    this.reason,
    this.isHold,
    this.allotmentDateTime,
    this.peerComparisonSource,
    this.sector,
    this.industry,
    this.basicIndustry,
    this.macroEconomicSector,
    this.spreadxIpoId,
    this.anchorInvestorBidDate,
    this.anchorLockinDate50,
    this.anchorLockinDateRemaining,
    this.anchorInvestorAmount,
    this.anchorInvestorFileUrl,
    this.isBuySellEnable,
    this.isSocialAccountEnable,
    this.isandroidsocial,
    this.isAvailableForApply,
    this.companyFinancialData,
    this.keyPerformanceIndicator,
    this.ipoReservation,
    this.appplicationWiseBreakup,
    this.subscriptionDemand,
    this.interestCostPerShare,
    this.ipoSubscriptionDetail,
    this.subscriptionHistory,
    this.valuation,
    this.financialPerformance,
    this.categories,
    this.merchantBankerData,
    this.qibsOffered,
    this.hnisOffered,
    this.hnisTenPlusOffered,
    this.hnisTwoPlusOffered,
    this.retailOffered,
    this.anchorOffered,
    this.shareholderOffered,
    this.marketMakerOffered,
    this.employeesOffered,
    this.otherInvestorsOffered,
    this.institutionalInvestorsOffered,
    this.slug,
    this.financialLotsize,
    this.documentLinks,
    this.registrarDetails,
    this.companyDetails,
    this.objectOfIssue,
    this.promotersName,
    this.importantDates,
    this.quota,
  });

  // Helper method to safely convert numeric values to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Helper method to safely convert any value to String
  static String? _toString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  factory NewIpoModel.fromJson(Map<String, dynamic> json) {
    return NewIpoModel(
      id: _toInt(json['id']),
      docId: json['_docId'] as String?, // Firebase document ID
      companyName: json['company_name'] as String?,
      symbol: json['symbol'] as String?,
      securityType: json['security_type'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      allotmentDate: json['allotment_date'] as String?,
      listingDate: json['listing_date'] as String?,
      listingAtGroup: json['listing_at_group'] as String?,
      faceValue: json['face_value'] as String?,
      priceRange: json['price_range'] as String?,
      leadManagers: json['lead_managers'] as String?,
      issueSize: _toInt(json['issue_size']),
      freshIssueSize: _toString(json['fresh_issue_size']),
      freshIssueValue: _toInt(json['fresh_issue_value']),
      offerOfSale: _toInt(json['offer_of_sale']),
      offerOfSaleValue: _toString(json['offer_of_sale_value']),
      issueAmount: _toString(json['issue_amount']),
      issueType: json['issue_type'] as String?,
      bidLot: _toInt(json['bid_lot']),
      ipoMaxValue: _toInt(json['ipo_max_value']),
      ipoMinValue: _toInt(json['ipo_min_value']),
      maxInvestment: _toInt(json['max_investment']),
      minInvestment: _toInt(json['min_investment']),
      subscription: _toInt(json['subscription']),
      aboutTheCompany: json['about_the_company'] as String?,
      gmp: _toString(json['gmp']),
      status: json['status'] as String?,
      ipoImage: json['ipo_image'] as String?,
      recommendation: json['recommendation'] as String?,
      updatedAt: json['updated_at'] as String?,
      newSymbol: json['new_symbol'] as String?,
      ipoStatus: json['ipo_status'] != null
          ? IpoStatus.fromJson(json['ipo_status'] as Map<String, dynamic>)
          : null,
      isReview: json['is_review'] as bool?,
      preIssueShareHolding: _toInt(json['pre_issue_share_holding']),
      postIssueShareHolding: _toInt(json['post_issue_share_holding']),
      companyPromoter: json['company_promoter'] as String?,
      issueObjectives: json['issue_objectives'] as String?,
      nii: _toString(json['nii']),
      employee: _toString(json['employee']),
      retail: _toString(json['retail']),
      gibs: _toString(json['gibs']),
      sHniLotSize: _toInt(json['s_hni_lot_size']),
      bHniLotSize: _toInt(json['b_hni_lot_size']),
      sHniSubscription: _toString(json['s_hni_subscription']),
      bHniSubscription: _toString(json['b_hni_subscription']),
      retailPortion: _toString(json['retail_portion']),
      companyStrenght: json['company_strenght'] as String?,
      companyWeakness: json['company_weakness'] as String?,
      listedPrice: _toString(json['listed_price']),
      allotment: json['allotment'] as bool?,
      isFirstTimeUpdate: json['is_first_time_update'] as bool?,
      buySellNotification: json['buy_sell_notification'] as bool?,
      buyPrice: _toString(json['buy_price']),
      sellPrice: _toString(json['sell_price']),
      isActive: json['is_active'] as bool?,
      issuePrice: _toString(json['issue_price']),
      currentPrice: _toString(json['current_price']),
      gainOrLose: _toString(json['gain_or_lose']),
      scripCode: _toString(json['scrip_code']),
      listingDayGain: _toString(json['listing_day_gain']),
      listingDayClose: _toString(json['listing_day_close']),
      reason: json['reason'] as String?,
      isHold: json['is_hold'] as bool?,
      allotmentDateTime: json['allotment_date_time'] as String?,
      peerComparisonSource: json['peer_comparison_source'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      basicIndustry: json['basic_industry'] as String?,
      macroEconomicSector: json['macro_economic_sector'] as String?,
      spreadxIpoId: _toInt(json['spreadx_ipo_id']),
      anchorInvestorBidDate: json['anchor_investor_bid_date'] as String?,
      anchorLockinDate50: json['anchor_lockin_date_50'] as String?,
      anchorLockinDateRemaining:
          json['anchor_lockin_date_remaining'] as String?,
      anchorInvestorAmount: json['anchor_investor_amount'] as String?,
      anchorInvestorFileUrl: json['anchor_investor_file_url'] as String?,
      isBuySellEnable: json['is_buy_sell_enable'] as bool?,
      isSocialAccountEnable: json['is_social_account_enable'] as bool?,
      isandroidsocial: json['isandroidsocial'] as bool?,
      isAvailableForApply: json['is_available_for_apply'] as bool?,
      companyFinancialData:
          json['company_financial_data'] as Map<String, dynamic>?,
      keyPerformanceIndicator:
          json['key_performance_indicator'] as List<dynamic>?,
      ipoReservation: json['ipo_reservation'] as List<dynamic>?,
      appplicationWiseBreakup:
          json['appplication_wise_breakup'] as Map<String, dynamic>?,
      subscriptionDemand: json['subscription_demand'] as List<dynamic>?,
      interestCostPerShare: json['interest_cost_per_share'] as List<dynamic>?,
      ipoSubscriptionDetail: json['ipo_subscription_detail'] as List<dynamic>?,
      subscriptionHistory: json['subscription_history'] as List<dynamic>?,
      valuation: json['valuation'] as List<dynamic>?,
      financialPerformance: json['financial_performance'] as List<dynamic>?,
      categories: json['categories'] as List<dynamic>?,
      merchantBankerData: json['merchant_banker_data'] as List<dynamic>?,
      qibsOffered: _toInt(json['qibs_offered']),
      hnisOffered: _toInt(json['hnis_offered']),
      hnisTenPlusOffered: _toInt(json['hnis_ten_plus_offered']),
      hnisTwoPlusOffered: _toInt(json['hnis_two_plus_offered']),
      retailOffered: _toInt(json['retail_offered']),
      anchorOffered: _toInt(json['anchor_offered']),
      shareholderOffered: _toInt(json['shareholder_offered']),
      marketMakerOffered: _toInt(json['market_maker_offered']),
      employeesOffered: _toInt(json['employees_offered']),
      otherInvestorsOffered: _toInt(json['other_investors_offered']),
      institutionalInvestorsOffered:
          _toInt(json['institutional_investors_offered']),
      slug: json['slug'] as String?,
      financialLotsize: json['financialLotsize'], // Can be Map, List, or String
      documentLinks: json['document_links'], // Can be Map or List
      registrarDetails: json['registrar_details'], // Can be Map or List
      companyDetails: json['company_details'], // Can be Map or List
      objectOfIssue: json['ObjectOfIssue'], // Can be String or List
      promotersName: json['promotersName'], // Can be String or List
      importantDates: json['important_dates'], // Can be Map or List
      quota: json['quota'], // Can be Map, List, or String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '_docId': docId, // Firebase document ID
      'company_name': companyName,
      'symbol': symbol,
      'security_type': securityType,
      'start_date': startDate,
      'end_date': endDate,
      'allotment_date': allotmentDate,
      'listing_date': listingDate,
      'listing_at_group': listingAtGroup,
      'face_value': faceValue,
      'price_range': priceRange,
      'lead_managers': leadManagers,
      'issue_size': issueSize,
      'fresh_issue_size': freshIssueSize,
      'fresh_issue_value': freshIssueValue,
      'offer_of_sale': offerOfSale,
      'offer_of_sale_value': offerOfSaleValue,
      'issue_amount': issueAmount,
      'issue_type': issueType,
      'bid_lot': bidLot,
      'ipo_max_value': ipoMaxValue,
      'ipo_min_value': ipoMinValue,
      'max_investment': maxInvestment,
      'min_investment': minInvestment,
      'subscription': subscription,
      'about_the_company': aboutTheCompany,
      'gmp': gmp,
      'status': status,
      'ipo_image': ipoImage,
      'recommendation': recommendation,
      'updated_at': updatedAt,
      'new_symbol': newSymbol,
      'ipo_status': ipoStatus?.toJson(),
      'is_review': isReview,
      'pre_issue_share_holding': preIssueShareHolding,
      'post_issue_share_holding': postIssueShareHolding,
      'company_promoter': companyPromoter,
      'issue_objectives': issueObjectives,
      'nii': nii,
      'employee': employee,
      'retail': retail,
      'gibs': gibs,
      's_hni_lot_size': sHniLotSize,
      'b_hni_lot_size': bHniLotSize,
      's_hni_subscription': sHniSubscription,
      'b_hni_subscription': bHniSubscription,
      'retail_portion': retailPortion,
      'company_strenght': companyStrenght,
      'company_weakness': companyWeakness,
      'listed_price': listedPrice,
      'allotment': allotment,
      'is_first_time_update': isFirstTimeUpdate,
      'buy_sell_notification': buySellNotification,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'is_active': isActive,
      'issue_price': issuePrice,
      'current_price': currentPrice,
      'gain_or_lose': gainOrLose,
      'scrip_code': scripCode,
      'listing_day_gain': listingDayGain,
      'listing_day_close': listingDayClose,
      'reason': reason,
      'is_hold': isHold,
      'allotment_date_time': allotmentDateTime,
      'peer_comparison_source': peerComparisonSource,
      'sector': sector,
      'industry': industry,
      'basic_industry': basicIndustry,
      'macro_economic_sector': macroEconomicSector,
      'spreadx_ipo_id': spreadxIpoId,
      'anchor_investor_bid_date': anchorInvestorBidDate,
      'anchor_lockin_date_50': anchorLockinDate50,
      'anchor_lockin_date_remaining': anchorLockinDateRemaining,
      'anchor_investor_amount': anchorInvestorAmount,
      'anchor_investor_file_url': anchorInvestorFileUrl,
      'is_buy_sell_enable': isBuySellEnable,
      'is_social_account_enable': isSocialAccountEnable,
      'isandroidsocial': isandroidsocial,
      'is_available_for_apply': isAvailableForApply,
      'company_financial_data': companyFinancialData,
      'key_performance_indicator': keyPerformanceIndicator,
      'ipo_reservation': ipoReservation,
      'appplication_wise_breakup': appplicationWiseBreakup,
      'subscription_demand': subscriptionDemand,
      'interest_cost_per_share': interestCostPerShare,
      'ipo_subscription_detail': ipoSubscriptionDetail,
      'subscription_history': subscriptionHistory,
      'valuation': valuation,
      'financial_performance': financialPerformance,
      'categories': categories,
      'merchant_banker_data': merchantBankerData,
      'qibs_offered': qibsOffered,
      'hnis_offered': hnisOffered,
      'hnis_ten_plus_offered': hnisTenPlusOffered,
      'hnis_two_plus_offered': hnisTwoPlusOffered,
      'retail_offered': retailOffered,
      'anchor_offered': anchorOffered,
      'shareholder_offered': shareholderOffered,
      'market_maker_offered': marketMakerOffered,
      'employees_offered': employeesOffered,
      'other_investors_offered': otherInvestorsOffered,
      'institutional_investors_offered': institutionalInvestorsOffered,
      'slug': slug,
      'financialLotsize': financialLotsize,
      'document_links': documentLinks,
      'registrar_details': registrarDetails,
      'company_details': companyDetails,
      'ObjectOfIssue': objectOfIssue,
      'promotersName': promotersName,
      'important_dates': importantDates,
      'quota': quota,
    };
  }
}

class IpoStatus {
  final String? status;
  final String? color;
  final String? backgroundColor;

  IpoStatus({
    this.status,
    this.color,
    this.backgroundColor,
  });

  factory IpoStatus.fromJson(Map<String, dynamic> json) {
    return IpoStatus(
      status: json['status'] as String?,
      color: json['color'] as String?,
      backgroundColor: json['background_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'color': color,
      'background_color': backgroundColor,
    };
  }
}
