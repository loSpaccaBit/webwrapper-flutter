import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/cache_service.dart';

/// Screen displayed when the device is offline
class OfflineScreen extends StatefulWidget {
  final OfflineConfig config;
  final VoidCallback onRetry;
  final CacheService? cacheService;
  final Brightness brightness;

  const OfflineScreen({
    super.key,
    required this.config,
    required this.onRetry,
    this.cacheService,
    required this.brightness,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  List<Map<String, dynamic>> _cachedPages = [];
  bool _showCachedPages = false;

  @override
  void initState() {
    super.initState();
    _loadCachedPages();
  }

  Future<void> _loadCachedPages() async {
    if (widget.cacheService != null) {
      final pages = await widget.cacheService!.getCachedPages();
      setState(() {
        _cachedPages = pages;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current colors based on brightness
    final colors = widget.config.getColors(widget.brightness);

    return Container(
      color: colors.backgroundColor,
      child: SafeArea(
        child: _showCachedPages && _cachedPages.isNotEmpty
            ? _buildCachedPagesList(colors)
            : _buildOfflineMessage(colors),
      ),
    );
  }

  Widget _buildOfflineMessage(OfflineColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Offline icon
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: colors.textColor.withAlpha(153),
            ),
            const SizedBox(height: 24),

            // Main message
            Text(
              widget.config.message,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle message
            Text(
              widget.config.subtitle,
              style: TextStyle(
                fontSize: 16,
                color: colors.textColor.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Cached pages info
            if (_cachedPages.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.textColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      color: colors.textColor.withAlpha(179),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_cachedPages.length} pagine disponibili offline',
                      style: TextStyle(
                        color: colors.textColor.withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showCachedPages = true;
                        });
                      },
                      child: Text(
                        'Visualizza pagine salvate',
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Retry button
            if (widget.config.showRetryButton)
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(widget.config.retryButtonText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: colors.textColor,
                  foregroundColor: colors.backgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCachedPagesList(OfflineColors colors) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: colors.textColor.withAlpha(26),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: colors.textColor),
                onPressed: () {
                  setState(() {
                    _showCachedPages = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pagine Salvate (Offline)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of cached pages
        Expanded(
          child: ListView.builder(
            itemCount: _cachedPages.length,
            itemBuilder: (context, index) {
              final page = _cachedPages[index];
              final timestamp = DateTime.fromMillisecondsSinceEpoch(
                page['timestamp'] as int,
              );

              return ListTile(
                leading: Icon(
                  Icons.article_outlined,
                  color: colors.textColor.withAlpha(179),
                ),
                title: Text(
                  page['title'] ?? 'Senza titolo',
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${_formatTimestamp(timestamp)}\n${page['url']}',
                  style: TextStyle(
                    color: colors.textColor.withAlpha(153),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                onTap: () {
                  // L'utente può vedere la pagina in cache, ma non caricarla senza connessione
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Riconnettiti per visualizzare questa pagina'),
                      action: SnackBarAction(
                        label: 'Riprova',
                        onPressed: widget.onRetry,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Bottom button
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(widget.config.retryButtonText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              backgroundColor: colors.textColor,
              foregroundColor: colors.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} giorni fa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ore fa';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuti fa';
    } else {
      return 'Poco fa';
    }
  }
}
