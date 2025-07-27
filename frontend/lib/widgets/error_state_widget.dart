import 'package:flutter/material.dart';
import '../services/error_handler.dart';

class ErrorStateWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback onRetry;
  final bool isRetrying;

  const ErrorStateWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.isRetrying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getErrorIcon(),
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _getErrorTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.userFriendlyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(isRetrying ? 'Retrying...' : 'Retry'),
                ),
                if (error.type == ErrorType.network) ...[
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.wifi),
                    label: const Text('Check Connection'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.timer_off;
      case ErrorType.server:
        return Icons.dns;
      case ErrorType.parsing:
        return Icons.broken_image;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.parsing:
        return 'Data Error';
      case ErrorType.unknown:
        return 'Something Went Wrong';
    }
  }
}