import 'package:flutter/material.dart';
import '../models/new_ipo_model.dart';
import '../services/api_service.dart';
import '../widgets/ipo_data_table.dart';
import '../services/firebase_service.dart';
import '../utils/snackbar_utils.dart';

class SmeCurrentTab extends StatefulWidget {
  const SmeCurrentTab({super.key});

  @override
  State<SmeCurrentTab> createState() => _SmeCurrentTabState();
}

class _SmeCurrentTabState extends State<SmeCurrentTab> {
  List<NewIpoModel> _savedIpos = [];
  List<NewIpoModel> _filteredIpos = [];
  List<NewIpoModel> _selectedIpos = [];
  bool _isLoading = false;
  bool _isLoadingSavedIpos = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    if (!mounted) return;

    setState(() {
      _isLoadingSavedIpos = true;
      _error = null;
    });

    try {
      if (!FirebaseService.isAvailable) {
        if (!mounted) return;
        setState(() {
          _error = 'Firebase not available. Please check your configuration.';
          _isLoadingSavedIpos = false;
        });
        return;
      }

      // Load IPOs from Firebase ipo_management collection
      final iposData = await FirebaseService.getIposFromManagement(
        ipoType: 'sme',
        category: 'live',
      );

      // Convert Firebase data to NewIpoModel
      final ipos = iposData.map((data) => NewIpoModel.fromJson(data)).toList();

      if (!mounted) return;
      setState(() {
        _savedIpos = ipos;
        _filteredIpos = _searchQuery.isEmpty
            ? ipos
            : ipos.where((ipo) {
                final companyName = (ipo.companyName ?? '').toLowerCase();
                final symbol = (ipo.symbol ?? '').toLowerCase();
                final searchLower = _searchQuery.toLowerCase();
                return companyName.contains(searchLower) ||
                    symbol.contains(searchLower);
              }).toList();
        _isLoadingSavedIpos = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingSavedIpos = false;
        _savedIpos = [];
        _filteredIpos = [];
      });
    }
  }

  Future<void> _fetchIposFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch IPOs from API with type 'sme' and category 'live'
      final ipos = await ApiService.getNewIpoList(
        ipoType: 'sme',
        category: 'live',
      );

      // Store IPOs in Firebase ipo_management collection
      if (FirebaseService.isAvailable) {
        // Clear all existing IPOs from this category first
        await FirebaseService.clearAllIposFromManagement(
          ipoType: 'sme',
          category: 'live',
        );

        int successCount = 0;
        int failedCount = 0;

        // Add all new IPOs
        for (int index = 0; index < ipos.length; index++) {
          final ipo = ipos[index];
          try {
            // Convert NewIpoModel to JSON
            final ipoJson = ipo.toJson();

            // Add new IPO with order index
            await FirebaseService.addIpoToManagement(
              ipoData: ipoJson,
              ipoType: 'sme',
              category: 'live',
              orderIndex: index,
            );
            successCount++;
          } catch (e) {
            failedCount++;
          }
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        SnackbarUtils.showSnackBar(
          context,
          'Fetched ${ipos.length} IPOs. Added: $successCount, Failed: $failedCount',
        );

        // Reload data from Firebase to display in table
        await _loadSavedIpos();
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        SnackbarUtils.showSnackBar(
          context,
          'Fetched ${ipos.length} SME IPOs (Firebase not available)',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      SnackbarUtils.showSnackBar(
        context,
        'Error fetching IPOs: $e',
        isError: true,
      );
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
          final symbol = (ipo.symbol ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return companyName.contains(searchLower) ||
              symbol.contains(searchLower);
        }).toList();
      }
    });
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
            _buildActionButtons(),
            _buildSearchBar(),
            Expanded(child: _buildIposList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _fetchIposFromApi,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_circle, size: 20),
        label: Text(
          _isLoading ? 'Adding...' : 'Add IPOs',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isLoading ? Colors.grey : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          minimumSize: const Size(double.infinity, 44),
        ),
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterIpos,
        decoration: InputDecoration(
          hintText: 'Search SME IPOs...',
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
      ),
    );
  }

  Widget _buildIposList() {
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
              'Error loading IPOs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
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

    if (_filteredIpos.isEmpty) {
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
              _searchQuery.isNotEmpty ? 'No IPOs found' : 'No current SME IPOs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Click "Add IPOs" to fetch data',
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
      child: IpoDataTable(
        key: ValueKey('sme_live_${_filteredIpos.length}'),
        ipos: _filteredIpos,
        ipoType: 'sme',
        category: 'live',
        onEdit: (ipo) {
          SnackbarUtils.showSnackBar(context, 'Edit functionality coming soon');
        },
        onSelectionChanged: (selectedIpos) {
          setState(() {
            _selectedIpos = selectedIpos;
          });
          if (selectedIpos.isNotEmpty) {
            SnackbarUtils.showSnackBar(
                context, '${selectedIpos.length} IPO(s) selected');
          }
        },
        onDataUpdated: _loadSavedIpos,
      ),
    );
  }
}
