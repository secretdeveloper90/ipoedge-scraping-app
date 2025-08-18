import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class MultiSelectIpoDropdown extends StatefulWidget {
  final List<IpoOption> selectedOptions;
  final Function(List<IpoOption>) onSelectionChanged;
  final bool enabled;

  const MultiSelectIpoDropdown({
    super.key,
    required this.selectedOptions,
    required this.onSelectionChanged,
    this.enabled = true,
  });

  @override
  State<MultiSelectIpoDropdown> createState() => _MultiSelectIpoDropdownState();
}

class _MultiSelectIpoDropdownState extends State<MultiSelectIpoDropdown> {
  List<IpoOption> _availableOptions = [];
  List<IpoOption> _filteredOptions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAvailableOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableOptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final options = await FirebaseService.getAvailableIpoOptions();
      setState(() {
        _availableOptions = options;
        _filteredOptions = options;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading IPO options: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterOptions(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredOptions = _availableOptions;
      } else {
        _filteredOptions = _availableOptions
            .where((option) =>
                option.companyName
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                option.companyId.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSelection(IpoOption option) {
    if (!widget.enabled) return;

    final newSelection = List<IpoOption>.from(widget.selectedOptions);
    if (newSelection.contains(option)) {
      newSelection.remove(option);
    } else {
      newSelection.add(option);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _selectAll() {
    if (!widget.enabled) return;
    widget.onSelectionChanged(List<IpoOption>.from(_filteredOptions));
  }

  void _clearAll() {
    if (!widget.enabled) return;
    widget.onSelectionChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Action buttons - centered and compact
        if (!_isLoading && _filteredOptions.isNotEmpty) ...[
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.enabled ? _selectAll : null,
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Select All'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(fontSize: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: widget.enabled ? _clearAll : null,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 32),
                    textStyle: const TextStyle(fontSize: 12),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Search field
        TextField(
          controller: _searchController,
          enabled: widget.enabled && !_isLoading,
          decoration: InputDecoration(
            labelText: 'Search IPOs',
            hintText: 'Search by company name or ID',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterOptions('');
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: _filterOptions,
        ),
        const SizedBox(height: 4),

        // Selection summary
        if (widget.selectedOptions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.selectedOptions.length} IPO${widget.selectedOptions.length == 1 ? '' : 's'} selected',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Options list with flexible height
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildOptionsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading available IPOs...'),
          ],
        ),
      );
    }

    if (_filteredOptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No IPOs found matching "$_searchQuery"'
                  : 'No IPOs available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterOptions('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _filteredOptions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 2), // Minimal spacing
      itemBuilder: (context, index) {
        final option = _filteredOptions[index];
        final isSelected = widget.selectedOptions.contains(option);

        return CheckboxListTile(
          value: isSelected,
          onChanged: widget.enabled ? (_) => _toggleSelection(option) : null,
          title: Text(
            option.companyName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14, // Slightly smaller font
            ),
          ),
          subtitle: Text(
            'ID: ${option.companyId}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11, // Smaller subtitle
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 0, // Remove vertical padding
          ),
          visualDensity: VisualDensity.compact, // More compact layout
        );
      },
    );
  }
}
