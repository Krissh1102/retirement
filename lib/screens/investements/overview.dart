import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? portfolioData;
  final List<Map<String, dynamic>> holdings;
  final List<Map<String, dynamic>> transactions;
  final Function({String type, String? symbol}) onAddInvestment;

  const OverviewTab({
    Key? key,
    required this.portfolioData,
    required this.holdings,
    required this.transactions,
    required this.onAddInvestment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assetAllocation =
        portfolioData?['asset_allocation'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssetAllocationChart(assetAllocation),
          const SizedBox(height: 32),
          _buildPerformanceMetrics(),
          const SizedBox(height: 32),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Buy',
                    Icons.add_shopping_cart,
                    Colors.green,
                    () => onAddInvestment(type: 'buy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Sell',
                    Icons.remove_shopping_cart,
                    Colors.red,
                    () => onAddInvestment(type: 'sell'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Start SIP',
                    Icons.autorenew,
                    Colors.blue,
                    () => onAddInvestment(type: 'sip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Add Dividend',
                    Icons.payment,
                    Colors.orange,
                    () => onAddInvestment(type: 'dividend'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetAllocationChart(Map<String, dynamic>? allocation) {
    if (allocation == null || allocation.values.every((v) => (v as num) <= 0)) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'No asset allocation data',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Start investing to see your portfolio distribution',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    int index = 0;
    allocation.forEach((key, value) {
      if ((value as num) > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[index % colors.length],
            value: (value as num).toDouble(),
            title: '${value.toStringAsFixed(1)}%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        index++;
      }
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asset Allocation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 10,
                  sectionsSpace: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildAssetAllocationLegend(allocation, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetAllocationLegend(
    Map<String, dynamic> allocation,
    List<Color> colors,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children:
          allocation.entries.where((e) => e.value > 0).map((entry) {
            final index = allocation.keys
                .where((k) => allocation[k] > 0)
                .toList()
                .indexOf(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.key.toUpperCase()}: ${entry.value}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow('Total Holdings', '${holdings.length}'),
            _buildMetricRow('Total Transactions', '${transactions.length}'),
            _buildMetricRow(
              'Average Return',
              holdings.isEmpty
                  ? '0.00%'
                  : '${_calculateAverageReturn().toStringAsFixed(2)}%',
            ),
            _buildMetricRow(
              'Portfolio Diversification',
              _getDiversificationLevel(),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageReturn() {
    if (holdings.isEmpty) return 0.0;
    double totalReturn = 0;
    for (var holding in holdings) {
      totalReturn += (holding['return_percentage']?.toDouble() ?? 0);
    }
    return totalReturn / holdings.length;
  }

  String _getDiversificationLevel() {
    if (holdings.length >= 10) return 'High';
    if (holdings.length >= 5) return 'Moderate';
    if (holdings.length >= 2) return 'Low';
    return 'Very Low';
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
