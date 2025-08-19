import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../widgets/bulk_add_ipo_modal.dart';
import '../widgets/document_links_modal.dart';

class ManagementTab extends StatefulWidget {
  const ManagementTab({super.key});

  @override
  State<ManagementTab> createState() => _ManagementTabState();
}

class _ManagementTabState extends State<ManagementTab> {
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

  Future<void> _manageDocumentLinks(IpoModel ipo) async {
    showDialog(
      context: context,
      builder: (context) => DocumentLinksModal(
        ipo: ipo,
        onSaved: () {
          Navigator.of(context).pop();
          _showSnackBar('Document links updated successfully');
          _loadSavedIpos(); // Reload to get updated data
        },
      ),
    );
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
      width: double.infinity,
      margin: const EdgeInsets.all(8),
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildSavedIposSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            padding: const EdgeInsets.all(6.0),
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
                    Icons.dashboard_customize_rounded,
                    size: 26,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Saved IPOs',
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
                    '${_savedIpos.length}',
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: _buildManagementDataTable(),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 8,
          horizontalMargin: 12,
          headingRowHeight: 56,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
          columns: const [
            DataColumn(
              label: SizedBox(
                width: 80,
                child: Text('IPO ID'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 150,
                child: Text('Company Name'),
              ),
            ),
            DataColumn(
              label: SizedBox(
                width: 120,
                child: Text('Actions'),
              ),
            ),
          ],
          rows: _savedIpos.map((ipo) {
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      ipo.companyId.isNotEmpty ? ipo.companyId : 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        ipo.companyName?.isNotEmpty == true
                            ? ipo.companyName!
                            : ipo.companyId.isNotEmpty
                                ? ipo.companyId
                                : 'Unknown Company',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            icon: const Icon(Icons.link),
                            color: Colors.blue,
                            onPressed: () => _manageDocumentLinks(ipo),
                            tooltip: 'Document Links',
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            color: Colors.orange,
                            onPressed: () => _updateIpo(ipo),
                            tooltip: 'Update',
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () => _deleteIpo(ipo),
                            tooltip: 'Delete',
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                          ),
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
