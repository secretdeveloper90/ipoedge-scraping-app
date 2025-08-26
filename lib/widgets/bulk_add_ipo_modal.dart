import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';
import '../models/ipo_model.dart';
import 'multi_select_ipo_dropdown.dart';
import 'manual_ipo_input.dart';

class BulkAddIpoModal extends StatefulWidget {
  final VoidCallback onIposAdded;

  const BulkAddIpoModal({
    super.key,
    required this.onIposAdded,
  });

  @override
  State<BulkAddIpoModal> createState() => _BulkAddIpoModalState();
}

class _BulkAddIpoModalState extends State<BulkAddIpoModal>
    with TickerProviderStateMixin {
  List<IpoOption> _selectedIpoOptions = [];
  List<String> _manualIpoIds = [];
  bool _isBulkLoading = false;
  int _currentBulkIndex = 0;
  int _totalBulkItems = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Method to add new IPOs with their appropriate categories (skip existing ones)
  Future<void> _addNewIposWithCategories(
      List<IpoModel> ipos, List<String> newIpoIds) async {
    // Create a map to track categories for each IPO ID
    final Map<String, String> ipoCategories = {};

    // Get categories from selected dropdown options
    for (final option in _selectedIpoOptions) {
      if (option.category != null) {
        ipoCategories[option.companyId] = option.category!;
      }
    }

    // For manual IDs, look up their categories from ipo_analysis collection
    final manualIds =
        _manualIpoIds.where((id) => !ipoCategories.containsKey(id)).toList();
    if (manualIds.isNotEmpty) {
      try {
        final analysisIpos = await FirebaseService.getAllIposFromAnalysis();
        for (final analysisIpo in analysisIpos) {
          final category = analysisIpo.category;
          if (category != null && manualIds.contains(analysisIpo.companyId)) {
            ipoCategories[analysisIpo.companyId] = category;
          }
        }
      } catch (e) {
        // If we can't get categories from analysis, continue without them
      }
    }

    // Add each new IPO with its category (only add, don't update)
    for (final ipo in ipos) {
      final category = ipoCategories[ipo.companyId];
      try {
        // Use addIpo instead of addOrUpdateIpo to ensure we only add new records
        await FirebaseService.addIpo(ipo, category: category);
      } catch (e) {
        // Error adding IPO, continue with other IPOs
        rethrow;
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _addBulkIpos() async {
    // Validate Firebase availability
    if (!FirebaseService.isAvailable) {
      _showSnackBar('Firebase not available. Please check your configuration.',
          isError: true);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Combine selected options and manual IDs
    final allIpoIds = <String>[];

    // Add IDs from dropdown selection
    allIpoIds.addAll(_selectedIpoOptions.map((option) => option.companyId));

    // Add manual IDs
    allIpoIds.addAll(_manualIpoIds);

    // Remove duplicates and validate
    final uniqueIpoIds =
        allIpoIds.toSet().where((id) => id.trim().isNotEmpty).toList();

    if (uniqueIpoIds.isEmpty) {
      _showSnackBar('Please select or enter at least one valid IPO ID',
          isError: true);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Show confirmation dialog for large batches
    if (uniqueIpoIds.length > 10) {
      final confirmed = await _showBulkConfirmDialog(uniqueIpoIds.length);
      if (!confirmed) return;
    }

    setState(() {
      _isBulkLoading = true;
      _currentBulkIndex = 0;
      _totalBulkItems = uniqueIpoIds.length;
    });

    try {
      // Check for existing IPOs with better error handling
      List<String> existingIds = [];
      try {
        existingIds = await FirebaseService.getExistingIpoIds(uniqueIpoIds);
      } catch (e) {
        _showSnackBar('Error checking existing IPOs: $e', isError: true);
        setState(() {
          _isBulkLoading = false;
        });
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Filter out existing IPOs - only process new ones
      final newIpoIds =
          uniqueIpoIds.where((id) => !existingIds.contains(id)).toList();
      final skippedCount = existingIds.length;

      if (existingIds.isNotEmpty) {
        _showSnackBar(
            '${existingIds.length} IPO(s) already exist and will be skipped');
      }

      if (newIpoIds.isEmpty) {
        _showSnackBar(
            'All IPOs already exist in the database. No new IPOs to add.');
        setState(() {
          _isBulkLoading = false;
        });
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Update total items to reflect only new IPOs
      setState(() {
        _totalBulkItems = newIpoIds.length;
      });

      // Fetch and process IPOs with enhanced error tracking
      final iposToProcess = <IpoModel>[];
      final failedIds = <Map<String, String>>[];
      const batchSize = 5;

      for (int i = 0; i < newIpoIds.length; i += batchSize) {
        final batch = newIpoIds.skip(i).take(batchSize).toList();

        // Process batch concurrently but with limited concurrency
        final futures = batch.map((id) async {
          setState(() {
            _currentBulkIndex = i + batch.indexOf(id) + 1;
          });

          try {
            final ipo = await ApiService.getIpoByCompanyId(id);
            return {'success': true, 'ipo': ipo, 'id': id};
          } catch (e) {
            return {'success': false, 'error': e.toString(), 'id': id};
          }
        });

        final results = await Future.wait(futures);

        for (final result in results) {
          if (result['success'] == true) {
            iposToProcess.add(result['ipo'] as IpoModel);
          } else {
            failedIds.add({
              'id': result['id'] as String,
              'error': result['error'] as String,
            });
          }
        }

        // Small delay between batches to be respectful to the API
        if (i + batchSize < newIpoIds.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Add successful IPOs to Firebase with their categories (only new ones)
      if (iposToProcess.isNotEmpty) {
        try {
          // Group IPOs by their categories and add them (not update since they're all new)
          await _addNewIposWithCategories(iposToProcess, newIpoIds);
        } catch (e) {
          _showSnackBar('Error saving IPOs to Firebase: $e', isError: true);
          setState(() {
            _isBulkLoading = false;
          });
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }

      // Show detailed results
      await _showBulkResultsDialog(
        successCount: iposToProcess.length,
        skippedCount: skippedCount, // Show how many existing IPOs were skipped
        failedIds: failedIds,
      );

      // Clear selections and notify parent
      _clearBulkSelections();
      widget.onIposAdded();

      // Close modal after showing results
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Unexpected error during bulk add: $e', isError: true);
      if (mounted) Navigator.of(context).pop();
    } finally {
      setState(() {
        _isBulkLoading = false;
        _currentBulkIndex = 0;
        _totalBulkItems = 0;
      });
    }
  }

  void _clearBulkSelections() {
    setState(() {
      _selectedIpoOptions.clear();
      _manualIpoIds.clear();
    });
  }

  Future<bool> _showBulkConfirmDialog(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Add/Update'),
        content: Text(
          'You are about to add/update $count IPOs. Existing IPOs will be updated with latest data and categories. '
          'This may take several minutes to complete. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showBulkResultsDialog({
    required int successCount,
    required int skippedCount,
    required List<Map<String, String>> failedIds,
  }) async {
    final failedCount = failedIds.length;
    final totalProcessed = successCount + failedCount;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Add/Update Results'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Processed $totalProcessed IPO${totalProcessed == 1 ? '' : 's'}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Success
              if (successCount > 0) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text('$successCount successfully added/updated'),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Failed
              if (failedCount > 0) ...[
                Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text('$failedCount failed'),
                  ],
                ),
                if (failedIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Failed IPO IDs:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: failedIds
                            .take(10)
                            .map((failed) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${failed['id']}: ${failed['error']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (failedIds.length > 10)
                    Text(
                      '... and ${failedIds.length - 10} more',
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                ],
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

  @override
  Widget build(BuildContext context) {
    final totalSelected = _selectedIpoOptions.length + _manualIpoIds.length;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).primaryColor,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Dropdown'),
                  Tab(text: 'Manual'),
                ],
              ),
            ),

            // Tab content - full height
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Dropdown selection tab
                    MultiSelectIpoDropdown(
                      selectedOptions: _selectedIpoOptions,
                      onSelectionChanged: (options) {
                        setState(() {
                          _selectedIpoOptions = options;
                        });
                      },
                      enabled: !_isBulkLoading,
                    ),
                    // Manual input tab
                    ManualIpoInput(
                      ipoIds: _manualIpoIds,
                      onIpoIdsChanged: (ids) {
                        setState(() {
                          _manualIpoIds = ids;
                        });
                      },
                      enabled: !_isBulkLoading,
                    ),
                  ],
                ),
              ),
            ),

            // Progress indicator during bulk loading
            if (_isBulkLoading) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adding/Updating IPOs...',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_currentBulkIndex of $_totalBulkItems completed',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _totalBulkItems > 0
                          ? _currentBulkIndex / _totalBulkItems
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],

            // Bottom section with summary and actions
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isBulkLoading) ...[
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          flex: totalSelected > 0 ? 2 : 1,
                          child: ElevatedButton.icon(
                            onPressed: totalSelected > 0 ? _addBulkIpos : null,
                            icon: const Icon(Icons.add_circle, size: 20),
                            label: Text(
                              totalSelected > 0
                                  ? 'Add $totalSelected IPO${totalSelected == 1 ? '' : 's'}'
                                  : 'Select IPOs to Add',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: totalSelected > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                              elevation: totalSelected > 0 ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
