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
  final _slugController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _expectedPremiumController = TextEditingController();
  bool _isLoading = false;
  bool _isSavingAdditionalData = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _slugController.dispose();
    _imageUrlController.dispose();
    _expectedPremiumController.dispose();
    super.dispose();
  }

  // Load existing slug, image URL, and expected premium from Firebase if they exist
  Future<void> _loadExistingData() async {
    try {
      if (widget.ipo.id != null && widget.ipo.id!.isNotEmpty) {
        final existingSlug =
            await FirebaseService.getSlugForIpo(widget.ipo.id!);
        final existingImageUrl =
            await FirebaseService.getImageUrlForIpo(widget.ipo.id!);
        final existingExpectedPremium =
            await FirebaseService.getExpectedPremiumForIpo(widget.ipo.id!);

        setState(() {
          if (existingSlug != null && existingSlug.isNotEmpty) {
            _slugController.text = existingSlug;
          }
          if (existingImageUrl != null && existingImageUrl.isNotEmpty) {
            _imageUrlController.text = existingImageUrl;
          }
          if (existingExpectedPremium != null &&
              existingExpectedPremium.isNotEmpty) {
            _expectedPremiumController.text = existingExpectedPremium;
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

  Future<void> _saveAdditionalData() async {
    final imageUrl = _imageUrlController.text.trim();
    final expectedPremium = _expectedPremiumController.text.trim();

    if (imageUrl.isEmpty && expectedPremium.isEmpty) {
      _showSnackBar(
          'Please enter at least one field (Image URL or Expected Premium)',
          isError: true);
      return;
    }

    setState(() {
      _isSavingAdditionalData = true;
    });

    try {
      if (widget.ipo.id != null && widget.ipo.id!.isNotEmpty) {
        List<String> savedFields = [];

        // Save image URL if provided
        if (imageUrl.isNotEmpty) {
          await FirebaseService.saveImageUrl(widget.ipo.id!, imageUrl);
          savedFields.add('Image URL');
          _imageUrlController.clear();
        }

        // Save expected premium if provided
        if (expectedPremium.isNotEmpty) {
          await FirebaseService.saveExpectedPremium(
              widget.ipo.id!, expectedPremium);
          savedFields.add('Expected Premium');
          _expectedPremiumController.clear();
        }

        _showSnackBar('${savedFields.join(' and ')} saved successfully!');
      } else {
        _showSnackBar('Error: No IPO ID found to update', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error saving data: $e', isError: true);
    } finally {
      setState(() {
        _isSavingAdditionalData = false;
      });
    }
  }

  Future<void> _storeIpoData() async {
    final slug = _slugController.text.trim();
    if (slug.isEmpty) {
      _showSnackBar('Please enter an IPO slug', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
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
            'IPO data merged successfully! Existing data preserved. ID: ${widget.ipo.id}');
      } else {
        _showSnackBar('Error: No IPO ID found to update', isError: true);
        return;
      }

      // Clear the slug field after successful storage
      _slugController.clear();
    } catch (e) {
      _showSnackBar('Error storing IPO data: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
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
          if (_isLoading)
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
                // IPO Slug input field
                TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: 'IPO Slug',
                    hintText:
                        'Enter the IPO slug (will be stored for future updates)',
                    prefixIcon: const Icon(Icons.business),
                    suffixIcon: _slugController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _slugController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear IPO Slug',
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
                  onFieldSubmitted: (_) => _storeIpoData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.go,
                ),
                const SizedBox(height: 16),

                // Image URL input field
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Company Logo URL',
                    hintText: 'Enter the company logo image URL',
                    prefixIcon: const Icon(Icons.image),
                    suffixIcon: _imageUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _imageUrlController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear Image URL',
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
                  onFieldSubmitted: (_) => _saveAdditionalData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Expected Premium input field
                TextFormField(
                  controller: _expectedPremiumController,
                  decoration: InputDecoration(
                    labelText: 'Expected Premium',
                    hintText: 'Enter expected premium (e.g., 15-20%)',
                    prefixIcon: const Icon(Icons.trending_up),
                    suffixIcon: _expectedPremiumController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _expectedPremiumController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear Expected Premium',
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
                  onFieldSubmitted: (_) => _saveAdditionalData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                // Buttons in one row
                Row(
                  children: [
                    // Save Additional Data button (Image URL & Expected Premium)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSavingAdditionalData ||
                                (_imageUrlController.text.trim().isEmpty &&
                                    _expectedPremiumController.text
                                        .trim()
                                        .isEmpty)
                            ? null
                            : _saveAdditionalData,
                        icon: _isSavingAdditionalData
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_alt, size: 18),
                        label: Text(
                          _isSavingAdditionalData ? 'Saving...' : 'Save Data',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(0, 36),
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Store IPO Data button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoading || _slugController.text.trim().isEmpty
                                ? null
                                : _storeIpoData,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync, size: 18),
                        label: Text(
                          _isLoading ? 'Merging...' : 'Merge IPO',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(0, 36),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
