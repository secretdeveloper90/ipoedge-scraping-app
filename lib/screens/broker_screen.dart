import 'package:flutter/material.dart';

class BrokerScreen extends StatefulWidget {
  const BrokerScreen({super.key});

  @override
  State<BrokerScreen> createState() => _BrokerScreenState();
}

class _BrokerScreenState extends State<BrokerScreen> {
  List<BrokerItem> _brokers = [];
  bool _isLoading = true;
  String? _error;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call - replace with actual Firebase/API integration
      await Future.delayed(const Duration(seconds: 1));

      // Mock data for demonstration
      final mockBrokers = [
        BrokerItem(
          id: '1',
          name: 'Zerodha',
          type: BrokerType.discount,
          rating: 4.5,
          brokerage: 20.0,
          accountOpeningFee: 0.0,
          features: [
            'Zero brokerage on equity delivery',
            'Advanced trading platform',
            '24/7 support'
          ],
          isActive: true,
          website: 'https://zerodha.com',
        ),
        BrokerItem(
          id: '2',
          name: 'HDFC Securities',
          type: BrokerType.fullService,
          rating: 4.2,
          brokerage: 0.5,
          accountOpeningFee: 999.0,
          features: ['Research reports', 'Advisory services', 'Branch network'],
          isActive: true,
          website: 'https://hdfcsec.com',
        ),
        BrokerItem(
          id: '3',
          name: 'Upstox',
          type: BrokerType.discount,
          rating: 4.1,
          brokerage: 20.0,
          accountOpeningFee: 0.0,
          features: ['Low brokerage', 'Mobile app', 'API access'],
          isActive: true,
          website: 'https://upstox.com',
        ),
        BrokerItem(
          id: '4',
          name: 'Angel Broking',
          type: BrokerType.fullService,
          rating: 3.9,
          brokerage: 0.25,
          accountOpeningFee: 500.0,
          features: ['Research', 'Advisory', 'Multiple platforms'],
          isActive: false,
          website: 'https://angelbroking.com',
        ),
      ];

      setState(() {
        _brokers = mockBrokers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<BrokerItem> get _sortedBrokers {
    final brokers = List<BrokerItem>.from(_brokers);
    switch (_sortBy) {
      case 'name':
        brokers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        brokers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'brokerage':
        brokers.sort((a, b) => a.brokerage.compareTo(b.brokerage));
        break;
    }
    return brokers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBrokers,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            _buildSortOptions(),
            const Divider(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBrokerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              Icons.business_rounded,
              size: 26,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Brokers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.3,
                    fontSize: 18,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              '${_brokers.length}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Name', 'name'),
                  const SizedBox(width: 8),
                  _buildSortChip('Rating', 'rating'),
                  const SizedBox(width: 8),
                  _buildSortChip('Brokerage', 'brokerage'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error loading brokers',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadBrokers,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_brokers.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.business_outlined,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No brokers available',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Add brokers to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        )),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _sortedBrokers.length,
      itemBuilder: (context, index) {
        final broker = _sortedBrokers[index];
        return _buildBrokerCard(broker);
      },
    );
  }

  Widget _buildBrokerCard(BrokerItem broker) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    broker.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBrokerTypeColor(broker.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    broker.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: broker.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    broker.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${broker.rating}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  broker.type == BrokerType.discount
                      ? '₹${broker.brokerage.toStringAsFixed(0)} per trade'
                      : '${broker.brokerage}% of trade value',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Account Opening Fee: ₹${broker.accountOpeningFee.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Features:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: broker.features
                  .map((feature) => Chip(
                        label: Text(
                          feature,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Open website
                    },
                    child: const Text('Visit Website'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Edit broker
                    },
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBrokerTypeColor(BrokerType type) {
    switch (type) {
      case BrokerType.discount:
        return Colors.blue;
      case BrokerType.fullService:
        return Colors.green;
    }
  }

  void _showAddBrokerDialog() {
    // TODO: Implement add broker dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add broker functionality coming soon')),
    );
  }
}

enum BrokerType { discount, fullService }

class BrokerItem {
  final String id;
  final String name;
  final BrokerType type;
  final double rating;
  final double brokerage;
  final double accountOpeningFee;
  final List<String> features;
  final bool isActive;
  final String website;

  BrokerItem({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.brokerage,
    required this.accountOpeningFee,
    required this.features,
    required this.isActive,
    required this.website,
  });
}
