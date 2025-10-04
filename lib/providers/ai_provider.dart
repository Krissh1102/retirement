import 'package:flutter/material.dart';

class AIProvider extends ChangeNotifier {
  List<String> _recommendations = <String>[];
  Map<String, dynamic> _behavioralInsights = <String, dynamic>{};
  bool _isAnalyzing = false;

  List<String> get recommendations => _recommendations;
  Map<String, dynamic> get behavioralInsights => _behavioralInsights;
  bool get isAnalyzing => _isAnalyzing;

  Future<void> generatePersonalizedAdvice(Map<String, dynamic> userData) async {
    _isAnalyzing = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _recommendations = <String>[
      'Increase SIP by ₹5,000 to achieve retirement goals 5 years earlier',
      'Switch to direct mutual funds to save 1.5% in commissions',
      'Consolidate loans to reduce interest burden by ₹2L',
      'Start NPS investment for additional ₹50L tax savings',
      'Rebalance portfolio: Increase equity to 70% at your age',
    ];

    _behavioralInsights = <String, dynamic>{
      'spending_pattern': 'Impulsive',
      'saving_consistency': 0.75,
      'investment_discipline': 0.82,
      'risk_tolerance': 'Moderate',
      'financial_literacy': 0.68,
      'improvement_areas': <String>[
        'Weekend spending control',
        'Emergency fund building',
        'Tax planning optimization',
      ],
    };

    _isAnalyzing = false;
    notifyListeners();
  }

  String getChatResponse(String query) {
    final Map<String, String> responses = <String, String>{
      'retirement':
          'Based on your profile, you need ₹5Cr corpus. Current trajectory: ₹3.8Cr. Increase SIP by 20%.',
      'emergency':
          'You need 12 months expenses (₹7.8L) as emergency fund. Current: ₹2L. Build this first.',
      'tax':
          'You can save ₹45,000 annually through 80C, NPS, and health insurance.',
      'default':
          'I can help with retirement, investments, tax saving, and financial goals.',
    };

    String key = 'default';
    final String lower = query.toLowerCase();
    if (lower.contains('retirement'))
      key = 'retirement';
    else if (lower.contains('emergency'))
      key = 'emergency';
    else if (lower.contains('tax'))
      key = 'tax';

    return responses[key]!;
  }
}
