import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:win33/features/auth/presentation/login_page.dart';

class SignupWebviewPage extends StatefulWidget {
  final String url;
  const SignupWebviewPage({super.key, required this.url});

  @override
  State<SignupWebviewPage> createState() => _SignupWebviewPageState();
}

class _SignupWebviewPageState extends State<SignupWebviewPage> {
  late final WebViewController controller;

  static const signInUrl = "https://lotto.redefyne.in/sign-in";
  static const signUpUrl = "https://lotto.redefyne.in/sign-up";

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint("PAGE STARTED → $url");

            // ⭐ Redirect detected → close WebView
            if (url.startsWith(signInUrl)) {
              _goToMobileLogin();
            }
          },
          onNavigationRequest: (req) {
            final url = req.url;
            debugPrint("NAV REQUEST → $url");

            // Allow only sign-up and sign-in for redirect detection
            if (url.startsWith(signUpUrl) || url.startsWith(signInUrl)) {
              return NavigationDecision.navigate;
            }

            // Block everything else
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _goToMobileLogin() {
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
