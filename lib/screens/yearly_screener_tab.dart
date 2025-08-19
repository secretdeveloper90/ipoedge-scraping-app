import 'package:flutter/material.dart';
import '../models/ipo_model.dart';
import '../services/api_service.dart';

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

    // Set default years with current year as default
    final currentYear = DateTime.now().year;
    setState(() {
      _availableYears = List.generate(5, (index) => currentYear - index);
      _selectedYear = currentYear;
      _isLoadingYears = false;
    });

    if (_selectedYear != null) {
      _loadIposByYear(_selectedYear!);
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
      body: RefreshIndicator(
        onRefresh: () => _selectedYear != null
            ? _loadIposByYear(_selectedYear!)
            : Future.value(),
        color: Theme.of(context).primaryColor,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            _buildYearSelector(),
            const Divider(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
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
          ),
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
          child: _ipos.isEmpty
              ? SingleChildScrollView(
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
                            'No IPOs found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No IPOs available for the selected year',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildDataTable(),
                ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
        child: Container(
      width: double.infinity,
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
            minWidth: MediaQuery.of(context).size.width - 32,
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
                label: Text('Sr. No.'),
              ),
              DataColumn(
                label: Text('Company Name'),
              ),
            ],
            rows: _ipos.asMap().entries.map((entry) {
              final index = entry.key;
              final ipo = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      ipo.companyName ??
                          (ipo.companyId.isNotEmpty
                              ? ipo.companyId
                              : 'Unknown Company'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
