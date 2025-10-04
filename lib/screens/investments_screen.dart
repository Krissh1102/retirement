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

      if (!mounted) return;

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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Investment Portfolio',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF000000),
            fontSize: 20,
            letterSpacing: -0.8,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF000000)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF000000),
              size: 26,
            ),
            onPressed: () => _showAddInvestmentBottomSheet(),
            tooltip: 'Add Investment',
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF000000),
              size: 24,
            ),
            onPressed: _refreshData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF000000),
                  strokeWidth: 2.5,
                ),
              )
              : RefreshIndicator(
                color: const Color(0xFF000000),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PORTFOLIO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Icon(
                      returnsPercentage >= 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.black,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${returnsPercentage >= 0 ? '+' : ''}${returnsPercentage.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'CURRENT VALUE',
                  '₹${formatAmount(currentValue)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'INVESTED',
                  '₹${formatAmount(totalInvested)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'RETURNS',
                  '₹${formatAmount(totalReturns)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'MONTHLY SIP',
                  '₹${formatAmount(monthlySip)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        controller: _tabController,
        indicator: const BoxDecoration(
          color: Color(0xFF000000),
          borderRadius: BorderRadius.zero,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'HOLDINGS'),
          Tab(text: 'TRANSACTIONS'),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          holding['symbol']?.substring(0, 2).toUpperCase() ??
                              'NA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0,
                          ),
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000000),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            holding['symbol'] ?? '',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(height: 1, color: const Color(0xFFE0E0E0)),
                const SizedBox(height: 24),
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
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddInvestmentBottomSheet(
                            type: 'buy',
                            symbol: holding['symbol'],
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF000000),
                          side: const BorderSide(
                            color: Color(0xFF000000),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'BUY MORE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddInvestmentBottomSheet(
                            type: 'sell',
                            symbol: holding['symbol'],
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        child: const Text(
                          'SELL',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 13,
                          ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF000000),
              letterSpacing: -0.3,
            ),
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
                      top: Radius.circular(2),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 28,
                    right: 28,
                    top: 28,
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
                              'ADD INVESTMENT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000000),
                                letterSpacing: 1,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, size: 24),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'TYPE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Color(0xFF000000),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoiceChip(
                              'BUY',
                              'buy',
                              selectedType,
                              setModalState,
                              (val) => selectedType = val,
                            ),
                            _buildChoiceChip(
                              'SELL',
                              'sell',
                              selectedType,
                              setModalState,
                              (val) => selectedType = val,
                            ),
                            _buildChoiceChip(
                              'SIP',
                              'sip',
                              selectedType,
                              setModalState,
                              (val) => selectedType = val,
                            ),
                            _buildChoiceChip(
                              'DIVIDEND',
                              'dividend',
                              selectedType,
                              setModalState,
                              (val) => selectedType = val,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'CATEGORY',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Color(0xFF000000),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoiceChip(
                              'EQUITY',
                              'equity',
                              selectedCategory,
                              setModalState,
                              (val) => selectedCategory = val,
                            ),
                            _buildChoiceChip(
                              'DEBT',
                              'debt',
                              selectedCategory,
                              setModalState,
                              (val) => selectedCategory = val,
                            ),
                            _buildChoiceChip(
                              'GOLD',
                              'gold',
                              selectedCategory,
                              setModalState,
                              (val) => selectedCategory = val,
                            ),
                            _buildChoiceChip(
                              'OTHERS',
                              'others',
                              selectedCategory,
                              setModalState,
                              (val) => selectedCategory = val,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          symbolController,
                          'Symbol/Ticker',
                          'e.g., RELIANCE, INFY',
                          isCapitalized: true,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          nameController,
                          'Investment Name',
                          'e.g., Reliance Industries Ltd',
                        ),
                        if (selectedType != 'dividend')
                          const SizedBox(height: 16),
                        if (selectedType != 'dividend')
                          _buildTextField(
                            quantityController,
                            'Quantity',
                            'Number of units',
                            isNumber: true,
                          ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          priceController,
                          selectedType == 'dividend'
                              ? 'Dividend Amount'
                              : 'Price per Unit',
                          selectedType == 'dividend'
                              ? 'Total dividend received'
                              : 'Price in ₹',
                          isNumber: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            labelStyle: const TextStyle(
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            hintStyle: const TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(2),
                              borderSide: const BorderSide(
                                color: Color(0xFF000000),
                                width: 2,
                              ),
                            ),
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
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                  foregroundColor: const Color(0xFF666666),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    fontSize: 13,
                                  ),
                                ),
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
                                  backgroundColor: const Color(0xFF000000),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: const Text(
                                  'SAVE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    String selectedValue,
    StateSetter setModalState,
    Function(String) onSelected,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => setModalState(() => onSelected(value)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000000) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF000000) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF666666),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
    bool isCapitalized = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF666666),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: Color(0xFF000000), width: 2),
        ),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textCapitalization:
          isCapitalized
              ? TextCapitalization.characters
              : TextCapitalization.none,
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
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Color(0xFF000000),
        ),
      );
      return;
    }

    if (type != 'dividend' && quantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity'),
          backgroundColor: Color(0xFF000000),
        ),
      );
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
          backgroundColor: const Color(0xFF000000),
        ),
      );
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving investment: $e'),
          backgroundColor: const Color(0xFF000000),
        ),
      );
    }
  }
}
