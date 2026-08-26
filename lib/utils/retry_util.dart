import 'dart:async';
import '../utils/error_handler.dart';

/// Utility class for retrying asynchronous operations with exponential backoff
class RetryUtil {
  /// Retries an asynchronous operation with exponential backoff
  ///
  /// [operation] is the async function to retry
  /// [maxAttempts] is the maximum number of attempts (default: 3)
  /// [initialDelay] is the initial delay between attempts in milliseconds (default: 500)
  /// [maxDelay] is the maximum delay between attempts in milliseconds (default: 5000)
  /// [backoffMultiplier] is the multiplier for exponential backoff (default: 2.0)
  /// [retryIf] optional predicate to control which errors should be retried.
  ///          By default, retries on transient errors (network issues, etc.)
  ///          Errors (programming bugs like ArgumentError, StateError) are NEVER retried.
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    int initialDelay = 500,
    int maxDelay = 5000,
    double backoffMultiplier = 2.0,
    bool Function(Object)? retryIf,
  }) async {
    int attempt = 0;
    double delay = initialDelay.toDouble();

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (e) {
        // Never retry programming Errors (ArgumentError, StateError, OutOfMemoryError, etc.)
        // These indicate bugs that should fail fast, not be silently retried.
        if (e is Error) {
          rethrow;
        }

        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Check custom predicate OR default transient error check
        final shouldRetry = retryIf?.call(e) ?? ErrorHandler.isTransientError(e);
        if (!shouldRetry) {
          rethrow; // Don't retry non-transient errors
        }

        // Wait for the delay period
        await Future.delayed(Duration(milliseconds: delay.toInt()));

        // Calculate next delay with exponential backoff (clamped to maxDelay)
        delay = (delay * backoffMultiplier).clamp(initialDelay.toDouble(), maxDelay.toDouble());
      }
    }
  }

  /// Retries an asynchronous operation with fixed delay
  static Future<T> retryOperationFixedDelay<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    int delayMs = 1000,
    bool Function(Object)? retryIf,
  }) async {
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (e) {
        // Never retry programming Errors
        if (e is Error) {
          rethrow;
        }

        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Check custom predicate OR default transient error check
        final shouldRetry = retryIf?.call(e) ?? ErrorHandler.isTransientError(e);
        if (!shouldRetry) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}

/// Extension for easier retry usage on Futures
extension RetryExtension<T> on Future<T> {
  /// Retries this future with exponential backoff
  Future<T> retry({
    int maxAttempts = 3,
    int initialDelay = 500,
    int maxDelay = 5000,
    double backoffMultiplier = 2.0,
    bool Function(Object)? retryIf,
  }) async => RetryUtil.retryOperation<T>(
        () async => await this,
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
        maxDelay: maxDelay,
        backoffMultiplier: backoffMultiplier,
        retryIf: retryIf,
      );
}