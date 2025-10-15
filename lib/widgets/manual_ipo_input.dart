import 'package:flutter/material.dart';

class ManualIpoInput extends StatefulWidget {
  final List<String> ipoIds;
  final Function(List<String>) onIpoIdsChanged;
  final bool enabled;

  const ManualIpoInput({
    super.key,
    required this.ipoIds,
    required this.onIpoIdsChanged,
    this.enabled = true,
  });

  @override
  State<ManualIpoInput> createState() => _ManualIpoInputState();
}

class _ManualIpoInputState extends State<ManualIpoInput> {
  final TextEditingController _textController = TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.ipoIds.join(', ');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseAndValidateInput(String input) {
    setState(() {
      _errorText = null;
    });

    if (input.trim().isEmpty) {
      widget.onIpoIdsChanged([]);
      return;
    }

    // Parse input - support both comma-separated and line-separated
    List<String> rawIds = [];

    // First try comma separation
    if (input.contains(',')) {
      rawIds = input.split(',');
    } else {
      // Try line separation
      rawIds = input.split('\n');
    }

    // Clean and validate IDs
    final cleanIds = <String>[];
    final invalidIds = <String>[];
    final duplicateIds = <String>[];
    final seenIds = <String>{};

    for (final rawId in rawIds) {
      final cleanId = rawId.trim();
      if (cleanId.isEmpty) continue;

      // Basic validation - check if it looks like a valid ID
      if (!_isValidIpoId(cleanId)) {
        invalidIds.add(cleanId);
        continue;
      }

      // Check for duplicates
      if (seenIds.contains(cleanId)) {
        if (!duplicateIds.contains(cleanId)) {
          duplicateIds.add(cleanId);
        }
        continue;
      }

      seenIds.add(cleanId);
      cleanIds.add(cleanId);
    }

    // Set error message if there are issues
    if (invalidIds.isNotEmpty || duplicateIds.isNotEmpty) {
      final errors = <String>[];
      if (invalidIds.isNotEmpty) {
        errors.add(
            'Invalid IDs: ${invalidIds.take(3).join(', ')}${invalidIds.length > 3 ? '...' : ''}');
      }
      if (duplicateIds.isNotEmpty) {
        errors.add(
            'Duplicate IDs: ${duplicateIds.take(3).join(', ')}${duplicateIds.length > 3 ? '...' : ''}');
      }
      setState(() {
        _errorText = errors.join('\n');
      });
    }

    widget.onIpoIdsChanged(cleanIds);
  }

  bool _isValidIpoId(String id) {
    // Basic validation - should not be empty and should contain alphanumeric characters
    if (id.isEmpty) return false;

    // Check if it contains only valid characters (letters, numbers, hyphens, underscores)
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!validPattern.hasMatch(id)) return false;

    // Should be reasonable length
    if (id.length < 2 || id.length > 50) return false;

    return true;
  }

  void _clearInput() {
    _textController.clear();
    widget.onIpoIdsChanged([]);
    setState(() {
      _errorText = null;
    });
  }

  void _showInputHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Format Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can enter multiple IPO IDs in the following formats:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Text('• Comma-separated:'),
            Text(
              'company1, company2, company3',
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0xFFF5F5F5),
              ),
            ),
            SizedBox(height: 12),
            Text('• Line-separated:'),
            Text(
              'company1\ncompany2\ncompany3',
              style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: Color(0xFFF5F5F5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Note: Duplicate IDs will be automatically removed.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header with title and help button
      Row(
        children: [
          Expanded(
            child: Text(
              'Manual IPO ID Entry',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            onPressed: _showInputHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Input format help',
            iconSize: 20,
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Input field
      Expanded(
        child: TextField(
          controller: _textController,
          enabled: widget.enabled,
          maxLines: null,
          expands: true,
          decoration: InputDecoration(
            labelText: 'IPO IDs',
            hintText:
                'Enter IPO IDs separated by commas or new lines\nExample: company1, company2, company3',
            border: const OutlineInputBorder(),
            errorText: _errorText,
            errorMaxLines: 3,
            suffixIcon: _textController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.enabled ? _clearInput : null,
                    tooltip: 'Clear all',
                  )
                : null,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: _parseAndValidateInput,
        ),
      ),
      const SizedBox(height: 12),

      // Summary
      if (widget.ipoIds.isNotEmpty) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _errorText != null
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorText != null
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _errorText != null ? Icons.warning : Icons.check_circle,
                color: _errorText != null ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.ipoIds.length} valid IPO ID${widget.ipoIds.length == 1 ? '' : 's'} entered',
                  style: TextStyle(
                    color: _errorText != null
                        ? Colors.orange[700]
                        : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show parsed IDs if there are any
        if (widget.ipoIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Parsed IDs:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.ipoIds
                  .map((id) => Chip(
                        label: Text(
                          id,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                        side: BorderSide(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    ]);
  }
}
