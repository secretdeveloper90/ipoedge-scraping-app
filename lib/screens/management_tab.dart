import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../widgets/bulk_add_ipo_modal.dart';
import 'ipo_management_screen.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({super.key});

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  List<IpoModel> _savedIpos = [];
  List<IpoModel> _filteredIpos = [];
  bool _isLoading = false;
  bool _isLoadingSavedIpos = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Track individual loading states for each IPO
  final Set<String> _updatingIpos = <String>{};
  final Set<String> _updatingCategories = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSavedIpos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedIpos() async {
    setState(() {
      _isLoadingSavedIpos = true;
    });

    try {
      if (!FirebaseService.isAvailable) {
        setState(() {
          _error = 'Firebase not available. Please check your configuration.';
          _isLoadingSavedIpos = false;
        });
        return;
      }

      final ipos = await FirebaseService.getAllIpos();
      setState(() {
        _savedIpos = ipos;
        _isLoadingSavedIpos = false;
      });

      // Reapply current search filter if there's an active search
      if (_searchQuery.isNotEmpty) {
        _filterIpos(_searchQuery);
      } else {
        setState(() {
          _filteredIpos = ipos;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingSavedIpos = false;
      });
    }
  }

  void _filterIpos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredIpos = _savedIpos;
      } else {
        _filteredIpos = _savedIpos.where((ipo) {
          final companyName = (ipo.companyName ?? '').toLowerCase();
          final companyId = ipo.companyId.toLowerCase();
          final searchLower = query.toLowerCase();

          return companyName.contains(searchLower) ||
              companyId.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _updateIpo(IpoModel ipo) async {
    if (ipo.id == null) return;

    setState(() {
      _updatingIpos.add(ipo.id!);
    });

    try {
      // Fetch updated data from API
      final updatedIpo = await ApiService.getIpoByCompanyId(ipo.companyId);

      // Extract specific fields from the updated IPO data
      final data = updatedIpo.additionalData;

      // Update only specific fields in Firebase
      await FirebaseService.updateIpoSpecificFields(
        ipo.id!,
        recentlyListed: data?['recentlyListed'] as bool?,
        subscriptionColor: data?['subscription_color']?.toString(),
        subscriptionText: data?['subscription_text']?.toString(),
        subscriptionValue: data?['subscription_value'],
        listingGains: data?['listing_gains'],
        sharesOnOffer: data?['shares_on_offer'],
        subscriptionRate: data?['subscription_rate'],
      );

      _showSnackBar('IPO updated successfully');
      _loadSavedIpos();
    } catch (e) {
      _showSnackBar('Error updating IPO: $e', isError: true);
    } finally {
      setState(() {
        _updatingIpos.remove(ipo.id!);
      });
    }
  }

  Future<void> _updateCategoryFromAnalysis(IpoModel ipo) async {
    if (ipo.id == null) return;

    setState(() {
      _updatingCategories.add(ipo.id!);
    });

    try {
      // Update category from IPO analysis collection
      await FirebaseService.updateCategoryFromAnalysis(ipo.id!, ipo.companyId);

      _showSnackBar('Category updated successfully from IPO analysis');
      _loadSavedIpos();
    } catch (e) {
      _showSnackBar('Error updating category: $e', isError: true);
    } finally {
      setState(() {
        _updatingCategories.remove(ipo.id!);
      });
    }
  }

  Future<void> _bulkUpdateAllIpos() async {
    if (_savedIpos.isEmpty) {
      _showSnackBar('No IPOs to update', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Bulk Update All IPOs',
      'Are you sure you want to update all ${_savedIpos.length} IPOs? This will fetch the latest data from the API for each IPO.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      int successCount = 0;
      int failureCount = 0;
      final List<String> failedCompanies = [];

      // Process IPOs in batches to avoid overwhelming the API
      const batchSize = 5;
      for (int i = 0; i < _savedIpos.length; i += batchSize) {
        final batch = _savedIpos.skip(i).take(batchSize).toList();

        // Process batch concurrently but with limited concurrency
        final futures = batch.map((ipo) async {
          if (ipo.id == null) {
            return {
              'success': false,
              'company': ipo.companyName ?? ipo.companyId
            };
          }

          try {
            // Fetch updated data from API
            final updatedIpo =
                await ApiService.getIpoByCompanyId(ipo.companyId);

            // Extract specific fields from the updated IPO data
            final data = updatedIpo.additionalData;

            // Update only specific fields in Firebase
            await FirebaseService.updateIpoSpecificFields(
              ipo.id!,
              category: data?['category']?.toString(),
              recentlyListed: data?['recentlyListed'] as bool?,
              subscriptionColor: data?['subscription_color']?.toString(),
              subscriptionText: data?['subscription_text']?.toString(),
              subscriptionValue: data?['subscription_value'],
              listingGains: data?['listing_gains'],
              sharesOnOffer: data?['shares_on_offer'],
              subscriptionRate: data?['subscription_rate'],
            );

            return {
              'success': true,
              'company': ipo.companyName ?? ipo.companyId
            };
          } catch (e) {
            return {
              'success': false,
              'company': ipo.companyName ?? ipo.companyId,
              'error': e.toString()
            };
          }
        });

        final results = await Future.wait(futures);

        for (final result in results) {
          if (result['success'] == true) {
            successCount++;
          } else {
            failureCount++;
            failedCompanies.add(result['company'] as String);
          }
        }

        // Small delay between batches to be respectful to the API
        if (i + batchSize < _savedIpos.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Show results
      if (failureCount == 0) {
        _showSnackBar('Successfully updated all $successCount IPOs');
      } else {
        _showSnackBar(
          'Updated $successCount IPOs successfully. $failureCount failed.',
          isError: failureCount > successCount,
        );

        // Show detailed failure information if there are failures
        if (failedCompanies.isNotEmpty) {
          _showBulkUpdateResultsDialog(
              successCount, failureCount, failedCompanies);
        }
      }

      _loadSavedIpos();
    } catch (e) {
      _showSnackBar('Error during bulk update: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteIpo(IpoModel ipo) async {
    if (ipo.id == null) return;

    final confirmed = await _showConfirmDialog(
      'Delete IPO',
      'Are you sure you want to delete ${ipo.companyName ?? ipo.companyId}?',
    );

    if (!confirmed) return;

    try {
      await FirebaseService.deleteIpo(ipo.id!);
      _showSnackBar('IPO deleted successfully');
      _loadSavedIpos();
    } catch (e) {
      _showSnackBar('Error deleting IPO: $e', isError: true);
    }
  }

  Future<void> _manageDocumentLinks(IpoModel ipo) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => IpoManagementScreen(ipo: ipo),
      ),
    );

    if (result == true) {
      _showSnackBar('Company details and documents updated successfully');
      _loadSavedIpos(); // Reload to get updated data
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: title.contains('Delete')
                ? const Text('Delete')
                : const Text('Update'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showBulkUpdateResultsDialog(
    int successCount,
    int failureCount,
    List<String> failedCompanies,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Update Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Successfully updated: $successCount IPOs'),
              const SizedBox(height: 8),
              Text('❌ Failed to update: $failureCount IPOs'),
              if (failedCompanies.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Failed companies:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: failedCompanies
                          .map((company) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text('• $company'),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openBulkAddModal() {
    showDialog(
      context: context,
      builder: (context) => BulkAddIpoModal(
        onIposAdded: _loadSavedIpos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSavedIpos,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildAddSection(),
            const Divider(),
            Expanded(child: _buildSavedIposSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSection() {
    return Container(
      margin: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _openBulkAddModal,
              icon: const Icon(Icons.add_circle, size: 20),
              label: const Text(
                'Add IPOs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
                minimumSize: const Size(0, 44), // Medium button height
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed:
                  _savedIpos.isEmpty || _isLoading ? null : _bulkUpdateAllIpos,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.update, size: 20),
              label: Text(
                _isLoading ? 'Updating...' : 'Update All',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _savedIpos.isEmpty || _isLoading
                    ? Colors.grey
                    : Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: Colors.orange.withOpacity(0.3),
                minimumSize: const Size(0, 44), // Medium button height
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedIposSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard_customize_rounded,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Saved IPOs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          letterSpacing: 0.2,
                          fontSize: 16,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? '${_filteredIpos.length}/${_savedIpos.length}'
                        : '${_savedIpos.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSearchBar(),
          Expanded(
            child: _buildSavedIposList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: TextField(
        controller: _searchController,
        onChanged: _filterIpos,
        decoration: InputDecoration(
          hintText: 'Search IPOs by company name or ID...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterIpos('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSavedIposList() {
    if (_isLoadingSavedIpos) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
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
                  'Error loading saved IPOs',
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
                  onPressed: _loadSavedIpos,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_savedIpos.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
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
                  'No saved IPOs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add IPOs using the form above',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredIpos.isEmpty && _searchQuery.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No IPOs found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search query',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _filterIpos('');
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildManagementDataTable(),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        icon: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(icon),
        color: color,
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        iconSize: 14,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildManagementDataTable() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
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
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columnSpacing: 0,
          horizontalMargin: 0,
          headingRowHeight: 40,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
          columns: [
            DataColumn(
              label: Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: const Text('Company Name'),
                ),
              ),
            ),
            DataColumn(
              label: Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  child: const Text('Actions'),
                ),
              ),
            ),
          ],
          rows: _filteredIpos.map((ipo) {
            return DataRow(
              cells: [
                // DataCell(
                //   SizedBox(
                //     width: 80,
                //     child: Text(
                //       ipo.companyId.isNotEmpty ? ipo.companyId : 'N/A',
                //       style: TextStyle(
                //         fontSize: 12,
                //         fontWeight: FontWeight.w600,
                //         color: Theme.of(context).primaryColor,
                //       ),
                //       overflow: TextOverflow.ellipsis,
                //       maxLines: 2,
                //     ),
                //   ),
                // ),
                DataCell(
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      ipo.companyName?.isNotEmpty == true
                          ? ipo.companyName!
                          : ipo.companyId.isNotEmpty
                              ? ipo.companyId
                              : 'Unknown Company',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 3,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.business_center,
                          color: Colors.blue,
                          onPressed: () => _manageDocumentLinks(ipo),
                          tooltip: 'Company & Documents',
                        ),
                        const SizedBox(width: 2),
                        _buildActionButton(
                          icon: Icons.category,
                          color: Colors.purple,
                          onPressed: () => _updateCategoryFromAnalysis(ipo),
                          tooltip: 'Update Category',
                          isLoading: _updatingCategories.contains(ipo.id),
                        ),
                        const SizedBox(width: 2),
                        _buildActionButton(
                          icon: Icons.refresh,
                          color: Colors.orange,
                          onPressed: () => _updateIpo(ipo),
                          tooltip: 'Update',
                          isLoading: _updatingIpos.contains(ipo.id),
                        ),
                        const SizedBox(width: 2),
                        _buildActionButton(
                          icon: Icons.delete,
                          color: Colors.red,
                          onPressed: () => _deleteIpo(ipo),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
