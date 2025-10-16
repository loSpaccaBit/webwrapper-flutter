import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Service to intercept and handle native URLs
class URLInterceptorService {
  final List<String> _nativeUrlPrefixes;

  URLInterceptorService({required List<String> nativeUrlPrefixes})
      : _nativeUrlPrefixes = nativeUrlPrefixes;

  /// Check if URL should be handled by a native app
  bool shouldInterceptUrl(String url) {
    for (String prefix in _nativeUrlPrefixes) {
      if (url.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /// Handle navigation request and intercept native URLs
  NavigationDecision handleNavigationRequest(String url) {
    if (shouldInterceptUrl(url)) {
      // Open in native app
      launchNativeUrl(url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  /// Launch URL in native app
  Future<void> launchNativeUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Silently fail if URL launch fails
    }
  }

  /// Launch URL with specific mode
  Future<bool> launchUrlWithMode(
    String url, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
