// AI Chatbot Screen with Google Gemini API and Firebase Integration
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AIChatbotScreen extends StatefulWidget {
  final dynamic firebaseService;

  const AIChatbotScreen({Key? key, required this.firebaseService})
    : super(key: key);

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  static const String apiKey = 'AIzaSyC3TVQ5iUDbpal03iE6udPF86xngJn-XOg';
  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeAI();
  }

  Future<void> _loadUserData() async {
    try {
      _userData = await widget.firebaseService.loadUserProfile();
      setState(() {});
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _initializeAI() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        '''You are an AI financial advisor assistant with access to the user's retirement planning data. Your goal is to be a helpful, conversational assistant that can read and update the user's financial data based on their requests.

## CAPABILITIES:
1.  **READ user data:** You can view their complete financial profile.
2.  **UPDATE user data:** You can modify any field in their data using the `update_user_data` function.
3.  **PROVIDE insights:** You can answer questions and give recommendations based on their data.

## DATA STRUCTURE CHEAT SHEET:
To update data, you must specify the correct `collection`, `document`, and a map of `updates`. Here is the structure:

- **Collection: `profile`**
  - **Document: `personal_info`**: Fields like `name`, `age`, `life_expectancy`, `dependents`.
  - **Document: `financial_profile`**: Fields like `current_income`, `monthly_expenses`, `existing_savings`, `expected_return_rate`.
  - **Document: `preferences`**: Fields like `risk_tolerance`, `investment_experience`.

- **Collection: `investments`**
  - **Document: `portfolio_summary`**: Fields like `monthly_sip`, `asset_allocation`.

- **Collection: `goals`**
  - **Document: `retirement_goals`**: Fields like `target_corpus`, `current_corpus`, `retirement_age`.

- **Collection: `spending`**
  - **Document: `monthly_expenses`**: Fields for budget categories like `housing`, `food`, `transportation`, etc.

## AVAILABLE FUNCTIONS:
1.  `update_user_data(collection, document, updates)`: The primary function for changing any user data.
2.  `add_milestone(parameters)`: Use ONLY when the user explicitly asks to add a new milestone.
3.  `get_analytics(type)`: Use ONLY when the user asks for a summary or analysis (e.g., "What's my portfolio like?", "How am I doing on my goals?").

## RESPONSE FORMAT:
When the user wants to update data, you MUST respond with a JSON object in this format:
{
  "message": "Your conversational response to the user.",
  "action": "update_user_data",
  "parameters": {
    "collection": "the_collection_name",
    "document": "the_document_name",
    "updates": {
      "field_to_update_1": "new_value_1",
      "field_to_update_2": 12345
    }
  }
}

## EXAMPLES:
User: "My name is Priya and I am 32 years old."
Response: {"message": "Got it. I've updated your name to Priya and your age to 32.", "action": "update_user_data", "parameters": {"collection": "profile", "document": "personal_info", "updates": {"name": "Priya", "age": 32}}}

User: "My monthly income is now 95000 and my expenses are 40000."
Response: {"message": "Thanks for the update. I've set your monthly income to ₹95,000 and expenses to ₹40,000. This leaves you with a healthy surplus for investing!", "action": "update_user_data", "parameters": {"collection": "profile", "document": "financial_profile", "updates": {"current_income": 95000, "monthly_expenses": 40000}}}

User: "I want to increase my monthly SIP to 25000."
Response: {"message": "Excellent! I'll update your monthly SIP to ₹25,000. This is a great step towards your retirement goal!", "action": "update_user_data", "parameters": {"collection": "investments", "document": "portfolio_summary", "updates": {"monthly_sip": 25000}}}

User: "Let's change my retirement age to 62."
Response: {"message": "I've updated your retirement age to 62 in your goals. This gives you two more years to grow your wealth.", "action": "update_user_data", "parameters": {"collection": "goals", "document": "retirement_goals", "updates": {"retirement_age": 62}}}

User: "What's my goal progress?"
Response: {"message": "Let me get the latest analytics on your retirement goals for you.", "action": "get_analytics", "parameters": {"type": "goal"}}

Always be conversational and provide context for the changes. When updating financial data, briefly explain the impact of the change.
''',
      ),
    );

    _chat = _model.startChat();
    if (_userData != null) {
      _sendInitialContext();
    }
  }

  Future<void> _sendInitialContext() async {
    try {
      final context = _buildUserDataContext();
      await _chat.sendMessage(
        Content.text(
          'Here is the current user data for context. Use this to answer questions and make updates:\n$context',
        ),
      );
    } catch (e) {
      print('Error sending initial context: $e');
    }
  }

  String _buildUserDataContext() {
    if (_userData == null) return 'No user data available';

    final profile = _userData!['profile'] ?? {};
    final personalInfo = profile['personal_info'] ?? {};
    final financialProfile = profile['financial_profile'] ?? {};
    final preferences = profile['preferences'] ?? {};

    final investments = _userData!['investments'] ?? {};
    final portfolioSummary = investments['portfolio_summary'] ?? {};

    final goals = _userData!['goals'] ?? {};
    final retirementGoals = goals['retirement_goals'] ?? {};

    final spending = _userData!['spending'] ?? {};
    final monthlyExpenses = spending['monthly_expenses'] ?? {};

    return '''
USER PROFILE:
- Name: ${personalInfo['name'] ?? 'Not set'}
- Age: ${personalInfo['age'] ?? 'Not set'}
- Retirement Age: ${personalInfo['retirement_age'] ?? 'Not set'}
- Life Expectancy: ${personalInfo['life_expectancy'] ?? 'Not set'}

FINANCIAL PROFILE:
- Monthly Income: ₹${financialProfile['current_income'] ?? 0}
- Monthly Expenses: ₹${financialProfile['monthly_expenses'] ?? 0}
- Existing Savings: ₹${financialProfile['existing_savings'] ?? 0}
- Existing Investments: ₹${financialProfile['existing_investments'] ?? 0}
- Expected Return Rate: ${financialProfile['expected_return_rate'] ?? 12}%

INVESTMENTS:
- Current Portfolio Value: ₹${portfolioSummary['current_value'] ?? 0}
- Total Invested: ₹${portfolioSummary['total_invested'] ?? 0}
- Monthly SIP: ₹${portfolioSummary['monthly_sip'] ?? 0}
- Returns: ₹${portfolioSummary['total_returns'] ?? 0} (${portfolioSummary['returns_percentage'] ?? 0}%)

RETIREMENT GOALS:
- Target Corpus: ₹${retirementGoals['target_corpus'] ?? 0}
- Current Corpus: ₹${retirementGoals['current_corpus'] ?? 0}
- Years to Retirement: ${retirementGoals['years_to_retirement'] ?? 0}

SPENDING:
- Total Monthly Expenses: ₹${monthlyExpenses['total_monthly_expenses'] ?? 0}
- Emergency Fund Target: ₹${monthlyExpenses['emergency_fund_target'] ?? 0}

PREFERENCES:
- Risk Tolerance: ${preferences['risk_tolerance'] ?? 'Not set'}
- Monthly SIP: ₹${preferences['sip_amount'] ?? 0}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Financial Advisor'),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ask me anything about your retirement plan!',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'I can read and update your data',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message['sender'] == 'user';

                        return Align(
                          alignment:
                              isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? const Color(0xFF6C63FF)
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text']!,
                                  style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (message['updated'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Updated',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'AI is thinking...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  mini: true,
                  backgroundColor:
                      _isLoading
                          ? Colors.grey.shade400
                          : const Color(0xFF6C63FF),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(userMessage));
      final aiResponse =
          response.text ?? 'Sorry, I couldn\'t generate a response.';

      // Try to parse JSON response for actions
      Map<String, dynamic>? actionData;
      String displayMessage = aiResponse;
      bool wasUpdated = false;

      try {
        // Check if response contains JSON
        if (aiResponse.contains('{') && aiResponse.contains('}')) {
          final jsonStart = aiResponse.indexOf('{');
          final jsonEnd = aiResponse.lastIndexOf('}') + 1;
          final jsonStr = aiResponse.substring(jsonStart, jsonEnd);
          actionData = json.decode(jsonStr);

          displayMessage = actionData?['message'] ?? aiResponse;

          // Execute the action
          if (actionData?['action'] != null) {
            wasUpdated = await _executeAction(
              actionData?['action'],
              actionData?['parameters'] ?? {},
            );
          }
        }
      } catch (e) {
        print('No action to parse: $e');
      }

      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': displayMessage,
          'updated': wasUpdated,
        });
        _isLoading = false;
      });

      // Reload user data if there was an update
      if (wasUpdated) {
        await _loadUserData();
        await _sendInitialContext(); // Refresh AI context
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text':
              'Sorry, I encountered an error: ${e.toString()}. Please try again.',
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<bool> _executeAction(
    String action,
    Map<String, dynamic> parameters,
  ) async {
    try {
      switch (action) {
        case 'update_user_data':
          // The new generic handler for all data updates
          final collection = parameters['collection'] as String?;
          final document = parameters['document'] as String?;
          final updates = parameters['updates'] as Map<String, dynamic>?;

          if (collection == null || document == null || updates == null) {
            print('Error: Missing parameters for update_user_data');
            return false;
          }

          // Use your existing generic update function from FirebaseService
          return await widget.firebaseService.updateProfileField(
            collection,
            document,
            updates,
          );

        case 'add_milestone':
          await widget.firebaseService.addMilestone(parameters);
          return true;

        case 'get_analytics':
          final type = parameters['type'] ?? 'goal';
          Map<String, dynamic> analytics;

          if (type == 'portfolio') {
            analytics = await widget.firebaseService.getPortfolioAnalytics();
          } else if (type == 'spending') {
            analytics = await widget.firebaseService.getSpendingAnalytics();
          } else {
            analytics = await widget.firebaseService.getGoalAnalytics();
          }

          // Send analytics back to AI for a conversational response
          await _chat.sendMessage(
            Content.text(
              'Here is the requested analytics data. Use this to form a natural language response for the user:\n${json.encode(analytics)}',
            ),
          );
          // Return false because this action doesn't update the user's primary data, it just fetches info.
          return false;

        default:
          print('Unknown action: $action');
          return false;
      }
    } catch (e) {
      print('Error executing action "$action": $e');
      return false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
