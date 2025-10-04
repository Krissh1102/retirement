import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:math';

class PersonalizedRoadmapScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PersonalizedRoadmapScreen({Key? key, required this.userData})
    : super(key: key);

  @override
  State<PersonalizedRoadmapScreen> createState() =>
      _PersonalizedRoadmapScreenState();
}

class _PersonalizedRoadmapScreenState extends State<PersonalizedRoadmapScreen> {
  late GenerativeModel _model;
  List<Map<String, dynamic>> _roadmaps = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _generatePersonalizedRoadmaps();
  }

  void _initializeGemini() {
    const apiKey = 'AIzaSyC3TVQ5iUDbpal03iE6udPF86xngJn-XOg';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 7500,
      ),
    );
  }

  Map<String, dynamic> _extractUserData() {
    // Extract from nested structure
    final profile = widget.userData['profile']?['personal_info'] ?? {};
    final goals = widget.userData['goals']?['retirement_goals'] ?? {};
    final portfolio =
        widget.userData['investments']?['portfolio_summary'] ?? {};

    final age = profile['age'] ?? 30;
    final retirementAge = goals['retirement_age'] ?? 60;
    final lifeExpectancy = profile['life_expectancy'] ?? 80;
    final income = profile['income']?.toDouble() ?? 0.0;
    final currentCorpus = goals['current_corpus']?.toDouble() ?? 0.0;
    final targetCorpus = goals['target_corpus']?.toDouble() ?? 0.0;
    final monthlyExpenses =
        profile['monthly_expenses']?.toDouble() ?? (income * 0.4);

    return {
      'name': profile['name'] ?? 'there',
      'age': age,
      'retirementAge': retirementAge,
      'lifeExpectancy': lifeExpectancy,
      'income': income,
      'monthlyExpenses': monthlyExpenses,
      'currentCorpus': currentCorpus,
      'targetCorpus': targetCorpus,
      'riskProfile': profile['risk_profile'] ?? 'Moderate',
      'yearsToRetirement': retirementAge - age,
      'postRetirementYears': lifeExpectancy - retirementAge,
      'gap': targetCorpus - currentCorpus,
    };
  }

  Future<void> _generatePersonalizedRoadmaps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = _extractUserData();

      print('DEBUG: User data extracted:');
      print(
        'Age: ${data['age']}, Retirement: ${data['retirementAge']}, Life: ${data['lifeExpectancy']}',
      );
      print('Years to retirement: ${data['yearsToRetirement']}');

      // Ultra-short prompt for faster response
      final prompt = '''Generate 4 retirement investment roadmaps as JSON.

User: ${data['name']}, Age ${data['age']}, Retires ${data['retirementAge']}, Lives to ${data['lifeExpectancy']}
Current: ₹${(data['currentCorpus'] / 100000).toStringAsFixed(1)}L, Target: ₹${(data['targetCorpus'] / 100000).toStringAsFixed(1)}L
Risk: ${data['riskProfile']}, Years left: ${data['yearsToRetirement']}

4 roadmaps (Wealth Max, Family Security, Lifestyle Balance, Tax Smart):
{
  "roadmaps": [
    {
      "priority": 1,
      "title": "Wealth Maximization Plan",
      "tagline": "Build maximum corpus for retirement",
      "personalMessage": "Personal advice for ${data['name']}",
      "keyFocus": ["point1", "point2", "point3"],
      "monthlyAction": "Monthly step",
      "timeline": [
        {"phase": "Growth ${data['age']}-${(data['age'] + data['yearsToRetirement'] / 2).toInt()}", "strategy": "Strategy", "allocation": "Equity 70%, Debt 20%, Gold 10%", "whyThisWorks": "Why"},
        {"phase": "Consolidation ${(data['age'] + data['yearsToRetirement'] / 2).toInt()}-${data['retirementAge'] - 5}", "strategy": "Strategy", "allocation": "Equity 50%, Debt 40%, Gold 10%", "whyThisWorks": "Why"},
        {"phase": "Preservation ${data['retirementAge'] - 5}-${data['retirementAge']}", "strategy": "Strategy", "allocation": "Equity 30%, Debt 60%, Gold 10%", "whyThisWorks": "Why"},
        {"phase": "Retirement ${data['retirementAge']}-${data['lifeExpectancy']}", "strategy": "Strategy", "allocation": "Equity 20%, Debt 70%, Gold 10%", "whyThisWorks": "Why"}
      ],
      "expectedOutcome": "Outcome at retirement",
      "bestFor": "Best for reason"
    }
  ]
}

Return valid JSON only, 4 roadmaps with different priorities.''';

      print('DEBUG: Sending prompt to Gemini...');
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final responseText = response.text ?? '';

      print('DEBUG: Response received, length: ${responseText.length}');
      print(
        'DEBUG: First 200 chars: ${responseText.substring(0, min(200, responseText.length))}',
      );

      // Clean response
      String cleanedJson = responseText.trim();

      // Remove markdown code blocks if present
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceAll(RegExp(r'```json\s*'), '');
        cleanedJson = cleanedJson.replaceAll(RegExp(r'```\s*'), '');
      }

      // Find JSON boundaries
      final jsonStart = cleanedJson.indexOf('{');
      final jsonEnd = cleanedJson.lastIndexOf('}') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        print('DEBUG: Could not find JSON in response');
        throw Exception('No valid JSON found in response');
      }

      final jsonString = cleanedJson.substring(jsonStart, jsonEnd);
      print('DEBUG: Attempting to parse JSON...');

      final parsedData = json.decode(jsonString);
      final roadmapsList = parsedData['roadmaps'] as List<dynamic>?;

      if (roadmapsList == null || roadmapsList.isEmpty) {
        print('DEBUG: Roadmaps list is null or empty');
        throw Exception('No roadmaps in response');
      }

      print('DEBUG: Successfully parsed ${roadmapsList.length} roadmaps');

      setState(() {
        _roadmaps = List<Map<String, dynamic>>.from(roadmapsList);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('DEBUG: Error occurred: $e');
      print('DEBUG: Stack trace: $stackTrace');

      setState(() {
        _error =
            'Error: ${e.toString()}\n\nPlease check your API key and internet connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Personal Roadmaps',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : _buildRoadmapsList(),
    );
  }

  Widget _buildLoadingState() {
    final data = _extractUserData();
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
          const SizedBox(height: 24),
          const Text(
            'Creating your personalized roadmaps...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Planning for ${data['postRetirementYears']} years of retirement',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePersonalizedRoadmaps,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapsList() {
    return RefreshIndicator(
      onRefresh: _generatePersonalizedRoadmaps,
      color: Colors.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _roadmaps.length + 1,
        itemBuilder: (context, index) {
          if (index == _roadmaps.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: TextButton.icon(
                  onPressed: _generatePersonalizedRoadmaps,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Generate New Roadmaps'),
                  style: TextButton.styleFrom(foregroundColor: Colors.black),
                ),
              ),
            );
          }
          return _buildRoadmapCard(_roadmaps[index], index);
        },
      ),
    );
  }

  Widget _buildRoadmapCard(Map<String, dynamic> roadmap, int index) {
    final priority = roadmap['priority'] ?? (index + 1);
    final priorityColors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];
    final color = priorityColors[index % priorityColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Priority $priority',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  roadmap['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  roadmap['tagline'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Personal Message
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 20, color: color),
                    const SizedBox(width: 8),
                    const Text(
                      'Why This Works for You',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  roadmap['personalMessage'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Key Focus Areas
          if (roadmap['keyFocus'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, size: 20, color: color),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Focus Areas',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List<String>.from(roadmap['keyFocus']).map(
                    (focus) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              focus,
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Monthly Action
          if (roadmap['monthlyAction'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.05)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_month, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Monthly Action',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roadmap['monthlyAction'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Timeline
          if (roadmap['timeline'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timeline, size: 20, color: color),
                      const SizedBox(width: 8),
                      const Text(
                        'Investment Timeline',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List<Map<String, dynamic>>.from(
                    roadmap['timeline'],
                  ).asMap().entries.map((entry) {
                    final isLast = entry.key == roadmap['timeline'].length - 1;
                    return _buildTimelinePhase(entry.value, color, isLast);
                  }),
                ],
              ),
            ),

          Divider(height: 1, color: Colors.grey.shade200),

          // Expected Outcome
          if (roadmap['expectedOutcome'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 20, color: color),
                      const SizedBox(width: 8),
                      const Text(
                        'Expected Outcome',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    roadmap['expectedOutcome'],
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),

          // Best For Tag
          if (roadmap['bestFor'] != null)
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      roadmap['bestFor'],
                      style: TextStyle(
                        fontSize: 13,
                        color: color.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(
    Map<String, dynamic> phase,
    Color color,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(width: 2, height: 80, color: color.withOpacity(0.3)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  phase['phase'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phase['strategy'] ?? '',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    phase['allocation'] ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (phase['whyThisWorks'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '💡 ${phase['whyThisWorks']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
