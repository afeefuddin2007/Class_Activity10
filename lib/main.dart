import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const LaunchpadApp());

/// The instructor may supply an HTTPS proxy URL. Without it, this app uses
/// an explicitly labeled deterministic mock, as allowed by Activity 10.
/// To use a supplied endpoint during build:
/// flutter build apk --release --dart-define=INSTRUCTOR_AI_URL=https://...
class SignupTipService {
  static const String endpoint = String.fromEnvironment('INSTRUCTOR_AI_URL');
  final http.Client _client = http.Client();

  Future<TipResponse> requestSignupTip({bool simulateOffline = false}) async {
    // We deliberately NEVER pass name, email, password or other form values.
    if (simulateOffline) {
      throw const TipException('Simulated offline connection. Turn off offline mode and retry.');
    }

    if (endpoint.isEmpty) {
      // Deterministic fallback; no network or live model is called.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return const TipResponse(
        text: 'Use a long, unique password and consider a password manager. Never reuse passwords across accounts.',
        isMock: true,
      );
    }

    try {
      final uri = Uri.parse(endpoint);
      if (uri.scheme != 'https') {
        throw const TipException('The instructor service must use HTTPS.');
      }
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(const {
              'task': 'signup_tip',
              'topic': 'password_help',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw const TipException('The tip service is unavailable. Please retry.');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['tip'] is! String ||
          (decoded['tip'] as String).trim().isEmpty) {
        throw const TipException('The tip service returned an invalid response.');
      }
      return TipResponse(
        text: (decoded['tip'] as String).trim(),
        isMock: false,
      );
    } on TimeoutException {
      throw const TipException('The request timed out. Check your connection and retry.');
    } on TipException {
      rethrow;
    } catch (_) {
      throw const TipException('Unable to get a tip. Check your connection and retry.');
    }
  }

  void dispose() => _client.close();
}

class TipResponse {
  const TipResponse({required this.text, required this.isMock});
  final String text;
  final bool isMock;
}

class TipException implements Exception {
  const TipException(this.message);
  final String message;
}

class LaunchpadApp extends StatelessWidget {
  const LaunchpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Launchpad Club',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B4AE6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const SignupPage(),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tipService = SignupTipService();

  bool _obscurePassword = true;
  bool _loadingTip = false;
  bool _simulateOffline = false;
  String? _tipText;
  String? _tipError;
  bool _tipIsMock = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tipService.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your full name.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password.';
    if (value.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo signup complete! Your form passed validation.'),
          backgroundColor: Color(0xFF178058),
        ),
      );
    }
  }

  Future<void> _getTip() async {
    if (_loadingTip) return;
    setState(() {
      _loadingTip = true;
      _tipText = null;
      _tipError = null;
    });
    try {
      final result = await _tipService.requestSignupTip(
        simulateOffline: _simulateOffline,
      );
      if (!mounted) return;
      final text = result.text.trim();
      setState(() {
        _loadingTip = false;
        _tipText = text.length > 240 ? text.substring(0, 240) : text;
        _tipIsMock = result.isMock;
      });
    } on TipException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTip = false;
        _tipError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingTip = false;
        _tipError = 'Unable to load a tip. Please retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Launchpad Club'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: color.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.rocket_launch_outlined, color: Colors.white, size: 36),
                        SizedBox(height: 12),
                        Text(
                          'Your next chapter starts here.',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Join our imaginary learning community. This is a form demo; no account is created.',
                          style: TextStyle(color: Colors.white, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Create your account',
                                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: _validateName,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email address',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                  icon: Icon(_obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined),
                                  onPressed: () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                                ),
                              ),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: _submit,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Sign up'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome_outlined),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('AI Signup Coach',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Request general password guidance. We never send your name, email or password.',
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Simulate offline (for testing)'),
                            value: _simulateOffline,
                            onChanged: _loadingTip
                                ? null
                                : (enabled) => setState(() => _simulateOffline = enabled),
                          ),
                          const SizedBox(height: 4),
                          FilledButton.tonalIcon(
                            onPressed: _loadingTip ? null : _getTip,
                            icon: _loadingTip
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lightbulb_outline),
                            label: Text(_loadingTip ? 'Getting tip...' : 'Get a signup tip'),
                          ),
                          if (_tipText != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              _tipIsMock
                                  ? 'Mock AI-generated advice (no live AI called)'
                                  : 'AI-generated advice',
                              style: TextStyle(
                                color: color.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SelectableText(_tipText!),
                          ],
                          if (_tipError != null) ...[
                            const SizedBox(height: 12),
                            Text(_tipError!, style: const TextStyle(color: Color(0xFFAE2626))),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _getTip,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Advice only. All signup validation stays local on your device.',
                            style: TextStyle(fontSize: 12, color: color.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
