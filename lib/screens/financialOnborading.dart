import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:retierment/services/questions_data.dart';

class RetirementQuestionnaireScreen extends StatefulWidget {
  @override
  _RetirementQuestionnaireScreenState createState() =>
      _RetirementQuestionnaireScreenState();
}

class _RetirementQuestionnaireScreenState
    extends State<RetirementQuestionnaireScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isLoading = false;

  // Form Data (same as before)
  final Map<String, dynamic> _userData = {
    // Basic Information
    'name': '',
    'age': '',
    'retirementAge': '',
    'lifeExpectancy': '',
    'location': '',
    'maritalStatus': '',
    'dependents': '',

    // Financial Information
    'currentIncome': '',
    'monthlyExpenses': '',
    'existingSavings': '',
    'existingInvestments': '',
    'expectedInflationRate': '6',
    'expectedReturnRate': '12',

    // Investment Preferences
    'riskTolerance': '',
    'investmentExperience': '',
    'preferredInvestments': <String>[],
    'sipAmount': '',
    'investmentFrequency': '',

    // Goals and Preferences
    'retirementGoals': <String>[],
    'emergencyFundMonths': '',
    'healthInsurance': '',
    'taxSlab': '',
    'section80c': '',
  };

  final List<String> _investmentOptions = [
    'Mutual Funds',
    'SIP',
    'PPF',
    'EPF',
    'NPS',
    'Fixed Deposits',
    'Stocks',
    'Bonds',
    'Real Estate',
    'Gold',
  ];

  final List<String> _retirementGoalOptions = [
    'Maintain current lifestyle',
    'Travel extensively',
    'Start a business',
    'Support children\'s education',
    'Healthcare expenses',
    'Charitable activities',
    'Luxury lifestyle',
    'Simple living',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            _currentStep > 0
                ? IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Color(0xFF1565C0)),
                  onPressed: _isLoading ? null : _previousStep,
                )
                : null,
        title: Text(
          'Retirement Planning Setup',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? _buildLoadingScreen()
              : Column(
                children: [
                  // Progress Indicator
                  _buildProgressIndicator(),

                  // Form Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildBasicInfoStep(),
                        _buildFinancialInfoStep(),
                        _buildInvestmentPreferencesStep(),
                        _buildGoalsAndPreferencesStep(),
                      ],
                    ),
                  ),

                  // Navigation Buttons
                  _buildNavigationButtons(),
                ],
              ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
          ),
          SizedBox(height: 24),
          Text(
            'Setting up your retirement plan...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few moments',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSteps, (index) {
              final isCompleted = index < _currentStep;
              final isCurrent = index == _currentStep;

              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        isCompleted || isCurrent
                            ? Color(0xFF1565C0)
                            : Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 12),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // All the form building methods remain the same...
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Let\'s start with some basic information about you',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            SizedBox(height: 32),

            _buildTextField(
              label: 'Full Name',
              key: 'name',
              validator:
                  (value) =>
                      value?.isEmpty == true ? 'Please enter your name' : null,
            ),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Current Age',
                    key: 'age',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final age = int.tryParse(value!);
                      if (age == null || age < 18 || age > 70) {
                        return 'Enter valid age (18-70)';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Retirement Age',
                    key: 'retirementAge',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Required';
                      final retAge = int.tryParse(value!);
                      final currentAge = int.tryParse(_userData['age'] ?? '0');
                      if (retAge == null ||
                          retAge <= (currentAge ?? 0) ||
                          retAge > 75) {
                        return 'Invalid age';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            _buildDropdownField(
              label: 'Marital Status',
              key: 'maritalStatus',
              items: ['Single', 'Married', 'Divorced', 'Widowed'],
            ),

            _buildTextField(
              label: 'Number of Dependents',
              key: 'dependents',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true)
                  return 'Please enter number of dependents (0 if none)';
                final deps = int.tryParse(value!);
                if (deps == null || deps < 0) return 'Enter valid number';
                return null;
              },
            ),

            _buildTextField(
              label: 'Location (City, State)',
              key: 'location',
              validator:
                  (value) =>
                      value?.isEmpty == true
                          ? 'Please enter your location'
                          : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Help us understand your current financial situation',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          SizedBox(height: 32),

          _buildTextField(
            label: 'Current Monthly Income (₹)',
            key: 'currentIncome',
            keyboardType: TextInputType.number,
            prefix: '₹',
            validator: (value) {
              if (value?.isEmpty == true) return 'Please enter your income';
              final income = double.tryParse(value!);
              if (income == null || income <= 0) return 'Enter valid amount';
              return null;
            },
          ),

          _buildTextField(
            label: 'Current Monthly Expenses (₹)',
            key: 'monthlyExpenses',
            keyboardType: TextInputType.number,
            prefix: '₹',
            validator: (value) {
              if (value?.isEmpty == true) return 'Please enter your expenses';
              final expenses = double.tryParse(value!);
              if (expenses == null || expenses <= 0)
                return 'Enter valid amount';
              return null;
            },
          ),

          _buildTextField(
            label: 'Existing Savings (₹)',
            key: 'existingSavings',
            keyboardType: TextInputType.number,
            prefix: '₹',
            validator: (value) {
              if (value?.isEmpty == true) return 'Enter 0 if no savings';
              final savings = double.tryParse(value!);
              if (savings == null || savings < 0) return 'Enter valid amount';
              return null;
            },
          ),

          _buildTextField(
            label: 'Current Investments (₹)',
            key: 'existingInvestments',
            keyboardType: TextInputType.number,
            prefix: '₹',
            validator: (value) {
              if (value?.isEmpty == true) return 'Enter 0 if no investments';
              final investments = double.tryParse(value!);
              if (investments == null || investments < 0)
                return 'Enter valid amount';
              return null;
            },
          ),

          _buildDropdownField(
            label: 'Current Tax Slab',
            key: 'taxSlab',
            items: [
              '0% (Up to ₹2.5L)',
              '5% (₹2.5L - ₹5L)',
              '20% (₹5L - ₹10L)',
              '30% (Above ₹10L)',
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Expected Inflation Rate (%)',
                  key: 'expectedInflationRate',
                  keyboardType: TextInputType.number,
                  suffix: '%',
                  initialValue: '6',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Expected Return Rate (%)',
                  key: 'expectedReturnRate',
                  keyboardType: TextInputType.number,
                  suffix: '%',
                  initialValue: '12',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentPreferencesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tell us about your investment preferences and risk tolerance',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          SizedBox(height: 32),

          _buildDropdownField(
            label: 'Risk Tolerance',
            key: 'riskTolerance',
            items: [
              'Conservative (Low Risk)',
              'Moderate (Medium Risk)',
              'Aggressive (High Risk)',
            ],
          ),

          _buildDropdownField(
            label: 'Investment Experience',
            key: 'investmentExperience',
            items: [
              'Beginner (0-2 years)',
              'Intermediate (2-5 years)',
              'Advanced (5+ years)',
            ],
          ),

          Text(
            'Preferred Investment Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Select all that interest you',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _investmentOptions.map((option) {
                  final isSelected = (_userData['preferredInvestments'] as List)
                      .contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final List<String> preferred =
                            _userData['preferredInvestments'] as List<String>;
                        if (selected) {
                          preferred.add(option);
                        } else {
                          preferred.remove(option);
                        }
                      });
                    },
                    selectedColor: Color(0xFF1565C0).withOpacity(0.2),
                    checkmarkColor: Color(0xFF1565C0),
                  );
                }).toList(),
          ),

          SizedBox(height: 24),

          _buildTextField(
            label: 'Monthly SIP Amount (₹)',
            key: 'sipAmount',
            keyboardType: TextInputType.number,
            prefix: '₹',
            helperText: 'Amount you can invest monthly via SIP',
          ),

          _buildDropdownField(
            label: 'Investment Frequency',
            key: 'investmentFrequency',
            items: ['Monthly', 'Quarterly', 'Annually'],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsAndPreferencesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Retirement Goals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'What are your plans and goals for retirement?',
            style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
          ),
          SizedBox(height: 32),

          Text(
            'Retirement Goals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Select all that apply to you',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _retirementGoalOptions.map((goal) {
                  final isSelected = (_userData['retirementGoals'] as List)
                      .contains(goal);
                  return FilterChip(
                    label: Text(goal),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final List<String> goals =
                            _userData['retirementGoals'] as List<String>;
                        if (selected) {
                          goals.add(goal);
                        } else {
                          goals.remove(goal);
                        }
                      });
                    },
                    selectedColor: Color(0xFF1565C0).withOpacity(0.2),
                    checkmarkColor: Color(0xFF1565C0),
                  );
                }).toList(),
          ),

          SizedBox(height: 24),

          _buildTextField(
            label: 'Emergency Fund (Months of Expenses)',
            key: 'emergencyFundMonths',
            keyboardType: TextInputType.number,
            helperText:
                'How many months of expenses do you want as emergency fund?',
            validator: (value) {
              if (value?.isEmpty == true)
                return 'Please enter number of months';
              final months = int.tryParse(value!);
              if (months == null || months < 3)
                return 'Minimum 3 months recommended';
              return null;
            },
          ),

          _buildDropdownField(
            label: 'Health Insurance Coverage',
            key: 'healthInsurance',
            items: [
              'No coverage',
              'Basic (₹1-5 Lakhs)',
              'Standard (₹5-10 Lakhs)',
              'Premium (₹10+ Lakhs)',
              'Family floater',
            ],
          ),

          SizedBox(height: 32),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF1565C0).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• We\'ll calculate your retirement corpus based on inflation\n'
                  '• Get personalized SIP recommendations\n'
                  '• See tax-optimized investment strategies\n'
                  '• Track your progress with AI insights',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1565C0),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String key,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
    String? prefix,
    String? suffix,
    String? initialValue,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: TextFormField(
        initialValue: initialValue ?? _userData[key]?.toString(),
        keyboardType: keyboardType,
        validator: validator,
        enabled: !_isLoading,
        onChanged: (value) {
          setState(() {
            _userData[key] = value;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixText: prefix,
          suffixText: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String key,
    required List<String> items,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: _userData[key]?.isEmpty == true ? null : _userData[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFFE5E5E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged:
            _isLoading
                ? null
                : (String? newValue) {
                  setState(() {
                    _userData[key] = newValue ?? '';
                  });
                },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select an option';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(0, 56),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (_currentStep > 0) SizedBox(width: 16),

          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size(0, 56),
                elevation: 0,
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        _currentStep == _totalSteps - 1
                            ? 'Complete Setup'
                            : 'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextStep() {
    if (_currentStep == _totalSteps - 1) {
      _completeSetup();
    } else {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKey.currentState?.validate() ?? false;
    }

    // Add validation for other steps as needed
    switch (_currentStep) {
      case 1: // Financial Info
        final income = double.tryParse(_userData['currentIncome'] ?? '');
        final expenses = double.tryParse(_userData['monthlyExpenses'] ?? '');
        if (income == null || expenses == null) {
          _showValidationError('Please fill all required financial fields');
          return false;
        }
        break;

      case 2: // Investment Preferences
        if (_userData['riskTolerance']?.isEmpty ?? true) {
          _showValidationError('Please select your risk tolerance');
          return false;
        }
        break;

      case 3: // Goals
        final emergencyMonths = int.tryParse(
          _userData['emergencyFundMonths'] ?? '',
        );
        if (emergencyMonths == null || emergencyMonths < 3) {
          _showValidationError(
            'Please enter emergency fund months (minimum 3)',
          );
          return false;
        }
        break;
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _completeSetup() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save user data to Firebase
      final success = await _firebaseService.saveRetirementData(_userData);

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Setup completed successfully!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Navigate to dashboard/home screen after a short delay
        await Future.delayed(Duration(milliseconds: 1500));
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw Exception('Failed to save data');
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to save data. Please try again.',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _completeSetup,
          ),
        ),
      );

      print('Error saving retirement data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
