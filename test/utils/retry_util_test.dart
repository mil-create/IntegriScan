
import 'package:flutter_test/flutter_test.dart';
import 'package:integriscan/utils/retry_util.dart';
import 'dart:io';

void main() {
  group('RetryUtil', () {
    test('retryOperation throws immediately on Error', () async {
      expect(
        () async => await RetryUtil.retryOperation<int>(
              () async => throw ArgumentError('Invalid argument'),
              maxAttempts: 3,
            ),
        throwsA(isArgumentError),
      );
    });

    test('retryOperation throws immediately on StateError', () async {
      expect(
        () async => await RetryUtil.retryOperation<int>(
              () async => throw StateError('Invalid state'),
              maxAttempts: 3,
            ),
        throwsA(isStateError),
      );
    });

    test('retryOperation retries on SocketException', () async {
      int attemptCount = 0;
      final result = await RetryUtil.retryOperation<int>(
        () async {
          attemptCount++;
          if (attemptCount < 3) throw const SocketException('Network error');
          return 42;
        },
        maxAttempts: 5,
      );
      expect(result, equals(42));
      expect(attemptCount, equals(3));
    });

    test('retryOperationFixedDelay throws immediately on Error', () async {
      expect(
        () async => await RetryUtil.retryOperationFixedDelay<int>(
              () async => throw ArgumentError('Invalid argument'),
              maxAttempts: 3,
            ),
        throwsA(isArgumentError),
      );
    });

    test('retryOperation respects retryIf predicate', () async {
      int attemptCount = 0;
      final result = await RetryUtil.retryOperation<int>(
        () async {
          attemptCount++;
          if (attemptCount < 2) throw const SocketException('Network error');
          return 42;
        },
        maxAttempts: 5,
        retryIf: (e) => e is SocketException,
      );
      expect(result, equals(42));
      expect(attemptCount, equals(2));
    });

    test('retryOperation does not retry when retryIf returns false', () async {
      int attemptCount = 0;
      expect(
        () async => await RetryUtil.retryOperation<int>(
              () async {
                attemptCount++;
                throw const SocketException('Network error');
              },
              maxAttempts: 5,
              retryIf: (e) => false, // Never retry
            ),
        throwsA(isInstanceOf<SocketException>()),
      );
      expect(attemptCount, equals(1)); // Only tried once
    });
  });
}