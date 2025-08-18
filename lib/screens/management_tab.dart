import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';

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
                  'Saved IPOs (${_savedIpos.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                IconButton(
                  onPressed: _loadSavedIpos,
                  icon: const Icon(Icons.refresh, size: 24),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildManagementDataTable(),
    );
  }

  Widget _buildManagementDataTable() {
    return SingleChildScrollView(
        child: Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:
                MediaQuery.of(context).size.width - 32, // Account for padding
          ),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 16,
            headingRowHeight: 50,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 48,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              fontSize: 16,
            ),
            columns: const [
              DataColumn(
                label: Text('IPO ID'),
              ),
              DataColumn(
                label: Text('Company Name'),
              ),
              DataColumn(
                label: Text('Actions'),
              ),
            ],
            rows: _savedIpos.map((ipo) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      ipo.companyId.isNotEmpty ? ipo.companyId : 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ipo.companyName?.isNotEmpty == true
                          ? ipo.companyName!
                          : ipo.companyId.isNotEmpty
                              ? ipo.companyId
                              : 'Unknown Company',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: Colors.orange,
                          onPressed: () => _updateIpo(ipo),
                          tooltip: 'Update',
                          iconSize: 20,
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _deleteIpo(ipo),
                          tooltip: 'Delete',
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    ));
  }
}
