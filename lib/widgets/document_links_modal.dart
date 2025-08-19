import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ipo_model.dart';
import '../services/firebase_service.dart';

class DocumentLinksModal extends StatefulWidget {
  final IpoModel ipo;
  final VoidCallback onSaved;

  const DocumentLinksModal({
    super.key,
    required this.ipo,
    required this.onSaved,
  });

  @override
  State<DocumentLinksModal> createState() => _DocumentLinksModalState();
}

class _DocumentLinksModalState extends State<DocumentLinksModal> {
  final _formKey = GlobalKey<FormState>();
  final _drhpLinkController = TextEditingController();
  final _rhpLinkController = TextEditingController();
  final _anchorLinkController = TextEditingController();
  final _expectedPremiumController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = false;

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
  }

  @override
  void dispose() {
    _drhpLinkController.dispose();
    _rhpLinkController.dispose();
    _anchorLinkController.dispose();
    _expectedPremiumController.dispose();
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
      await FirebaseService.updateIpoDocumentLinks(
        widget.ipo.id!,
        drhpLink: _drhpLinkController.text.trim().isEmpty
            ? '' // Empty string to remove the field
            : _drhpLinkController.text.trim(),
        rhpLink: _rhpLinkController.text.trim().isEmpty
            ? '' // Empty string to remove the field
            : _rhpLinkController.text.trim(),
        anchorLink: _anchorLinkController.text.trim().isEmpty
            ? '' // Empty string to remove the field
            : _anchorLinkController.text.trim(),
        expectedPremium: _expectedPremiumController.text.trim().isEmpty
            ? '' // Empty string to remove the field
            : _expectedPremiumController.text.trim(),
      );

      widget.onSaved();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingData)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: _buildForm(),
              ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Links Section
            Text(
              'Document Links',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            _buildLinkField(
              controller: _drhpLinkController,
              label: 'DRHP Link',
              hint: 'Enter DRHP document URL',
              icon: Icons.description,
            ),
            const SizedBox(height: 12),
            _buildLinkField(
              controller: _rhpLinkController,
              label: 'RHP Link',
              hint: 'Enter RHP document URL',
              icon: Icons.article,
            ),
            const SizedBox(height: 12),
            _buildLinkField(
              controller: _anchorLinkController,
              label: 'ANCHOR Link',
              hint: 'Enter ANCHOR document URL',
              icon: Icons.anchor,
            ),
            const SizedBox(height: 16),

            // Expected Premium Section
            Text(
              'Expected Premium',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _expectedPremiumController,
              decoration: const InputDecoration(
                labelText: 'Expected Premium',
                hintText: 'Enter expected premium (e.g., 25-26 (25%))',
                prefixIcon: Icon(Icons.trending_up),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              maxLines: 1,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    final hasUrl = controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
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
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveDocumentLinks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
