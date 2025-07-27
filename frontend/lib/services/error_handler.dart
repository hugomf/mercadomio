import 'dart:async';
import 'package:flutter/material.dart';

enum ErrorType {
  network,
  timeout,
  server,
  parsing,
  unknown,
}

class AppError {
  final ErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  String get userFriendlyMessage {
    switch (type) {
      case ErrorType.network:
        return 'Network connection issue. Please check your internet connection.';
      case ErrorType.timeout:
        return 'Request timed out. Please try again.';
      case ErrorType.server:
        return 'Server error. Please try again later.';
      case ErrorType.parsing:
        return 'Data format error. Please contact support.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}

class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
  });
}

class ErrorHandler {
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt < config.maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt >= config.maxRetries) {
          throw createError(e);
        }

        // Exponential backoff
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).round(),
        );
      }
    }

    throw const AppError(
      type: ErrorType.unknown,
      message: 'Max retries exceeded',
    );
  }

  static AppError createError(dynamic error) {
    if (error is AppError) return error;

    if (error.toString().contains('timeout') || 
        error.toString().contains('TimeoutException')) {
      return AppError(
        type: ErrorType.timeout,
        message: 'Request timed out',
        originalError: error,
      );
    }

    if (error.toString().contains('SocketException') || 
        error.toString().contains('Network')) {
      return AppError(
        type: ErrorType.network,
        message: 'Network error',
        originalError: error,
      );
    }

    if (error.toString().contains('FormatException') || 
        error.toString().contains('JSON')) {
      return AppError(
        type: ErrorType.parsing,
        message: 'Data parsing error',
        originalError: error,
      );
    }

    return AppError(
      type: ErrorType.unknown,
      message: error.toString(),
      originalError: error,
    );
  }

  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    bool showRetry = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error.userFriendlyMessage),
        actions: [
          if (showRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showErrorSnackBar(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userFriendlyMessage),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}