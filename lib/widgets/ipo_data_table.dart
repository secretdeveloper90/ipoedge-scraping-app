import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../models/new_ipo_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

class IpoDataTable extends StatefulWidget {
  final List<NewIpoModel> ipos;
  final Function(NewIpoModel) onEdit;
  final Function(List<NewIpoModel>)? onSelectionChanged;
  final String ipoType; // 'mainboard' or 'sme'
  final String category; // 'live', 'upcoming', or 'listed'
  final VoidCallback? onDataUpdated; // Callback to reload data after update

  const IpoDataTable({
    super.key,
    required this.ipos,
    required this.onEdit,
    this.onSelectionChanged,
    required this.ipoType,
    required this.category,
    this.onDataUpdated,
  });

  @override
  State<IpoDataTable> createState() => _IpoDataTableState();
}

class _IpoDataTableState extends State<IpoDataTable> {
  final Set<String> _selectedIds = {};
  bool _isUpdating = false;
  bool _isDeleting = false;
  final Set<String> _updatingIndividualIds = {}; // Track individual IPO updates

  bool get _isAllSelected =>
      widget.ipos.isNotEmpty && _selectedIds.length == widget.ipos.length;

  bool get _isSomeSelected =>
      _selectedIds.isNotEmpty && _selectedIds.length < widget.ipos.length;

  List<NewIpoModel> get _selectedIpos => widget.ipos
      .where((ipo) => ipo.docId != null && _selectedIds.contains(ipo.docId))
      .toList();

