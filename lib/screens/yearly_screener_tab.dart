import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';
import '../widgets/ipo_card.dart';

class YearlyScreenerTab extends StatefulWidget {
  const YearlyScreenerTab({super.key});

  @override
  State<YearlyScreenerTab> createState() => _YearlyScreenerTabState();
}

class _YearlyScreenerTabState extends State<YearlyScreenerTab> {
  List<IpoModel> _ipos = [];
  List<int> _availableYears = [];
  int? _selectedYear;
  bool _isLoading = false;
  bool _isLoadingYears = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
  }

  Future<void> _loadAvailableYears() async {
    setState(() {
      _isLoadingYears = true;
    });

    try {
      final years = await ApiService.getAvailableYears();
      setState(() {
        _availableYears = years;
        _selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;
        _isLoadingYears = false;
      });
      
      if (_selectedYear != null) {
        _loadIposByYear(_selectedYear!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingYears = false;
        // Set default years if API fails
        final currentYear = DateTime.now().year;
        _availableYears = List.generate(5, (index) => currentYear - index);
        _selectedYear = currentYear;
      });
      
      if (_selectedYear != null) {
        _loadIposByYear(_selectedYear!);
      }
    }
  }

  Future<void> _loadIposByYear(int year) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ipos = await ApiService.getIposByYear(year);
      setState(() {
        _ipos = ipos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onYearChanged(int? year) {
    if (year != null && year != _selectedYear) {
      setState(() {
        _selectedYear = year;
      });
      _loadIposByYear(year);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildYearSelector(),
          const Divider(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IPO Screener',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Select Year:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _isLoadingYears
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: _availableYears.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: _onYearChanged,
                      ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _selectedYear != null
                    ? () => _loadIposByYear(_selectedYear!)
                    : null,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedYear != null
                  ? () => _loadIposByYear(_selectedYear!)
                  : null,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ipos.isEmpty) {
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
              'No IPOs found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedYear != null
                  ? 'No IPOs found for year $_selectedYear'
                  : 'Select a year to view IPOs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IPOs for $_selectedYear',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_ipos.length} IPOs',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadIposByYear(_selectedYear!),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _ipos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: IpoCard(
                    ipo: _ipos[index],
                    onTap: () => _showIpoDetails(_ipos[index]),
                    showYear: false, // Don't show year since we're filtering by year
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
