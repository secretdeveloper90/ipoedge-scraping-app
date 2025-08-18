import 'package:flutter/material.dart';
import '../models/ipo_model.dart';

class IpoCard extends StatelessWidget {
  final IpoModel ipo;
  final VoidCallback? onTap;
  final bool showYear;

  const IpoCard({
    super.key,
    required this.ipo,
    this.onTap,
    this.showYear = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ipo.companyName ??
                          (ipo.companyId.isNotEmpty
                              ? ipo.companyId
                              : 'Unknown Company'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (ipo.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ipo.status!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ipo.status!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (ipo.sector != null || ipo.industry != null)
                Text(
                  [ipo.sector, ipo.industry]
                      .where((element) => element != null)
                      .join(' • '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (ipo.issuePrice != null && ipo.issuePrice! > 0)
                    Expanded(
                      child: _buildInfoItem(
                        'Issue Price',
                        '₹${ipo.issuePrice!.toStringAsFixed(2)}',
                        Icons.currency_rupee,
                      ),
                    ),
                  if (ipo.listingPrice != null && ipo.listingPrice! > 0)
                    Expanded(
                      child: _buildInfoItem(
                        'Listing Price',
                        '₹${ipo.listingPrice!.toStringAsFixed(2)}',
                        Icons.trending_up,
                      ),
                    ),
                ],
              ),
              if (ipo.issuePrice != null && ipo.listingPrice != null)
                const SizedBox(height: 8),
              if (ipo.listingGain != null)
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Listing Gain',
                        '${ipo.listingGain! >= 0 ? '+' : ''}${ipo.listingGain!.toStringAsFixed(2)}%',
                        ipo.listingGain! >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color:
                            ipo.listingGain! >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    if (ipo.listingDate != null && showYear)
                      Expanded(
                        child: _buildInfoItem(
                          'Listing Date',
                          ipo.listingDate!,
                          Icons.calendar_today,
                        ),
                      ),
                  ],
                ),
              if (ipo.issueSize != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildInfoItem(
                    'Issue Size',
                    ipo.issueSize!,
                    Icons.account_balance,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'listed':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'open':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      case 'withdrawn':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
