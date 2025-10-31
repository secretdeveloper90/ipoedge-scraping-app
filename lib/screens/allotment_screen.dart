import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/app_config.dart';
import '../widgets/allotment_data_table.dart';

class AllotmentScreen extends StatefulWidget {
  const AllotmentScreen({super.key});

  @override
  State<AllotmentScreen> createState() => _AllotmentScreenState();
}

class _AllotmentScreenState extends State<AllotmentScreen> {
  List<Map<String, dynamic>> _allotments = [];
  bool _isLoading = true;
  bool _isAddingAllotment = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllotments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addAllotedIPO() async {
    setState(() {
      _isAddingAllotment = true;
      _error = null;
    });

    try {
      // Fetch data from API
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/ipos/allotedipo-list'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> iposData = responseData['data'];

          // Store in Firebase
          await _storeInFirebase(iposData);

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Successfully added ${iposData.length} allotment records'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // Reload the data
          await _loadAllotments();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to add allotment data: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingAllotment = false;
        });
      }
    }
  }

  Future<void> _storeInFirebase(List<dynamic> iposData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Reference to the allotmentout_ipos collection
      final collectionRef = firestore.collection('allotmentout_ipos');

      // Clear existing data
      final existingDocs = await collectionRef.get();
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new data with order index to maintain sequence
      for (int i = 0; i < iposData.length; i++) {
        final ipoData = iposData[i];
        final docRef = collectionRef.doc();
        batch.set(docRef, {
          'ipoid': ipoData['ipoid'],
          'iponame': (ipoData['iponame'] ?? '').toString().toUpperCase(),
          'order': i, // Store the order index
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error storing data in Firebase: $e');
    }
  }

  Future<void> _loadAllotments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('allotmentout_ipos')
          .orderBy('order')
          .get();

      setState(() {
        _allotments = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'ipoid': doc['ipoid'] ?? '',
                  'iponame': doc['iponame'] ?? '',
                  'order': doc['order'] ?? 0,
                  'createdAt': doc['createdAt'],
                  'updatedAt': doc['updatedAt'],
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load allotments: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredAllotments() {
    if (_searchQuery.isEmpty) {
      return _allotments;
    }
    return _allotments.where((item) {
      final ipoName = (item['iponame'] ?? '').toString().toLowerCase();
      final ipoId = (item['ipoid'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      return ipoName.contains(searchLower) || ipoId.contains(searchLower);
    }).toList();
  }

  void _filterAllotments(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadAllotments,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildUpdateButton(),
            Expanded(child: _buildAllotmentsSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14,vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _isAddingAllotment ? null : _addAllotedIPO,
        icon: _isAddingAllotment
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.add_rounded),
        label: Text(
          _isAddingAllotment ? 'Adding...' : 'Add Alloted IPO',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildAllotmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchBar(),
        Expanded(
          child: _buildAllotmentsList(),
        ),
      ],
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
        onChanged: _filterAllotments,
        decoration: InputDecoration(
          hintText: 'Search by IPO name or ID...',
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
                    _filterAllotments('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAllotmentsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
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
                  'Error loading allotments',
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
                  onPressed: _loadAllotments,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_allotments.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
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
                  'No allotment data',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "Add Alloted IPO" to fetch data',
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

    final filteredAllotments = _getFilteredAllotments();

    if (filteredAllotments.isEmpty && _searchQuery.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No allotments found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search query',
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: constraints.maxHeight,
            child: AllotmentDataTable(allotments: filteredAllotments),
          ),
        );
      },
    );
  }
}