  @override
  void didUpdateWidget(IpoDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selections when the IPO list changes
    if (oldWidget.ipos != widget.ipos) {
      _selectedIds.clear();
      _notifySelectionChanged();
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.clear();
        for (var ipo in widget.ipos) {
          if (ipo.docId != null) {
            _selectedIds.add(ipo.docId!);
          }
        }
      } else {
        _selectedIds.clear();
      }
    });
    _notifySelectionChanged();
  }

  void _toggleSelection(String? docId) {
    if (docId == null) return;

    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    if (widget.onSelectionChanged != null) {
      final selectedIpos = widget.ipos
          .where((ipo) => ipo.docId != null && _selectedIds.contains(ipo.docId))
          .toList();
      widget.onSelectionChanged!(selectedIpos);
    }
  }

  Future<void> _updateSingleIpo(NewIpoModel ipo) async {
    debugPrint('🔄 Starting individual update for: ${ipo.companyName}');

    final firebaseDocId = ipo.docId;
    if (firebaseDocId == null) {
      debugPrint('❌ No Firebase document ID found for: ${ipo.companyName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No Firebase document ID found for ${ipo.companyName ?? "this IPO"}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Use the IPO ID to fetch updated data
    final ipoId = ipo.id;
    debugPrint('📝 IPO ID for ${ipo.companyName}: $ipoId');

    if (ipoId == null) {
      debugPrint('❌ No IPO ID found for: ${ipo.companyName}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No IPO ID found for ${ipo.companyName ?? "this IPO"}. Cannot update from API.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _updatingIndividualIds.add(firebaseDocId);
    });

    try {
      debugPrint('🌐 Fetching data from API for IPO ID: $ipoId');

      // Fetch all IPOs from the same category and type
      final ipoList = await ApiService.getNewIpoList(
        ipoType: widget.ipoType,
        category: widget.category,
        pageSize: 500,
      );

      debugPrint('📊 Fetched ${ipoList.length} IPOs from API');

      // Find the matching IPO by ID
      final updatedIpo = ipoList.firstWhere(
        (apiIpo) => apiIpo.id == ipoId,
        orElse: () =>
            throw Exception('IPO with ID $ipoId not found in API response'),
      );

      debugPrint('✅ Found matching IPO in API: ${updatedIpo.companyName}');

      // Convert to JSON and update in Firebase
      final ipoData = updatedIpo.toJson();
      ipoData['_firebaseUpdatedAt'] = DateTime.now();

      debugPrint('💾 Updating Firebase for docId: $firebaseDocId');

      await FirebaseService.updateIpoInManagement(
        docId: firebaseDocId,
        ipoType: widget.ipoType,
        category: widget.category,
        ipoData: ipoData,
      );

      debugPrint('✅ Firebase updated successfully for: ${ipo.companyName}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${ipo.companyName ?? "IPO"} updated successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reload data
        if (widget.onDataUpdated != null) {
          debugPrint('🔄 Reloading table data...');
          widget.onDataUpdated!();
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating ${ipo.companyName}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error updating ${ipo.companyName ?? "IPO"}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingIndividualIds.remove(firebaseDocId);
        });
      }
    }
  }

  Future<void> _updateSelectedIpos() async {
    if (_selectedIpos.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Update IPOs',
      'Are you sure you want to update ${_selectedIpos.length} selected IPO(s) from the API?',
    );

    if (!confirmed) return;

    setState(() {
      _isUpdating = true;
    });

    int successCount = 0;
    int failCount = 0;
    final List<String> errors = [];

    try {
      // Fetch all IPOs from the API once
      debugPrint('🌐 Fetching all IPOs from API for bulk update...');
      final ipoList = await ApiService.getNewIpoList(
        ipoType: widget.ipoType,
        category: widget.category,
        pageSize: 500,
      );
      debugPrint('📊 Fetched ${ipoList.length} IPOs from API');

      // Create a map of ID -> IPO for quick lookup
      final ipoMap = <int, NewIpoModel>{};
      for (final apiIpo in ipoList) {
        if (apiIpo.id != null) {
          ipoMap[apiIpo.id!] = apiIpo;
        }
      }

      for (final ipo in _selectedIpos) {
        try {
          // Get the Firebase document ID
          final firebaseDocId = ipo.docId;
          if (firebaseDocId == null) {
            failCount++;
            errors.add(
                '${ipo.companyName ?? "Unknown"}: No Firebase document ID found');
            continue;
          }

          // Use the IPO ID to find updated data
          final ipoId = ipo.id;
          if (ipoId == null) {
            failCount++;
            errors.add(
                '${ipo.companyName ?? "Unknown"}: No IPO ID found for API update');
            continue;
          }

          // Find the matching IPO in the API response
          final updatedIpo = ipoMap[ipoId];
          if (updatedIpo == null) {
            failCount++;
            errors.add(
                '${ipo.companyName ?? "Unknown"}: IPO with ID $ipoId not found in API response');
            continue;
          }

          debugPrint('✅ Found matching IPO for ${ipo.companyName}');

          // Convert to JSON and update in Firebase
          final ipoData = updatedIpo.toJson();
          ipoData['_firebaseUpdatedAt'] = DateTime.now();

          await FirebaseService.updateIpoInManagement(
            docId: firebaseDocId,
            ipoType: widget.ipoType,
            category: widget.category,
            ipoData: ipoData,
          );

          successCount++;
        } catch (e) {
          failCount++;
          errors.add('${ipo.companyName ?? "Unknown"}: ${e.toString()}');
        }
      }
    } catch (e) {
      // Error fetching from API
      debugPrint('❌ Error fetching IPOs from API: $e');
      for (final ipo in _selectedIpos) {
        failCount++;
        errors.add('${ipo.companyName ?? "Unknown"}: Failed to fetch API data');
      }
    }

    setState(() {
      _isUpdating = false;
      _selectedIds.clear();
    });

    _notifySelectionChanged();

    // Show result
    if (mounted) {
      String message = 'Updated $successCount IPO(s)';
      if (failCount > 0) {
        message += ', $failCount failed';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
          action: errors.isNotEmpty
              ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    if (mounted) {
                      _showErrorDialog(errors);
                    }
                  },
                )
              : null,
        ),
      );

      // Reload data
      if (widget.onDataUpdated != null) {
        widget.onDataUpdated!();
      }
    }
  }

  Future<void> _deleteSelectedIpos() async {
    if (_selectedIpos.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      'Delete IPOs',
      'Are you sure you want to delete ${_selectedIpos.length} selected IPO(s)? This action cannot be undone.',
    );

    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    int successCount = 0;
    int failCount = 0;
    final List<String> errors = [];

    for (final ipo in _selectedIpos) {
      try {
        final firebaseDocId = ipo.docId;
        if (firebaseDocId == null) {
          failCount++;
          errors.add(
              '${ipo.companyName ?? "Unknown"}: No Firebase document ID found');
          continue;
        }

        // Delete from Firebase
        await FirebaseService.deleteIpoFromManagement(
          docId: firebaseDocId,
          ipoType: widget.ipoType,
          category: widget.category,
        );

        successCount++;
      } catch (e) {
        failCount++;
        errors.add('${ipo.companyName ?? "Unknown"}: ${e.toString()}');
      }
    }

    setState(() {
      _isDeleting = false;
      _selectedIds.clear();
    });

    _notifySelectionChanged();

    // Show result
    if (mounted) {
      String message = 'Deleted $successCount IPO(s)';
      if (failCount > 0) {
        message += ', $failCount failed';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 3),
          action: errors.isNotEmpty
              ? SnackBarAction(
                  label: 'Details',
                  textColor: Colors.white,
                  onPressed: () {
                    _showErrorDialog(errors);
                  },
                )
              : null,
        ),
      );

      // Reload data
      if (widget.onDataUpdated != null) {
        widget.onDataUpdated!();
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showErrorDialog(List<String> errors) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Error Details'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: errors.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '• ${errors[index]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSlugInputDialog(NewIpoModel ipo) async {
    // Fetch existing slug from ipo_remaining_data collection
    String? existingSlug;
    if (ipo.id != null) {
      try {
        final remainingData = await FirebaseService.getIpoRemainingData(
          ipoId: ipo.id!,
          ipoType: widget.ipoType,
          category: widget.category,
        );
        existingSlug = remainingData?['slug'] as String?;
      } catch (e) {
        debugPrint('Error fetching existing slug: $e');
      }
    }

    final TextEditingController slugController = TextEditingController(
      text: existingSlug ??
          ipo.slug ??
          '', // Pre-fill with existing slug if available
    );
    bool isLoading = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.edit, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ipo.companyName ?? 'N/A',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: slugController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'IPO Dekho Slug',
                      hintText: 'e.g., example-company-ipo',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final slug = slugController.text.trim();
                          if (slug.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a slug'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            // Call the API
                            final ipoData =
                                await ApiService.getIpoDetailsBySlug(slug);

                            // Extract the actual IPO data from the nested response structure
                            final actualIpoData =
                                ipoData['data']['Data'] as Map<String, dynamic>;

                            // Store in ipo_remaining_data collection if IPO has an ID
                            if (ipo.id != null && ipo.companyName != null) {
                              // Map document links from IPO Dekho response
                              final documentLinks = {
                                'drhp': actualIpoData['DRHPDraft'],
                                'rhp': actualIpoData['RHPDraft'],
                                'anchor': actualIpoData['AnchorInvestors'],
                              };

                              // Map company details from IPO Dekho response
                              final companyDetails = {
                                'description':
                                    actualIpoData['companyDescription'],
                                'address': actualIpoData['address'],
                                'website': actualIpoData['website'],
                                'email': actualIpoData['email'],
                                'phone': actualIpoData['companyPhone'],
                              };

                              // Map important dates from IPO Dekho response
                              final importantDates = {
                                'open_date': actualIpoData['IPOOpenDate'],
                                'close_date': actualIpoData['IPOCloseDate'],
                                'allotment_date':
                                    actualIpoData['IPOAllotmentDate'],
                                'refund_date':
                                    actualIpoData['IPORefundsInitiation'],
                                'demat_transfer_date':
                                    actualIpoData['IPODematTransfer'],
                                'listing_date': actualIpoData['IPOListingDate'],
                              };

                              // Map quota from IPO Dekho response
                              final quota = {
                                'retail': actualIpoData['reatailQuota'],
                                'qib': actualIpoData['qibQuota'],
                                'nii': actualIpoData['nilQuota'],
                              };

                              // Map registrar details from IPO Dekho response
                              final registrarDetails = {
                                'name': actualIpoData['registerName'],
                                'email': actualIpoData['registerEmail'],
                                'phone': actualIpoData['registerPhone'],
                                'website': actualIpoData['registerWebsite'],
                                'allotment_link':
                                    actualIpoData['allotmentLink'],
                                'check_allotment':
                                    actualIpoData['checkAllotment'],
                              };

                              // Store only specific IPO Dekho fields (as defined in NewIpoModel)
                              final remainingData = <String, dynamic>{
                                'slug': slug,
                                'financialLotsize':
                                    actualIpoData['financialLotsize'],
                                'document_links': documentLinks,
                                'registrar_details': registrarDetails,
                                'company_details': companyDetails,
                                'ObjectOfIssue': actualIpoData['ObjectOfIssue'],
                                'promotersName': actualIpoData['promotersName'],
                                'important_dates': importantDates,
                                'quota': quota,
                              };

                              await FirebaseService.addOrUpdateIpoRemainingData(
                                ipoId: ipo.id!,
                                companyName: ipo.companyName!,
                                remainingData: remainingData,
                                ipoType: widget.ipoType,
                                category: widget.category,
                              );
                            }

                            if (!context.mounted) return;

                            setState(() {
                              isLoading = false;
                            });

                            Navigator.pop(context);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully stored data for: ${actualIpoData['companyName'] ?? slug}',
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            // Reload data if callback provided
                            if (widget.onDataUpdated != null) {
                              widget.onDataUpdated!();
                            }
                          } catch (e) {
                            if (!context.mounted) return;

                            setState(() {
                              isLoading = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(isLoading ? 'Storing...' : 'Store Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔧 IpoDataTable build called with ${widget.ipos.length} IPOs');
    for (var ipo in widget.ipos) {
      debugPrint('  - ${ipo.companyName} (docId: ${ipo.docId})');
    }

    return Column(
      children: [
        // Action bar for selected items
        if (_selectedIds.isNotEmpty) _buildActionBar(),

        // Data table - use Expanded to take remaining space
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DataTable2(
                columnSpacing: 0,
                horizontalMargin: 0,
                headingRowHeight: 48,
                dataRowHeight: 52,
                fixedTopRows: 1, // This makes the header fixed
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: [
                  DataColumn2(
                    size: ColumnSize.S,
                    fixedWidth: 40,
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      child: Checkbox(
                        value: _isAllSelected
                            ? true
                            : (_isSomeSelected ? null : false),
                        tristate: true,
                        onChanged: _toggleSelectAll,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.L,
                    fixedWidth: 205,
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Text(
                          'Company Name ( Total : ${widget.ipos.length} )'),
                    ),
                  ),
                  DataColumn2(
                    size: ColumnSize.S,
                    fixedWidth: 78,
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      child: const Text('Actions'),
                    ),
                  ),
                ],
                rows: widget.ipos.map((ipo) {
                  final isSelected =
                      ipo.docId != null && _selectedIds.contains(ipo.docId);
                  return DataRow2(
                    selected: isSelected,
                    cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(ipo.docId),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(
                            ipo.companyName ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                color: Colors.blue,
                                onPressed: () => _showSlugInputDialog(ipo),
                                tooltip: 'Edit Slug',
                              ),
                              const SizedBox(width: 3),
                              _buildActionButton(
                                icon: Icons.refresh,
                                color: Colors.orange,
                                onPressed: () => _updateSingleIpo(ipo),
                                tooltip: 'Update from API',
                                isLoading:
                                    _updatingIndividualIds.contains(ipo.docId),
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
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Update button
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isUpdating || _isDeleting ? null : _updateSelectedIpos,
              icon: _isUpdating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                _isUpdating ? 'Updating...' : 'Update',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Delete button
          Expanded(
            child: ElevatedButton.icon(
              onPressed:
                  _isUpdating || _isDeleting ? null : _deleteSelectedIpos,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.delete, size: 16),
              label: Text(
                _isDeleting ? 'Deleting...' : 'Delete',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
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
}
