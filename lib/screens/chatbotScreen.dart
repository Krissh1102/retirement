// AI Chatbot Screen with Google Gemini API and Firebase Integration
// Professional Black & White Design
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text(
          'AI Financial Advisor',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey.shade300),
          Expanded(
            child:
                _messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.chat_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'AI Financial Advisor',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ask me anything about your retirement plan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'I can read and update your financial data',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
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
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUser ? Colors.black : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isUser
                                        ? Colors.black
                                        : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['text']!,
                                  style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (message['updated'] == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'DATA UPDATED',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.8,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    style: const TextStyle(fontSize: 14, letterSpacing: 0.2),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey.shade300 : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 22,
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
