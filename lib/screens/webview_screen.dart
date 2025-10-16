import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../config/app_config.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/url_interceptor_service.dart';

/// Fullscreen WebView with gesture navigation
class WebViewScreen extends StatefulWidget {
  final AppConfig config;

  const WebViewScreen({
    super.key,
    required this.config,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _webViewController;
  late final ConnectivityService _connectivityService;
  late final CacheService _cacheService;
  late final URLInterceptorService _urlInterceptorService;

  // Connectivity tracking
  bool? _previousConnectionState; // null = non ancora inizializzato

  // Gesture navigation state
  bool _canGoBack = false;
  Offset? _startPosition;
  double _dragDistance = 0.0;
  bool _isDragging = false;
  static const double _edgeThreshold = 20.0; // 20px dal bordo

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeWebView();
  }

  /// Initialize services
  void _initializeServices() {
    _connectivityService = ConnectivityService();
    _cacheService = CacheService();
    _urlInterceptorService = URLInterceptorService(
      nativeUrlPrefixes: widget.config.nativeUrlHandlers,
    );

    // Listen to connectivity changes
    _connectivityService.initialize();
    _connectivityService.connectionStatus.listen((isConnected) {
      if (!mounted) return;

      // Se è il primo check, salva lo stato senza mostrare toast
      if (_previousConnectionState == null) {
        _previousConnectionState = isConnected;
        return;
      }

      // Mostra toast solo se lo stato è cambiato
      if (_previousConnectionState != isConnected) {
        if (!isConnected) {
          // Appena andato offline
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Sei offline'),
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Connessione ripristinata
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Connessione ripristinata'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _webViewController.reload();
        }

        _previousConnectionState = isConnected;
      }
    });
  }

  /// Initialize WebView
  void _initializeWebView() {
    // Platform-specific parameters (best practice da documentazione ufficiale)
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      // iOS/macOS specific settings
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback:
            widget.config.webview.allowInlineMediaPlayback,
        mediaTypesRequiringUserAction:
            widget.config.webview.allowMediaPlayback
                ? const <PlaybackMediaTypes>{}
                : {
                    PlaybackMediaTypes.audio,
                    PlaybackMediaTypes.video,
                  },
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    // Create controller with platform-specific params
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Platform-specific settings (best practice da documentazione ufficiale)
    if (controller.platform is AndroidWebViewController) {
      // Enable debugging in debug mode
      AndroidWebViewController.enableDebugging(kDebugMode);

      // Set media playback requirements
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(
        !widget.config.webview.allowMediaPlayback,
      );
    }

    // Gestione cookie
    final cookieManager = WebViewCookieManager();
    if (widget.config.webview.clearCookiesOnStart) {
      cookieManager.clearCookies();
    }
    // I cookie vengono automaticamente salvati e ripristinati tra le sessioni

    // Configure WebView
    controller
      ..setJavaScriptMode(
        widget.config.webview.enableJavascript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(Colors.white) // Best practice per performance
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Progress tracking can be added if needed
          },
          onPageStarted: (String url) {
            _cacheService.saveLastUrl(url);
          },
          onPageFinished: (String url) async {
            _updateCanGoBack();

            // Salva pagina in cache con titolo
            try {
              final title =
                  await _webViewController.getTitle() ?? 'Pagina senza titolo';
              _cacheService.cachePage(url, title);
            } catch (e) {
              // Silently fail
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Filter per mostrare solo errori del frame principale
            if (error.isForMainFrame ?? false) {
              // Ignora errore -999 (NSURLErrorCancelled) su iOS
              // Questo errore è normale quando la navigazione viene cancellata
              if (error.errorCode == -999) {
                return;
              }

              debugPrint('''
WebView Resource Error (Main Frame):
  Code: ${error.errorCode}
  Description: ${error.description}
  Type: ${error.errorType}
  URL: ${error.url ?? 'unknown'}
              ''');
            }
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('''
HTTP Error:
  Status Code: ${error.response?.statusCode}
  URL: ${error.response?.uri}
              ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Intercept native URLs
            return _urlInterceptorService.handleNavigationRequest(request.url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.config.app.websiteUrl));

    // Set user agent if specified
    if (widget.config.webview.userAgent != null) {
      controller.setUserAgent(widget.config.webview.userAgent);
    }

    // Clear cache if configured (sconsigliato per offline mode)
    if (widget.config.webview.clearCacheOnStart) {
      _cacheService.clearCache(controller);
    } else {
      // Abilita caching per offline mode
      _cacheService.enableWebViewCache(controller);
    }

    _webViewController = controller;
  }

  /// Update can go back state
  Future<void> _updateCanGoBack() async {
    final canGoBack = await _webViewController.canGoBack();
    if (mounted && canGoBack != _canGoBack) {
      setState(() {
        _canGoBack = canGoBack;
      });
    }
  }

  /// Handle back navigation
  Future<bool> _handleBackNavigation() async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
      _updateCanGoBack();
      return false;
    }
    return true;
  }

  /// Handle pointer down event
  void _handlePointerDown(PointerDownEvent event) {
    // Swipe da sinistra = indietro
    if (event.position.dx < _edgeThreshold && _canGoBack) {
      setState(() {
        _startPosition = event.position;
        _isDragging = false;
        _dragDistance = 0.0;
      });
    }
  }

  /// Handle pointer move event
  void _handlePointerMove(PointerMoveEvent event) {
    if (_startPosition == null || !_canGoBack) return;

    final dx = event.position.dx - _startPosition!.dx;

    // Swipe verso destra
    if (dx > 10 && !_isDragging) {
      setState(() {
        _isDragging = true;
      });
    }

    if (_isDragging && dx > 0) {
      setState(() {
        _dragDistance = dx.clamp(0.0, MediaQuery.of(context).size.width);
      });
    }
  }

  /// Handle pointer up event
  void _handlePointerUp(PointerUpEvent event) {
    if (_startPosition == null) return;

    final threshold = MediaQuery.of(context).size.width * 0.3;

    if (_canGoBack && _isDragging && _dragDistance > threshold) {
      _handleBackNavigation();
    }

    setState(() {
      _isDragging = false;
      _dragDistance = 0.0;
      _startPosition = null;
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get current brightness (for system theme mode)
    final currentBrightness = MediaQuery.of(context).platformBrightness;

    // Get theme based on current brightness
    final currentTheme = widget.config.theme.getTheme(currentBrightness);

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: currentTheme.statusBarColor,
        statusBarIconBrightness: currentTheme.statusBarBrightness,
        statusBarBrightness: currentTheme.statusBarBrightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackNavigation();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: currentTheme.backgroundColor,
        body: SafeArea(
          bottom: false, // Rimuove padding bianco in basso
          child: Listener(
            // iOS-style horizontal swipe to go back - NON blocca touch della WebView
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            child: Transform.scale(
              scale: _isDragging ? 1 - (_dragDistance / 2000) : 1.0,
              child: Opacity(
                opacity: _isDragging ? 1 - (_dragDistance / 800).clamp(0, 0.3) : 1.0,
                child: WebViewWidget(controller: _webViewController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
