import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class PerformanceOptimizer {
  static final Logger _logger = Logger();

  /// Optimize widget rebuild by using const constructors and selective rebuild
  static Widget optimizeBuild(BuildContext context, Widget child) {
    return MediaQuery(
      // Reduce rebuilds when screen size changes
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(
          // Clamp text scale between 0.8 and 1.2 to prevent extreme scaling
          MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
        ),
      ),
      child: child,
    );
  }

  /// Add loading indicator that doesn't block UI
  static Widget addNonBlockingLoader(Widget child, bool isLoading) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Debounce function calls to prevent too many API calls
  static void debounce(VoidCallback fn,
      {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, fn);
  }

  static Timer? _debounceTimer;

  /// Preload heavy data in background
  static Future<void> preloadData<T>(
    Future<T> Function() loader,
    String preloadMessage,
  ) async {
    try {
      _logger.i('Preloading: $preloadMessage');
      await loader();
      _logger.i('Preloaded: $preloadMessage');
    } catch (e) {
      _logger.e('Failed to preload $preloadMessage: $e');
    }
  }

  /// Optimize large list rendering
  static Widget optimizeListView<T>(
    List<T> items,
    Widget Function(BuildContext, int, T) itemBuilder, {
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      padding: padding,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return RepaintBoundary(
          child: itemBuilder(context, index, item),
        );
      },
      cacheExtent: 300, // Reduce cache to improve performance
    );
  }

  /// Add performance monitoring to widget
  static Widget withPerformanceMonitoring(
    Widget child,
    String widgetName,
  ) {
    final stopwatch = Stopwatch()..start();

    return Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          final duration = stopwatch.elapsedMilliseconds;
          if (duration > 16) {
            // If frame takes more than 16ms (60fps threshold)
            _logger.w(
                'Performance warning: $widgetName took ${duration}ms to render');
          }
        });

        return child;
      },
    );
  }

  /// Memory management helpers
  static void disposeResources(List<dynamic> disposables) {
    for (final disposable in disposables) {
      try {
        if (disposable is IDisposable) {
          disposable.dispose();
        } else if (disposable is Listenable) {
          disposable.removeListener(() {});
        }
      } catch (e) {
        _logger.e('Error disposing resource: $e');
      }
    }
  }

  /// Optimize chart rendering
  static Widget optimizeChart(Widget chart,
      {bool enableHardwareAcceleration = true}) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: chart,
      ),
    );
  }

  /// Batch updates to prevent multiple rebuilds
  static void batchUpdate(VoidCallback updates) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updates();
    });
  }

  /// Add loading skeleton for better UX during data loading
  static Widget buildLoadingSkeleton({
    required BuildContext context,
    required Widget child,
    bool isLoading = false,
  }) {
    if (!isLoading) return child;

    // Simple loading animation instead of shimmer
    return AnimatedOpacity(
      opacity: isLoading ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  /// Create optimized container for statistics cards
  static Widget buildOptimizedCard({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  /// Prevent UI freeze by adding async gap
  static Widget addAsyncGap(Widget child, Duration delay) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return child;
      },
    );
  }
}

/// Interface for disposable resources
abstract class IDisposable {
  void dispose();
}

/// Memory-efficient data caching
class DataCache<T> {
  final int maxSize;
  final Duration expiration;
  final Map<String, CacheEntry<T>> _cache = {};

  DataCache({
    this.maxSize = 100,
    this.expiration = const Duration(minutes: 5),
  });

  void put(String key, T value) {
    _evictExpired();
    _cache[key] = CacheEntry(value, DateTime.now());

    if (_cache.length > maxSize) {
      _evictLRU();
    }
  }

  T? get(String key) {
    _evictExpired();
    final entry = _cache[key];
    if (entry != null) {
      entry.lastAccessed = DateTime.now();
      return entry.value;
    }
    return null;
  }

  void clear() {
    _cache.clear();
  }

  void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere(
        (key, entry) => now.difference(entry.createdAt) > expiration);
  }

  void _evictLRU() {
    final sortedEntries = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    final entriesToRemove =
        sortedEntries.take((_cache.length - maxSize).clamp(0, maxSize));

    for (final entry in entriesToRemove) {
      _cache.remove(entry.key);
    }
  }
}

class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  DateTime lastAccessed;

  CacheEntry(this.value, this.createdAt) : lastAccessed = createdAt;
}
