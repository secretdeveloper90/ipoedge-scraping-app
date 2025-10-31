import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

class AllotmentDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> allotments;

  const AllotmentDataTable({
    super.key,
    required this.allotments,
  });

  @override
  Widget build(BuildContext context) {
    if (allotments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DataTable2(
          columnSpacing: 0,
          horizontalMargin: 0,
          headingRowHeight: 40,
          dataRowHeight: 48,
          fixedTopRows: 1,
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
          columns: [
            DataColumn2(
              size: ColumnSize.S,
              fixedWidth: 70,
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: const Text('Sr. No'),
              ),
            ),
            DataColumn2(
              size: ColumnSize.L,
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text('IPO Name ( Total : ${allotments.length} )'),
              ),
            ),
          ],
          rows: allotments.asMap().entries.map((entry) {
            final index = entry.key;
            final allotment = entry.value;
            return DataRow2(
              cells: [
                DataCell(
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      allotment['iponame'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
