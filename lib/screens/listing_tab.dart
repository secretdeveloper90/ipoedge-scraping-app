import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/firebase_service.dart';

class ListingTab extends StatefulWidget {
  const ListingTab({super.key});

  @override
  State<ListingTab> createState() => _ListingTabState();
}

class _ListingTabState extends State<ListingTab> {
  Map<String, List<IpoModel>> _categorizedIpos = {};
  bool _isLoading = true;
  bool _isUpdatingFirebase = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIpos();
  }

  Future<void> _loadIpos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch data from Firebase ipo_analysis collection instead of API
      final allIpos = await FirebaseService.getAllIposFromAnalysis();

      // Categorize the Firebase data
      final categorizedIpos = _categorizeFirebaseData(allIpos);

      setState(() {
        _categorizedIpos = categorizedIpos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Categorize Firebase data based on category field or status
  Map<String, List<IpoModel>> _categorizeFirebaseData(List<IpoModel> ipos) {
    final Map<String, List<IpoModel>> categorized = {
      'draft_issues': <IpoModel>[],
      'upcoming_open': <IpoModel>[],
      'listing_soon': <IpoModel>[],
      'recently_listed': <IpoModel>[],
      'gain_loss_analysis': <IpoModel>[],
    };

    for (final ipo in ipos) {
      // Check if the IPO has a category field from Firebase
      final category = ipo.additionalData?['category']?.toString();

      if (category != null && categorized.containsKey(category)) {
        categorized[category]!.add(ipo);
      } else {
        // Fallback: categorize based on status or other fields from additionalData
        final status =
            (ipo.additionalData?['status']?.toString() ?? '').toLowerCase();
        final listingDate = ipo.additionalData?['listing_date']?.toString() ??
            ipo.additionalData?['listingDate']?.toString();
        final listingGain = ipo.additionalData?['listing_gain'] ??
            ipo.additionalData?['listingGain'] ??
            ipo.additionalData?['listing_gainP'];

        if (status.contains('draft') || status.contains('drhp')) {
          categorized['draft_issues']!.add(ipo);
        } else if (status.contains('upcoming') || status.contains('open')) {
          categorized['upcoming_open']!.add(ipo);
        } else if (status.contains('listing') && !status.contains('listed')) {
          categorized['listing_soon']!.add(ipo);
        } else if (status.contains('listed') || listingDate != null) {
          if (listingGain != null) {
            categorized['gain_loss_analysis']!.add(ipo);
          } else {
            categorized['recently_listed']!.add(ipo);
          }
        } else {
          // Default to draft_issues if no clear category
          categorized['draft_issues']!.add(ipo);
        }
      }
    }

    return categorized;
  }

  Future<void> _updateAllData() async {
    setState(() {
      _isUpdatingFirebase = true;
    });

    try {
      // Fetch fresh data from API and update Firebase ipo_analysis collection
      await FirebaseService.updateAllIpoData();

      // Reload the display data from Firebase after update
      await _loadIpos();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'All IPO data updated successfully in Firebase ipo_analysis collection'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _isUpdatingFirebase = false;
      });
    } catch (e) {
      setState(() {
        _isUpdatingFirebase = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating Firebase data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Fixed button positioning with proper margins
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: ElevatedButton.icon(
              onPressed: _isUpdatingFirebase ? null : _updateAllData,
              icon: _isUpdatingFirebase
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.cloud_sync, size: 20),
              label: Text(
                _isUpdatingFirebase
                    ? 'Updating Firebase...'
                    : 'Update All Data',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
          ),
          // Scrollable content with proper spacing
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading IPOs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadIpos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Check if all categories are empty
    final totalIpos =
        _categorizedIpos.values.fold<int>(0, (sum, list) => sum + list.length);

    if (totalIpos == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No IPO data available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Update All Data" to fetch the latest IPO information',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIpos,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildCategorySection(
              'Draft Issues', 'draft_issues', Icons.edit_note),
          const SizedBox(height: 6),
          _buildCategorySection(
              'Upcoming Open', 'upcoming_open', Icons.schedule),
          const SizedBox(height: 6),
          _buildCategorySection(
              'Listing Soon', 'listing_soon', Icons.trending_up),
          const SizedBox(height: 6),
          _buildCategorySection(
              'Recently Listed', 'recently_listed', Icons.check_circle),
          const SizedBox(height: 6),
          _buildCategorySection(
              'Gain/Loss Analysis', 'gain_loss_analysis', Icons.analytics),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
      String title, String categoryKey, IconData icon) {
    final ipos = _categorizedIpos[categoryKey] ?? [];

    if (ipos.isEmpty) {
      return const SizedBox.shrink(); // Don't show empty categories
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4.0, bottom: 6.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: 0.3,
                        fontSize: 18,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '${ipos.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildDataTable(ipos),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDataTable(List<IpoModel> ipos) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width -
                32,
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 12,
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 36,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            ),
            columns: const [
              DataColumn(
                label: Text('Sr. No.'),
              ),
              DataColumn(
                label: Text('Company Name'),
              ),
            ],
            rows: ipos.asMap().entries.map((entry) {
              final index = entry.key;
              final ipo = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ipo.companyName ??
                          (ipo.companyId.isNotEmpty
                              ? ipo.companyId
                              : 'Unknown Company'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
