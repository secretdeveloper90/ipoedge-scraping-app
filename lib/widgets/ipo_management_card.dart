import 'package:flutter/material.dart';
import '../models/ipo_model.dart';

class IpoManagementCard extends StatelessWidget {
  final IpoModel ipo;
  final VoidCallback onView;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const IpoManagementCard({
    super.key,
    required this.ipo,
    required this.onView,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ipo.companyName ??
                            (ipo.companyId.isNotEmpty
                                ? ipo.companyId
                                : 'Unknown Company'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ipo.companyName != null)
                        Text(
                          'ID: ${ipo.companyId}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                    ],
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
                    ),
                  ),
                if (ipo.listingPrice != null && ipo.listingPrice! > 0)
                  Expanded(
                    child: _buildInfoItem(
                      'Listing Price',
                      '₹${ipo.listingPrice!.toStringAsFixed(2)}',
                    ),
                  ),
                if (ipo.listingGain != null)
                  Expanded(
                    child: _buildInfoItem(
                      'Gain',
                      '${ipo.listingGain! >= 0 ? '+' : ''}${ipo.listingGain!.toStringAsFixed(2)}%',
                      color: ipo.listingGain! >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'View',
                  onPressed: onView,
                  color: Colors.blue,
                ),
                _buildActionButton(
                  icon: Icons.refresh,
                  label: 'Update',
                  onPressed: onUpdate,
                  color: Colors.orange,
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  onPressed: onDelete,
                  color: Colors.red,
                ),
              ],
            ),
            if (ipo.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Last updated: ${_formatDate(ipo.updatedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? color}) {
    return Column(
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          color: color,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
