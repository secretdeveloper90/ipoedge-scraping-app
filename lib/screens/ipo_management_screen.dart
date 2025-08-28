import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ipo_model.dart';
import '../services/firebase_service.dart';
import '../services/ipoji_scraper_service.dart';

class IpoManagementScreen extends StatefulWidget {
  final IpoModel ipo;

  const IpoManagementScreen({
    super.key,
    required this.ipo,
  });

  @override
  State<IpoManagementScreen> createState() =>
      _IpoManagementScreenState();
}

class _IpoManagementScreenState extends State<IpoManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _drhpLinkController = TextEditingController();
  final _rhpLinkController = TextEditingController();
  final _anchorLinkController = TextEditingController();
  final _expectedPremiumController = TextEditingController();
  final _companyLogoController = TextEditingController();

  // Company details controllers
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyWebsiteController = TextEditingController();

  // IPOji scraping
  final _ipojiUrlController = TextEditingController();
  bool _isLoading = false;
  bool _isScrapingLoading = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    _drhpLinkController.text = widget.ipo.drhpLink ?? '';
    _rhpLinkController.text = widget.ipo.rhpLink ?? '';
    _anchorLinkController.text = widget.ipo.anchorLink ?? '';
    _expectedPremiumController.text = widget.ipo.expectedPremium ?? '';

    // Populate company logo from company_headers.company_logo
    final additionalData = widget.ipo.additionalData;
    if (additionalData != null && additionalData['company_headers'] != null) {
      final companyHeaders =
          additionalData['company_headers'] as Map<String, dynamic>;
      _companyLogoController.text =
          companyHeaders['company_logo']?.toString() ?? '';
    } else {
      _companyLogoController.text = widget.ipo.companyLogo ?? '';
    }

    // Populate company details from nested company_details object
    if (additionalData != null && additionalData['company_details'] != null) {
      final companyDetails =
          additionalData['company_details'] as Map<String, dynamic>;
      _companyNameController.text =
          companyDetails['company_name']?.toString() ?? '';
      _companyAddressController.text =
          companyDetails['address']?.toString() ?? '';
      _companyEmailController.text = companyDetails['email']?.toString() ?? '';
      _companyPhoneController.text = companyDetails['phone']?.toString() ?? '';
      _companyWebsiteController.text =
          companyDetails['website']?.toString() ?? '';
    } else {
      // Fallback to root level fields for backward compatibility
      _companyNameController.text = '';
      if (additionalData != null) {
        _companyAddressController.text =
            additionalData['company_address']?.toString() ?? '';
        _companyEmailController.text =
            additionalData['company_email']?.toString() ?? '';
        _companyPhoneController.text =
            additionalData['company_phone']?.toString() ?? '';
        _companyWebsiteController.text =
            additionalData['company_website']?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _drhpLinkController.dispose();
    _rhpLinkController.dispose();
    _anchorLinkController.dispose();
    _expectedPremiumController.dispose();
    _companyLogoController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyWebsiteController.dispose();
    _ipojiUrlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'Please enter a valid URL (http:// or https://)';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  Future<void> _saveDocumentLinks() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.ipo.id == null) {
      _showSnackBar('IPO ID is required to save document links', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseService.updateIpoDocumentLinksAndCompanyDetails(
        widget.ipo.id!,
        drhpLink: _drhpLinkController.text.trim().isEmpty
            ? ''
            : _drhpLinkController.text.trim(),
        rhpLink: _rhpLinkController.text.trim().isEmpty
            ? ''
            : _rhpLinkController.text.trim(),
        anchorLink: _anchorLinkController.text.trim().isEmpty
            ? ''
            : _anchorLinkController.text.trim(),
        expectedPremium: _expectedPremiumController.text.trim().isEmpty
            ? ''
            : _expectedPremiumController.text.trim(),
        companyLogo: _companyLogoController.text.trim().isEmpty
            ? ''
            : _companyLogoController.text.trim(),
        companyName: _companyNameController.text.trim().isEmpty
            ? null
            : _companyNameController.text.trim(),
        companyAddress: _companyAddressController.text.trim().isEmpty
            ? null
            : _companyAddressController.text.trim(),
        companyEmail: _companyEmailController.text.trim().isEmpty
            ? null
            : _companyEmailController.text.trim(),
        companyPhone: _companyPhoneController.text.trim().isEmpty
            ? null
            : _companyPhoneController.text.trim(),
        companyWebsite: _companyWebsiteController.text.trim().isEmpty
            ? null
            : _companyWebsiteController.text.trim(),
      );

      _showSnackBar('Document links updated successfully');
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      _showSnackBar('Error saving document links: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      _showSnackBar('No URL provided', isError: true);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not launch URL', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error launching URL: $e', isError: true);
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

  Future<void> _scrapeIpojiData() async {
    final url = _ipojiUrlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('Please enter an IPOji URL', isError: true);
      return;
    }

    if (!url.contains('ipoji.com/ipo/')) {
      _showSnackBar('Please enter a valid IPOji IPO URL', isError: true);
      return;
    }

    setState(() {
      _isScrapingLoading = true;
    });

    try {
      final scrapedData = await IpojiScraperService.scrapeIpojiData(url);

      // Populate company details
      final companyDetails =
          scrapedData['company_details'] as Map<String, String?>?;
      if (companyDetails != null) {
        if (companyDetails['company_name']?.isNotEmpty == true) {
          _companyNameController.text = companyDetails['company_name']!;
        }
        if (companyDetails['address']?.isNotEmpty == true) {
          _companyAddressController.text = companyDetails['address']!;
        }
        if (companyDetails['email']?.isNotEmpty == true) {
          _companyEmailController.text = companyDetails['email']!;
        }
        if (companyDetails['phone']?.isNotEmpty == true) {
          _companyPhoneController.text = companyDetails['phone']!;
        }
        if (companyDetails['website']?.isNotEmpty == true) {
          _companyWebsiteController.text = companyDetails['website']!;
        }
      }

      // Populate document links
      final documentLinks =
          scrapedData['document_links'] as Map<String, String?>?;
      if (documentLinks != null) {
        if (documentLinks['drhp']?.isNotEmpty == true) {
          _drhpLinkController.text = documentLinks['drhp']!;
        }
        if (documentLinks['rhp']?.isNotEmpty == true) {
          _rhpLinkController.text = documentLinks['rhp']!;
        }
        if (documentLinks['anchor']?.isNotEmpty == true) {
          _anchorLinkController.text = documentLinks['anchor']!;
        }
      }

      // Populate company logo
      final companyLogo = scrapedData['company_logo'] as String?;
      if (companyLogo?.isNotEmpty == true) {
        _companyLogoController.text = companyLogo!;
      }

      // Populate expected premium
      final expectedPremium = scrapedData['expected_premium'] as String?;
      if (expectedPremium?.isNotEmpty == true) {
        _expectedPremiumController.text = expectedPremium!;
      }

      _showSnackBar('Data scraped successfully from IPOji!');
    } catch (e) {
      _showSnackBar('Error scraping data: $e', isError: true);
    } finally {
      setState(() {
        _isScrapingLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company & Document Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              widget.ipo.companyName ?? widget.ipo.companyId,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // IPOji Scraping Section
            _buildScrapingSection(),
            const SizedBox(height: 24),
            _buildSection(
              'Company Information',
              Icons.business,
              [
                _buildLinkField(
                  controller: _companyLogoController,
                  label: 'Company Logo URL',
                  hint: 'Enter company logo URL',
                  icon: Icons.image,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _expectedPremiumController,
                  label: 'Expected Premium',
                  hint: 'Enter expected premium value',
                  icon: Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Company Details',
              Icons.business_center,
              [
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  hint: 'Enter company name',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Company name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyAddressController,
                  label: 'Company Address',
                  hint: 'Enter complete company address',
                  icon: Icons.location_on,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyEmailController,
                  label: 'Email',
                  hint: 'Enter email address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyPhoneController,
                  label: 'Phone',
                  hint: 'Enter phone number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildLinkField(
                  controller: _companyWebsiteController,
                  label: 'Website',
                  hint: 'Enter company website URL',
                  icon: Icons.language,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Document Management',
              Icons.description,
              [
                _buildLinkField(
                  controller: _drhpLinkController,
                  label: 'DRHP Document URL',
                  hint: 'Enter DRHP document URL',
                  icon: Icons.description,
                ),
                const SizedBox(height: 16),
                _buildLinkField(
                  controller: _rhpLinkController,
                  label: 'RHP Document URL',
                  hint: 'Enter RHP document URL',
                  icon: Icons.article,
                ),
                const SizedBox(height: 16),
                _buildLinkField(
                  controller: _anchorLinkController,
                  label: 'Anchor Document URL',
                  hint: 'Enter anchor document URL',
                  icon: Icons.anchor,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScrapingSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced URL input field
                TextFormField(
                  controller: _ipojiUrlController,
                  decoration: InputDecoration(
                    labelText: 'IPO Data Source URL',
                    hintText: 'Paste the URL to scrape IPO information',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.link,
                        size: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    suffixIcon: _ipojiUrlController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onPressed: () {
                              _ipojiUrlController.clear();
                              setState(() {});
                            },
                            tooltip: 'Clear URL',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onFieldSubmitted: (_) => _scrapeIpojiData(),
                  onChanged: (value) => setState(() {}),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                ),
                const SizedBox(height: 16),

                // Enhanced action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScrapingLoading ||
                            _ipojiUrlController.text.trim().isEmpty
                        ? null
                        : _scrapeIpojiData,
                    icon: _isScrapingLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.auto_fix_high,
                            size: 18,
                          ),
                    label: Text(
                      _isScrapingLoading
                          ? 'Extracting Data...'
                          : 'Extract IPO Data',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScrapingLoading ||
                              _ipojiUrlController.text.trim().isEmpty
                          ? Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: _isScrapingLoading ||
                              _ipojiUrlController.text.trim().isEmpty
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isScrapingLoading ||
                              _ipojiUrlController.text.trim().isEmpty
                          ? 0
                          : 3,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      minimumSize: const Size(0, 40),
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final hasUrl = controller.text.isNotEmpty;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: hasUrl
            ? IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                onPressed: () => _launchUrl(controller.text),
                tooltip: 'Open link',
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      validator: _validateUrl,
      keyboardType: TextInputType.url,
      maxLines: 2,
      minLines: 1,
      onChanged: (value) {
        setState(() {}); // Rebuild to show/hide open link button
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType ?? TextInputType.text,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveDocumentLinks,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
