import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../widgets/ipo_management_card.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({super.key});

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
  final TextEditingController _companyIdController = TextEditingController();
  List<IpoModel> _savedIpos = [];
  bool _isLoading = false;
  bool _isLoadingSavedIpos = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedIpos();
  }

  @override
  void dispose() {
    _companyIdController.dispose();
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
    } catch (e) {
      print('Error loading saved IPOs: $e');
      setState(() {
        _error = e.toString();
        _isLoadingSavedIpos = false;
      });
    }
  }

  Future<void> _addIpo() async {
    final companyId = _companyIdController.text.trim();
    if (companyId.isEmpty) {
      _showSnackBar('Please enter a company ID', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Starting to add IPO for company ID: $companyId');

      // Check if IPO already exists
      print('Checking if IPO exists...');
      final exists = await FirebaseService.ipoExistsByCompanyId(companyId);
      if (exists) {
        print('IPO already exists for company ID: $companyId');
        _showSnackBar('IPO with this company ID already exists', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch IPO data from API
      print('Fetching IPO data from API...');
      final ipo = await ApiService.getIpoByCompanyId(companyId);
      print('IPO data fetched successfully: ${ipo.companyName}');

      // Save to Firebase
      print('Saving IPO to Firebase...');
      await FirebaseService.addIpo(ipo);
      print('IPO saved to Firebase successfully');

      _showSnackBar('IPO added successfully');
      _companyIdController.clear();
      _loadSavedIpos();
    } catch (e) {
      print('Error adding IPO: $e');
      print('Error type: ${e.runtimeType}');
      _showSnackBar('Error adding IPO: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateIpo(IpoModel ipo) async {
    if (ipo.id == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch updated data from API
      final updatedIpo = await ApiService.getIpoByCompanyId(ipo.companyId);

      // Update in Firebase
      await FirebaseService.updateIpo(ipo.id!, updatedIpo);

      _showSnackBar('IPO updated successfully');
      _loadSavedIpos();
    } catch (e) {
      _showSnackBar('Error updating IPO: $e', isError: true);
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAddSection(),
          const Divider(),
          _buildSavedIposSection(),
        ],
      ),
    );
  }

  Widget _buildAddSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add New IPO',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _companyIdController,
                  decoration: const InputDecoration(
                    labelText: 'Company ID',
                    hintText: 'Enter company ID',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _addIpo,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved IPOs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: _loadSavedIpos,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildSavedIposList(),
          ),
        ],
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
      );
    }

    if (_savedIpos.isEmpty) {
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _savedIpos.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: IpoManagementCard(
            ipo: _savedIpos[index],
            onView: () => _showIpoDetails(_savedIpos[index]),
            onUpdate: () => _updateIpo(_savedIpos[index]),
            onDelete: () => _deleteIpo(_savedIpos[index]),
          ),
        );
      },
    );
  }

  void _showIpoDetails(IpoModel ipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ipo.companyName ?? 'IPO Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Company ID', ipo.companyId),
              _buildDetailRow('Sector', ipo.sector),
              _buildDetailRow('Industry', ipo.industry),
              _buildDetailRow('Issue Price', ipo.issuePrice?.toString()),
              _buildDetailRow('Issue Size', ipo.issueSize),
              _buildDetailRow('Listing Date', ipo.listingDate),
              _buildDetailRow('Open Date', ipo.openDate),
              _buildDetailRow('Close Date', ipo.closeDate),
              _buildDetailRow('Listing Price', ipo.listingPrice?.toString()),
              _buildDetailRow('Listing Gain', ipo.listingGain?.toString()),
              _buildDetailRow('Status', ipo.status),
              if (ipo.createdAt != null)
                _buildDetailRow('Added', ipo.createdAt.toString()),
              if (ipo.updatedAt != null)
                _buildDetailRow('Updated', ipo.updatedAt.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
