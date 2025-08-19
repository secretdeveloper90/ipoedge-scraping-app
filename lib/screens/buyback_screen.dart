import 'package:flutter/material.dart';

class BuybackScreen extends StatefulWidget {
  const BuybackScreen({super.key});

  @override
  State<BuybackScreen> createState() => _BuybackScreenState();
}

class _BuybackScreenState extends State<BuybackScreen> {
  List<BuybackItem> _buybacks = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'All';

  final List<String> _statusOptions = ['All', 'Announced', 'Open', 'Closed', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadBuybacks();
  }

  Future<void> _loadBuybacks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API call - replace with actual Firebase/API integration
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data for demonstration
      final mockBuybacks = [
        BuybackItem(
          id: '1',
          companyName: 'TCS Limited',
          buybackPrice: 4500.0,
          marketPrice: 4200.0,
          totalAmount: 18000.0,
          recordDate: DateTime.now().add(const Duration(days: 5)),
          openDate: DateTime.now().add(const Duration(days: 10)),
          closeDate: DateTime.now().add(const Duration(days: 40)),
          status: BuybackStatus.announced,
          acceptanceRatio: null,
        ),
        BuybackItem(
          id: '2',
          companyName: 'Infosys Limited',
          buybackPrice: 1850.0,
          marketPrice: 1750.0,
          totalAmount: 9200.0,
          recordDate: DateTime.now().subtract(const Duration(days: 5)),
          openDate: DateTime.now().subtract(const Duration(days: 2)),
          closeDate: DateTime.now().add(const Duration(days: 28)),
          status: BuybackStatus.open,
          acceptanceRatio: null,
        ),
        BuybackItem(
          id: '3',
          companyName: 'Wipro Limited',
          buybackPrice: 650.0,
          marketPrice: 580.0,
          totalAmount: 12000.0,
          recordDate: DateTime.now().subtract(const Duration(days: 45)),
          openDate: DateTime.now().subtract(const Duration(days: 40)),
          closeDate: DateTime.now().subtract(const Duration(days: 10)),
          status: BuybackStatus.closed,
          acceptanceRatio: 85.5,
        ),
        BuybackItem(
          id: '4',
          companyName: 'HCL Technologies',
          buybackPrice: 1200.0,
          marketPrice: 1100.0,
          totalAmount: 6000.0,
          recordDate: DateTime.now().subtract(const Duration(days: 90)),
          openDate: DateTime.now().subtract(const Duration(days: 85)),
          closeDate: DateTime.now().subtract(const Duration(days: 55)),
          status: BuybackStatus.completed,
          acceptanceRatio: 92.3,
        ),
      ];

      setState(() {
        _buybacks = mockBuybacks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<BuybackItem> get _filteredBuybacks {
    if (_filterStatus == 'All') {
      return _buybacks;
    }
    return _buybacks.where((buyback) => 
        buyback.status.name.toLowerCase() == _filterStatus.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadBuybacks,
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusFilter(),
            const Divider(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBuybackDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    final filteredCount = _filteredBuybacks.length;
    
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
              Icons.account_balance_wallet_rounded,
              size: 26,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Buybacks',
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
              '$filteredCount',
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

  Widget _buildStatusFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusOptions.length,
        itemBuilder: (context, index) {
          final status = _statusOptions[index];
          final isSelected = status == _filterStatus;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filterStatus = status;
                });
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
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
                Text('Error loading buybacks',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadBuybacks,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredBuybacks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, 
                     size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No buybacks available',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Check back later for updates',
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
      itemCount: _filteredBuybacks.length,
      itemBuilder: (context, index) {
        final buyback = _filteredBuybacks[index];
        return _buildBuybackCard(buyback);
      },
    );
  }

  Widget _buildBuybackCard(BuybackItem buyback) {
    final premium = ((buyback.buybackPrice - buyback.marketPrice) / buyback.marketPrice) * 100;
    
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
                    buyback.companyName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(buyback.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    buyback.status.name.toUpperCase(),
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
                Expanded(
                  child: _buildInfoItem(
                    'Buyback Price',
                    '₹${buyback.buybackPrice.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Market Price',
                    '₹${buyback.marketPrice.toStringAsFixed(0)}',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Premium',
                    '${premium.toStringAsFixed(1)}%',
                    Icons.percent,
                    color: premium > 0 ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Total Amount',
                    '₹${buyback.totalAmount.toStringAsFixed(0)} Cr',
                    Icons.account_balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDateInfo('Record Date', buyback.recordDate),
            _buildDateInfo('Open Date', buyback.openDate),
            _buildDateInfo('Close Date', buyback.closeDate),
            if (buyback.acceptanceRatio != null) ...[
              const SizedBox(height: 8),
              _buildInfoItem(
                'Acceptance Ratio',
                '${buyback.acceptanceRatio!.toStringAsFixed(1)}%',
                Icons.check_circle,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuybackStatus status) {
    switch (status) {
      case BuybackStatus.announced:
        return Colors.blue;
      case BuybackStatus.open:
        return Colors.green;
      case BuybackStatus.closed:
        return Colors.orange;
      case BuybackStatus.completed:
        return Colors.grey;
    }
  }

  void _showAddBuybackDialog() {
    // TODO: Implement add buyback dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add buyback functionality coming soon')),
    );
  }
}

enum BuybackStatus { announced, open, closed, completed }

class BuybackItem {
  final String id;
  final String companyName;
  final double buybackPrice;
  final double marketPrice;
  final double totalAmount;
  final DateTime recordDate;
  final DateTime openDate;
  final DateTime closeDate;
  final BuybackStatus status;
  final double? acceptanceRatio;

  BuybackItem({
    required this.id,
    required this.companyName,
    required this.buybackPrice,
    required this.marketPrice,
    required this.totalAmount,
    required this.recordDate,
    required this.openDate,
    required this.closeDate,
    required this.status,
    this.acceptanceRatio,
  });
}
