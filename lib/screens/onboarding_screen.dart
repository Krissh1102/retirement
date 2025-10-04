import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isSigningIn = false;
  GoogleSignInAccount? _user;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(
        serverClientId: '1083998051434-ob5dsu3i2j72l2bchmf7v0ml0vrks54b.apps.googleusercontent.com',
      );

      _authSubscription = signIn.authenticationEvents.listen(
        _handleAuthenticationEvent,
        onError: _handleAuthenticationError,
      );

      await signIn.attemptLightweightAuthentication();
    } catch (e) {
      print('Google Sign-In initialization failed: $e');
      if (mounted) {
        _showErrorSnackBar('Google Sign-In initialization failed.');
      }
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    if (!mounted) return;
    setState(() {
      switch (event) {
        case GoogleSignInAuthenticationEventSignIn():
          _user = event.user;
          break;
        case GoogleSignInAuthenticationEventSignOut():
          _user = null;
          break;
      }
    });
  }

  void _handleAuthenticationError(Object error) {
    print('Authentication error: $error');
    if (mounted) {
      _showErrorSnackBar('Authentication error occurred');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);

    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      if (signIn.supportsAuthenticate()) {
        await signIn.authenticate();
      } else {
        throw UnsupportedError('Authentication not supported on this platform');
      }

      if (_user == null) {
        setState(() => _isSigningIn = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await _user!.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted && userCredential.user != null) {
        // Navigate to questionnaire for first-time users
        Navigator.pushReplacementNamed(context, '/questionnaire');
      }
    } on GoogleSignInException catch (e) {
      print("Google Sign-In exception: ${e.code} - ${e.description}");
      if (mounted) {
        _showErrorSnackBar('Sign-in failed: ${e.description ?? e.code}');
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth exception: ${e.code} - ${e.message}");
      if (mounted) {
        _showErrorSnackBar('Authentication failed: ${e.message}');
      }
    } catch (e) {
      print("Unexpected error in Google Sign-In: $e");
      if (mounted) {
        _showErrorSnackBar('Sign-in failed, please try again');
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.08),
              
              // App Logo/Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1565C0).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 40),
              
              // App Name
              Text(
                'RetireSmart',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Tagline
              Text(
                'AI-Powered Retirement Planning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                  letterSpacing: 0.2,
                ),
              ),
              
              SizedBox(height: 60),
              
              // Key Features
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE5E5E5), width: 1),
                ),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      Icons.analytics_outlined,
                      'Smart Corpus Calculator',
                      'Real-time retirement corpus estimation',
                    ),
                    SizedBox(height: 20),
                    _buildFeatureRow(
                      Icons.trending_up_outlined,
                      'SIP Recommendations',
                      'Personalized investment suggestions',
                    ),
                    SizedBox(height: 20),
                    _buildFeatureRow(
                      Icons.calculate_outlined,
                      'Tax-Optimized Planning',
                      'Factor in 80C benefits & LTCG implications',
                    ),
                    SizedBox(height: 20),
                    _buildFeatureRow(
                      Icons.security_outlined,
                      'Trusted & Transparent',
                      'No hidden fees, subscription-based model',
                    ),
                  ],
                ),
              ),
              
              Spacer(),
              
              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSigningIn ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Color(0xFF1565C0).withOpacity(0.6),
                  ),
                  child: _isSigningIn
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Signing in...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.login, size: 24);
                              },
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Terms and Privacy
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Color(0xFF1565C0),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}