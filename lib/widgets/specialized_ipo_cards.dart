import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../utils/formatters.dart';

// Base card widget with common styling
abstract class BaseIpoCard extends StatelessWidget {
  final IpoModel ipo;
  final VoidCallback? onTap;

  const BaseIpoCard({
    super.key,
    required this.ipo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
          highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), 
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context);

  Widget buildCompanyHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        ipo.displayName,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              fontSize: 18,
              letterSpacing: 0.2,
              height: 1.3,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: valueColor ?? Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.grey.shade800,
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 1. Draft Issues IPO Card
class DraftIssueCard extends BaseIpoCard {
  const DraftIssueCard({
    super.key,
    required super.ipo,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCompanyHeader(context),
        const SizedBox(height: 18),
        if (ipo.issueSize != null || ipo.drhpFilingDate != null)
          LayoutBuilder(
            builder: (context, constraints) {
              // Use column layout on smaller screens
              if (constraints.maxWidth < 320) {
                return Column(
                  children: [
                    if (ipo.issueSize != null) ...[
                      buildInfoRow(
                        'Issue Size',
                        IpoFormatters.formatIssueSize(ipo.issueSize),
                        Icons.account_balance,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (ipo.drhpFilingDate != null)
                      buildInfoRow(
                        'DRHP Filing',
                        IpoFormatters.formatDate(ipo.drhpFilingDate),
                        Icons.calendar_today,
                      ),
                  ],
                );
              }
              // Use row layout on larger screens
              return Row(
                children: [
                  if (ipo.issueSize != null)
                    Expanded(
                      child: buildInfoRow(
                        'Issue Size',
                        IpoFormatters.formatIssueSize(ipo.issueSize),
                        Icons.account_balance,
                      ),
                    ),
                  if (ipo.issueSize != null && ipo.drhpFilingDate != null)
                    const SizedBox(width: 14),
                  if (ipo.drhpFilingDate != null)
                    Expanded(
                      child: buildInfoRow(
                        'DRHP Filing',
                        IpoFormatters.formatDate(ipo.drhpFilingDate),
                        Icons.calendar_today,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// 2. Upcoming Open IPO Card
class UpcomingOpenCard extends BaseIpoCard {
  const UpcomingOpenCard({
    super.key,
    required super.ipo,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCompanyHeader(context),
        const SizedBox(height: 18),
        if (ipo.openDate != null && ipo.closeDate != null) ...[
          buildInfoRow(
            'Open - Close Date',
            IpoFormatters.formatDateRange(ipo.openDate, ipo.closeDate),
            Icons.date_range,
          ),
          const SizedBox(height: 14),
        ],
        if (ipo.lotSize != null || ipo.issuePrice != null)
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 320) {
                return Column(
                  children: [
                    if (ipo.lotSize != null) ...[
                      buildInfoRow(
                        'Lot Size',
                        IpoFormatters.formatLotSize(ipo.lotSize),
                        Icons.inventory,
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (ipo.issuePrice != null)
                      buildInfoRow(
                        'Issue Price',
                        ipo.issuePriceFormatted,
                        Icons.currency_rupee,
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  if (ipo.lotSize != null)
                    Expanded(
                      child: buildInfoRow(
                        'Lot Size',
                        IpoFormatters.formatLotSize(ipo.lotSize),
                        Icons.inventory,
                      ),
                    ),
                  if (ipo.lotSize != null && ipo.issuePrice != null)
                    const SizedBox(width: 14),
                  if (ipo.issuePrice != null)
                    Expanded(
                      child: buildInfoRow(
                        'Issue Price',
                        ipo.issuePriceFormatted,
                        Icons.currency_rupee,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

// 3. Listing Soon IPO Card
class ListingSoonCard extends BaseIpoCard {
  const ListingSoonCard({
    super.key,
    required super.ipo,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCompanyHeader(context),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  if (ipo.allotmentDate != null) ...[
                    buildInfoRow(
                      'Allotment Date',
                      IpoFormatters.formatDate(ipo.allotmentDate),
                      Icons.assignment,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ipo.listingDate != null) ...[
                    buildInfoRow(
                      'Listing Date',
                      IpoFormatters.formatDate(ipo.listingDate),
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ipo.totalSubscription != null)
                    buildInfoRow(
                      'Total Subscription',
                      IpoFormatters.formatSubscription(ipo.totalSubscription),
                      Icons.analytics,
                      valueColor: IpoFormatters.getSubscriptionColor(
                          ipo.totalSubscription),
                    ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    if (ipo.allotmentDate != null)
                      Expanded(
                        child: buildInfoRow(
                          'Allotment Date',
                          IpoFormatters.formatDate(ipo.allotmentDate),
                          Icons.assignment,
                        ),
                      ),
                    if (ipo.allotmentDate != null && ipo.listingDate != null)
                      const SizedBox(width: 14),
                    if (ipo.listingDate != null)
                      Expanded(
                        child: buildInfoRow(
                          'Listing Date',
                          IpoFormatters.formatDate(ipo.listingDate),
                          Icons.trending_up,
                        ),
                      ),
                  ],
                ),
                if (ipo.totalSubscription != null) ...[
                  const SizedBox(height: 14),
                  buildInfoRow(
                    'Total Subscription',
                    IpoFormatters.formatSubscription(ipo.totalSubscription),
                    Icons.analytics,
                    valueColor: IpoFormatters.getSubscriptionColor(
                        ipo.totalSubscription),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// 4. Recently Listed IPO Card
class RecentlyListedCard extends BaseIpoCard {
  const RecentlyListedCard({
    super.key,
    required super.ipo,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCompanyHeader(context),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  if (ipo.listingDate != null) ...[
                    buildInfoRow(
                      'Listing Date',
                      IpoFormatters.formatDate(ipo.listingDate),
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ipo.issuePrice != null) ...[
                    buildInfoRow(
                      'Issue Price',
                      ipo.issuePriceFormatted,
                      Icons.currency_rupee,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ipo.listingGain != null)
                    buildInfoRow(
                      'Listing Gain/Loss',
                      IpoFormatters.formatPercentage(ipo.listingGain),
                      ipo.listingGain! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      valueColor:
                          IpoFormatters.getPercentageColor(ipo.listingGain),
                    ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    if (ipo.listingDate != null)
                      Expanded(
                        child: buildInfoRow(
                          'Listing Date',
                          IpoFormatters.formatDate(ipo.listingDate),
                          Icons.calendar_today,
                        ),
                      ),
                    if (ipo.listingDate != null && ipo.issuePrice != null)
                      const SizedBox(width: 14),
                    if (ipo.issuePrice != null)
                      Expanded(
                        child: buildInfoRow(
                          'Issue Price',
                          ipo.issuePriceFormatted,
                          Icons.currency_rupee,
                        ),
                      ),
                  ],
                ),
                if (ipo.listingGain != null) ...[
                  const SizedBox(height: 14),
                  buildInfoRow(
                    'Listing Gain/Loss',
                    IpoFormatters.formatPercentage(ipo.listingGain),
                    ipo.listingGain! >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    valueColor:
                        IpoFormatters.getPercentageColor(ipo.listingGain),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// 5. Gain and Loss Analysis Card
class GainLossAnalysisCard extends BaseIpoCard {
  const GainLossAnalysisCard({
    super.key,
    required super.ipo,
    super.onTap,
  });

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildCompanyHeader(context),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 320) {
              return Column(
                children: [
                  if (ipo.listingGain != null) ...[
                    buildInfoRow(
                      'Listing Gain/Loss',
                      IpoFormatters.formatPercentage(ipo.listingGain),
                      ipo.listingGain! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      valueColor:
                          IpoFormatters.getPercentageColor(ipo.listingGain),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (ipo.currentGain != null)
                    buildInfoRow(
                      'Current Gain/Loss',
                      IpoFormatters.formatPercentage(ipo.currentGain),
                      ipo.currentGain! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      valueColor:
                          IpoFormatters.getPercentageColor(ipo.currentGain),
                    ),
                ],
              );
            }
            return Row(
              children: [
                if (ipo.listingGain != null)
                  Expanded(
                    child: buildInfoRow(
                      'Listing Gain/Loss',
                      IpoFormatters.formatPercentage(ipo.listingGain),
                      ipo.listingGain! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      valueColor:
                          IpoFormatters.getPercentageColor(ipo.listingGain),
                    ),
                  ),
                if (ipo.listingGain != null && ipo.currentGain != null)
                  const SizedBox(width: 14),
                if (ipo.currentGain != null)
                  Expanded(
                    child: buildInfoRow(
                      'Current Gain/Loss',
                      IpoFormatters.formatPercentage(ipo.currentGain),
                      ipo.currentGain! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      valueColor:
                          IpoFormatters.getPercentageColor(ipo.currentGain),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
