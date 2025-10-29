import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class IpoManagementScreen extends StatefulWidget {
  final IpoModel ipo;

  const IpoManagementScreen({
    super.key,
    required this.ipo,
  });

  @override
  State<IpoManagementScreen> createState() => _IpoManagementScreenState();
}

class _IpoManagementScreenState extends State<IpoManagementScreen> {
  final _ipoDekhoSlugController = TextEditingController();
  final _ipoTrendSlugController = TextEditingController();
  bool _isLoadingDekho = false;
  bool _isLoadingTrend = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _ipoDekhoSlugController.dispose();
    _ipoTrendSlugController.dispose();
    super.dispose();
  }

  // Load existing slugs from Firebase if they exist
  Future<void> _loadExistingData() async {
    try {
      if (widget.ipo.id != null && widget.ipo.id!.isNotEmpty) {
        final existingSlug =
            await FirebaseService.getSlugForIpo(widget.ipo.id!);

        // Load BSEScriptCode from stock_data for IPO Trend slug
        final bseScriptCode =
            await FirebaseService.getBSEScriptCodeForIpo(widget.ipo.id!);

        setState(() {
          if (existingSlug != null && existingSlug.isNotEmpty) {
            _ipoDekhoSlugController.text = existingSlug;
          }
          if (bseScriptCode != null && bseScriptCode.isNotEmpty) {
            _ipoTrendSlugController.text = bseScriptCode;
          }
        });
      }
    } catch (e) {
      // Silently handle error - fields will remain empty
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

  Future<void> _storeIpoDekhoData() async {
    final slug = _ipoDekhoSlugController.text.trim();
    if (slug.isEmpty) {
      _showSnackBar('Please enter an IPO Dekho slug', isError: true);
      return;
    }

    setState(() {
      _isLoadingDekho = true;
    });

    try {
      // Fetch IPO details from API
      final ipoData = await ApiService.getIpoDetailsBySlug(slug);

      // Extract the actual IPO data from the nested response structure
      final actualIpoData = ipoData['data']['Data'] as Map<String, dynamic>;

      // Merge the new data with existing IPO using the IPO ID from widget
      if (widget.ipo.id != null && widget.ipo.id!.isNotEmpty) {
        // Merge new data with existing IPO (preserves all existing fields)
        await FirebaseService.updateIpoWithSpecificData(
          widget.ipo.id!,
          actualIpoData,
          slug, // Pass the slug for storage
        );

        _showSnackBar(
            'IPO Dekho data merged successfully! ID: ${widget.ipo.id}');
      } else {
        _showSnackBar('Error: No IPO ID found to update', isError: true);
        return;
      }

      // Clear the slug field after successful storage
      _ipoDekhoSlugController.clear();
    } catch (e) {
      _showSnackBar('Error storing IPO Dekho data: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingDekho = false;
      });
    }
  }

  Future<void> _storeIpoTrendData() async {
    final symbol = _ipoTrendSlugController.text.trim();
    if (symbol.isEmpty) {
      _showSnackBar('Please enter an IPO Trend symbol', isError: true);
      return;
    }

    setState(() {
      _isLoadingTrend = true;
    });

    try {
      // Fetch IPO details from IPO Trend API by symbol
      final ipoData = await ApiService.getIpoDetailsBySymbol(symbol);

      // Merge the new data with existing IPO using the IPO ID from widget
      if (widget.ipo.id != null && widget.ipo.id!.isNotEmpty) {
        // Merge IPO Trend data with existing IPO (preserves all existing fields)
        await FirebaseService.updateIpoWithTrendData(
          widget.ipo.id!,
          ipoData,
          symbol, // Pass the symbol for storage
        );

        _showSnackBar(
            'IPO Trend data merged successfully! ID: ${widget.ipo.id}');
      } else {
        _showSnackBar('Error: No IPO ID found to update', isError: true);
        return;
      }

      // Clear the symbol field after successful storage
      _ipoTrendSlugController.clear();
    } catch (e) {
      _showSnackBar('Error storing IPO Trend data: $e', isError: true);
    } finally {
      setState(() {
        _isLoadingTrend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ipo.companyName ?? 'IPO Data Storage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          if (_isLoadingDekho || _isLoadingTrend)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // API Data Storage Section
            _buildDataFetchingSection(),
            const SizedBox(height: 24),
            // Extra bottom padding for keyboard space
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDataFetchingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Card(
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IPO Dekho Slug input field
                TextFormField(
                  controller: _ipoDekhoSlugController,
                  decoration: InputDecoration(
                    labelText: 'IPO Dekho Slug',
                    hintText: 'Enter the IPO Dekho slug',
                    prefixIcon: const Icon(Icons.business),
                    suffixIcon: _ipoDekhoSlugController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _ipoDekhoSlugController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear IPO Dekho Slug',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onFieldSubmitted: (_) => _storeIpoDekhoData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.go,
                ),
                const SizedBox(height: 12),

                // Store IPO Dekho Data button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingDekho ||
                            _ipoDekhoSlugController.text.trim().isEmpty
                        ? null
                        : _storeIpoDekhoData,
                    icon: _isLoadingDekho
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(
                      _isLoadingDekho ? 'Storing...' : 'Store IPO Dekho Data',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 40),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // IPO Trend Slug input field
                TextFormField(
                  controller: _ipoTrendSlugController,
                  decoration: InputDecoration(
                    labelText: 'IPO Trend Slug',
                    hintText: 'Enter the IPO Trend symbol (e.g., ORKLAINDIA)',
                    prefixIcon: const Icon(Icons.trending_up),
                    suffixIcon: _ipoTrendSlugController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _ipoTrendSlugController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear IPO Trend Slug',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onFieldSubmitted: (_) => _storeIpoTrendData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.go,
                ),
                const SizedBox(height: 12),

                // Store IPO Trend Data button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingTrend ||
                            _ipoTrendSlugController.text.trim().isEmpty
                        ? null
                        : _storeIpoTrendData,
                    icon: _isLoadingTrend
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload, size: 18),
                    label: Text(
                      _isLoadingTrend ? 'Storing...' : 'Store IPO Trend Data',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 40),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
