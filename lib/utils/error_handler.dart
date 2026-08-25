import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class for handling errors in a user-friendly way
class ErrorHandler {
  /// Converts technical exceptions to user-friendly messages
  ///
  /// [error] The exception or error to convert
  /// [isAuthContext] Whether this is an authentication context
  /// Returns a user-friendly error message
  static String getUserFriendlyErrorMessage(Object error, {bool isAuthContext = false}) {
    // Network-related errors
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Image loading errors (PlatformException from image_picker)
    if (error is PlatformException) {
      switch (error.code) {
        case 'camera_access_denied':
          return 'Please enable camera access in settings to take photos.';
        case 'gallery_access_denied':
          return 'Please allow access to your photos to upload an image.';
        case 'IMAGE_LOADER_ERROR':
          return 'Unable to load image. Please try again.';
        default:
          return 'Unable to access media. Please check your permissions.';
      }
    }

    // File not found
    if (error is FileSystemException) {
      return 'File not found. Please try again.';
    }

    // Format exceptions (parsing errors)
    if (error is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    // Authentication errors (if in auth context)
    if (isAuthContext) {
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('invalid-email')) {
        return 'Please enter a valid email address.';
      }
      if (errorString.contains('user-disabled')) {
        return 'This account has been disabled. Please contact support.';
      }
      if (errorString.contains('user-not-found') ||
          errorString.contains('wrong-password')) {
        return 'Incorrect email or password. Please try again.';
      }
      if (errorString.contains('email-already-in-use')) {
        return 'An account with this email already exists. Please sign in instead.';
      }
      if (errorString.contains('weak-password')) {
        return 'Password should be at least 6 characters.';
      }
      if (errorString.contains('network-request-failed')) {
        return 'Unable to connect to authentication service. Please check your internet connection.';
      }
    }

    // Generic fallback
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Determines if an error is transient and worth retrying
  static bool isTransientError(Object error) {
    // Network errors are typically transient
    if (error is SocketException) return true;

    // Some platform exceptions might be transient
    if (error is PlatformException) {
      // Service unavailable, internal errors, etc.
      final transientCodes = [
        'INTERNAL_ERROR',
        'SERVICE_UNAVAILABLE',
        'NETWORK_ERROR',
        'TIMEOUT'
      ];
      return transientCodes.contains(error.code);
    }

    return false;
  }
}