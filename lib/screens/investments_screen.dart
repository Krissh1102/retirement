import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:retierment/screens/investements/holdings.dart';
import 'package:retierment/screens/investements/overview.dart';
import 'package:retierment/screens/investements/transaction.dart';
import 'package:retierment/services/questions_data.dart';
import 'package:retierment/widgets/formatters.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  late TabController _tabController;

  Map<String, dynamic>? portfolioData;
  List<Map<String, dynamic>> holdings = [];
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInvestmentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvestmentData() async {
    try {
      final userData = await _firebaseService.loadUserProfile();

      if (!mounted) return; // ✅ Prevent setState after dispose

      if (userData != null && userData['investments'] != null) {
        setState(() {
          portfolioData = userData['investments']['portfolio_summary'];
          holdings = List<Map<String, dynamic>>.from(
            userData['investments']['holdings']?['holdings'] ?? [],
          );
          transactions = List<Map<String, dynamic>>.from(
            userData['investments']['transactions']?['transactions'] ?? [],
          );
          isLoading = false;
        });
      } else {
        setState(() {
          portfolioData = {
            'current_value': 0.0,
            'total_invested': 0.0,
            'total_returns': 0.0,
            'returns_percentage': 0.0,
            'monthly_sip': 0.0,
            'asset_allocation': {
              'equity': 0,
              'debt': 0,
              'gold': 0,
              'others': 0,
            },
          };
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading investment data: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    await _loadInvestmentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Investment Portfolio',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart, color: Colors.white),
            onPressed: () => _showAddInvestmentBottomSheet(),
            tooltip: 'Add Investment',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _refreshData,
                child: Column(
                  children: [
                    _buildPortfolioSummary(),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTabBar(),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Use the new tab widgets
                                OverviewTab(
                                  portfolioData: portfolioData,
                                  holdings: holdings,
                                  transactions: transactions,
                                  onAddInvestment:
                                      _showAddInvestmentBottomSheet,
                                ),
                                HoldingsTab(
                                  holdings: holdings,
                                  onShowDetails: _showHoldingDetails,
                                  onAddInvestment:
                                      _showAddInvestmentBottomSheet,
                                ),
                                TransactionsTab(transactions: transactions),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPortfolioSummary() {
    final currentValue = portfolioData?['current_value']?.toDouble() ?? 0.0;
    final totalInvested = portfolioData?['total_invested']?.toDouble() ?? 0.0;
    final totalReturns = portfolioData?['total_returns']?.toDouble() ?? 0.0;
    final returnsPercentage =
        portfolioData?['returns_percentage']?.toDouble() ?? 0.0;
    final monthlySip = portfolioData?['monthly_sip']?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3F51B5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      returnsPercentage >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${returnsPercentage >= 0 ? '+' : ''}${returnsPercentage.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Current Value',
                  '₹${formatAmount(currentValue)}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Invested',
                  '₹${formatAmount(totalInvested)}',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Returns',
                  '₹${formatAmount(totalReturns)}',
                  Icons.show_chart,
                  isReturn: true,
                  returnValue: totalReturns,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Monthly SIP',
                  '₹${formatAmount(monthlySip)}',
                  Icons.autorenew,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon, {
    bool isReturn = false,
    double returnValue = 0,
  }) {
    Color cardColor = Colors.white.withOpacity(0.1);
    Color textColor = Colors.white;

    if (isReturn) {
      cardColor =
          returnValue >= 0
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF1A237E),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Holdings'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  void _showHoldingDetails(Map<String, dynamic> holding) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1A237E),
                      radius: 24,
                      child: Text(
                        holding['symbol']?.substring(0, 2).toUpperCase() ??
                            'NA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            holding['symbol'] ?? '',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildDetailRow('Quantity', '${holding['quantity'] ?? 0}'),
                _buildDetailRow(
                  'Average Price',
                  '₹${holding['avg_price'] ?? 0}',
                ),
                _buildDetailRow(
                  'Current Value',
                  '₹${formatAmount(holding['current_value']?.toDouble() ?? 0)}',
                ),
                _buildDetailRow(
                  'Returns',
                  '${(holding['return_percentage']?.toDouble() ?? 0) >= 0 ? '+' : ''}${(holding['return_percentage']?.toDouble() ?? 0).toStringAsFixed(2)}%',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddInvestmentBottomSheet(
                            type: 'buy',
                            symbol: holding['symbol'],
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Buy More'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddInvestmentBottomSheet(
                            type: 'sell',
                            symbol: holding['symbol'],
                          );
                        },
                        icon: const Icon(Icons.remove),
                        label: const Text('Sell'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  void _showAddInvestmentBottomSheet({String type = 'buy', String? symbol}) {
    final symbolController = TextEditingController(text: symbol ?? '');
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String selectedType = type;
    String selectedCategory = 'equity';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add Investment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Transaction Type',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Buy'),
                              selected: selectedType == 'buy',
                              onSelected: (selected) {
                                setModalState(() => selectedType = 'buy');
                              },
                              selectedColor: Colors.green.withOpacity(0.3),
                            ),
                            ChoiceChip(
                              label: const Text('Sell'),
                              selected: selectedType == 'sell',
                              onSelected: (selected) {
                                setModalState(() => selectedType = 'sell');
                              },
                              selectedColor: Colors.red.withOpacity(0.3),
                            ),
                            ChoiceChip(
                              label: const Text('SIP'),
                              selected: selectedType == 'sip',
                              onSelected: (selected) {
                                setModalState(() => selectedType = 'sip');
                              },
                              selectedColor: Colors.blue.withOpacity(0.3),
                            ),
                            ChoiceChip(
                              label: const Text('Dividend'),
                              selected: selectedType == 'dividend',
                              onSelected: (selected) {
                                setModalState(() => selectedType = 'dividend');
                              },
                              selectedColor: Colors.orange.withOpacity(0.3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Equity'),
                              selected: selectedCategory == 'equity',
                              onSelected: (selected) {
                                setModalState(
                                  () => selectedCategory = 'equity',
                                );
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Debt'),
                              selected: selectedCategory == 'debt',
                              onSelected: (selected) {
                                setModalState(() => selectedCategory = 'debt');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Gold'),
                              selected: selectedCategory == 'gold',
                              onSelected: (selected) {
                                setModalState(() => selectedCategory = 'gold');
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Others'),
                              selected: selectedCategory == 'others',
                              onSelected: (selected) {
                                setModalState(
                                  () => selectedCategory = 'others',
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: symbolController,
                          decoration: InputDecoration(
                            labelText: 'Symbol/Ticker *',
                            hintText: 'e.g., RELIANCE, INFY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.code),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Investment Name *',
                            hintText: 'e.g., Reliance Industries Ltd',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.business),
                          ),
                        ),
                        if (selectedType != 'dividend')
                          const SizedBox(height: 16),
                        if (selectedType != 'dividend')
                          TextField(
                            controller: quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              hintText: 'Number of units',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: priceController,
                          decoration: InputDecoration(
                            labelText:
                                selectedType == 'dividend'
                                    ? 'Dividend Amount *'
                                    : 'Price per Unit *',
                            hintText:
                                selectedType == 'dividend'
                                    ? 'Total dividend received'
                                    : 'Price in ₹',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.currency_rupee),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            labelText: 'Date *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              dateController.text = DateFormat(
                                'yyyy-MM-dd',
                              ).format(date);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    () => _saveInvestment(
                                      selectedType,
                                      selectedCategory,
                                      symbolController.text,
                                      nameController.text,
                                      quantityController.text,
                                      priceController.text,
                                      dateController.text,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Future<void> _saveInvestment(
    String type,
    String category,
    String symbol,
    String name,
    String quantity,
    String price,
    String date,
  ) async {
    if (symbol.isEmpty || name.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (type != 'dividend' && quantity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter quantity')));
      return;
    }

    try {
      final qty = type == 'dividend' ? 0.0 : double.parse(quantity);
      final prc = double.parse(price);
      final amount = type == 'dividend' ? prc : qty * prc;

      final userData = await _firebaseService.loadUserProfile();

      if (userData?['investments'] == null) {
        userData!['investments'] = {
          'portfolio_summary': {
            'current_value': 0.0,
            'total_invested': 0.0,
            'total_returns': 0.0,
            'returns_percentage': 0.0,
            'monthly_sip': 0.0,
            'asset_allocation': {
              'equity': 0,
              'debt': 0,
              'gold': 0,
              'others': 0,
            },
          },
          'holdings': {'holdings': []},
          'transactions': {'transactions': []},
        };
      }

      final transaction = {
        'type': type,
        'symbol': symbol.toUpperCase(),
        'description': '$name - ${type.toUpperCase()}',
        'amount': amount,
        'quantity': qty,
        'price': prc,
        'timestamp': date,
        'category': category,
      };

      final transactions = List<Map<String, dynamic>>.from(
        userData?['investments']['transactions']?['transactions'] ?? [],
      );
      transactions.insert(0, transaction);
      userData?['investments']['transactions']['transactions'] = transactions;

      final holdings = List<Map<String, dynamic>>.from(
        userData?['investments']['holdings']?['holdings'] ?? [],
      );

      if (type == 'buy' || type == 'sip') {
        final existingIndex = holdings.indexWhere(
          (h) => h['symbol'] == symbol.toUpperCase(),
        );
        if (existingIndex >= 0) {
          final existing = holdings[existingIndex];
          final existingQty = (existing['quantity'] ?? 0.0).toDouble();
          final existingAvg = (existing['avg_price'] ?? 0.0).toDouble();
          final newQty = existingQty + qty;
          final newAvg = ((existingQty * existingAvg) + (qty * prc)) / newQty;
          holdings[existingIndex] = {
            'symbol': symbol.toUpperCase(),
            'name': name,
            'quantity': newQty,
            'avg_price': newAvg,
            'current_value': newQty * prc,
            'return_percentage': ((prc - newAvg) / newAvg) * 100,
            'category': category,
          };
        } else {
          holdings.add({
            'symbol': symbol.toUpperCase(),
            'name': name,
            'quantity': qty,
            'avg_price': prc,
            'current_value': amount,
            'return_percentage': 0.0,
            'category': category,
          });
        }
      } else if (type == 'sell') {
        final existingIndex = holdings.indexWhere(
          (h) => h['symbol'] == symbol.toUpperCase(),
        );
        if (existingIndex >= 0) {
          final existing = holdings[existingIndex];
          final existingQty = (existing['quantity'] ?? 0.0).toDouble();
          final newQty = existingQty - qty;
          if (newQty > 0) {
            holdings[existingIndex]['quantity'] = newQty;
            holdings[existingIndex]['current_value'] =
                newQty * existing['avg_price'];
          } else {
            holdings.removeAt(existingIndex);
          }
        }
      }
      userData?['investments']['holdings']['holdings'] = holdings;

      double totalInvested = 0;
      double currentValue = 0;
      Map<String, int> assetAllocation = {
        'equity': 0,
        'debt': 0,
        'gold': 0,
        'others': 0,
      };

      for (var holding in holdings) {
        final invested =
            (holding['quantity'] ?? 0.0) * (holding['avg_price'] ?? 0.0);
        final current = holding['current_value']?.toDouble() ?? 0.0;
        totalInvested += invested;
        currentValue += current;
        final cat = holding['category'] ?? 'others';
        assetAllocation[cat] = (assetAllocation[cat] ?? 0) + 1;
      }

      final totalHoldings = holdings.length;
      if (totalHoldings > 0) {
        assetAllocation.forEach((key, value) {
          assetAllocation[key] = ((value / totalHoldings) * 100).round();
        });
      }

      final totalReturns = currentValue - totalInvested;
      final returnsPercentage =
          totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;

      double monthlySip = 0;
      for (var txn in transactions) {
        if (txn['type'] == 'sip') {
          monthlySip += (txn['amount']?.toDouble() ?? 0);
        }
      }

      userData?['investments']['portfolio_summary'] = {
        'current_value': currentValue,
        'total_invested': totalInvested,
        'total_returns': totalReturns,
        'returns_percentage': returnsPercentage,
        'monthly_sip': monthlySip,
        'asset_allocation': assetAllocation,
      };

      await _firebaseService.saveUserProfile(userData!);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Investment ${type == 'sell' ? 'sold' : 'added'} successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving investment: $e')));
    }
  }
}
