import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/offline_manager.dart';

class ConnectionIndicator extends StatelessWidget {
  final bool showWhenOnline;
  final EdgeInsets padding;

  const ConnectionIndicator({
    super.key,
    this.showWhenOnline = false,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineManager>(
      builder: (context, offlineManager, child) {
        if (!offlineManager.isInitialized) {
          return const SizedBox.shrink();
        }

        // Solo mostrar cuando esté offline o sincronizando (a menos que se especifique lo contrario)
        if (offlineManager.isOnline && !showWhenOnline && offlineManager.pendingOperations == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: padding,
          child: _buildIndicatorContent(context, offlineManager),
        );
      },
    );
  }

  Widget _buildIndicatorContent(BuildContext context, OfflineManager offlineManager) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message = offlineManager.getStatusMessage();

    switch (offlineManager.status) {
      case OfflineStatus.online:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.cloud_done;
        break;
      case OfflineStatus.offline:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.cloud_off;
        break;
      case OfflineStatus.syncing:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.sync;
        break;
      case OfflineStatus.syncError:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.error;
        break;
    }

    return Card(
      color: backgroundColor,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (offlineManager.isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (offlineManager.status == OfflineStatus.syncError)
              IconButton(
                icon: Icon(Icons.refresh, color: textColor, size: 16),
                onPressed: () => offlineManager.forceSync(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

class FloatingConnectionIndicator extends StatelessWidget {
  const FloatingConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineManager>(
      builder: (context, offlineManager, child) {
        if (!offlineManager.isInitialized || 
            (offlineManager.isOnline && offlineManager.pendingOperations == 0)) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: ConnectionIndicator(
              showWhenOnline: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
          ),
        );
      },
    );
  }
}

class ConnectionStatusIcon extends StatelessWidget {
  final double size;
  
  const ConnectionStatusIcon({
    super.key,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineManager>(
      builder: (context, offlineManager, child) {
        if (!offlineManager.isInitialized) {
          return Icon(Icons.help_outline, size: size, color: Colors.grey);
        }

        IconData icon;
        Color color;
        
        switch (offlineManager.status) {
          case OfflineStatus.online:
            icon = offlineManager.pendingOperations > 0 ? Icons.cloud_sync : Icons.cloud_done;
            color = Colors.green;
            break;
          case OfflineStatus.offline:
            icon = Icons.cloud_off;
            color = Colors.orange;
            break;
          case OfflineStatus.syncing:
            return SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          case OfflineStatus.syncError:
            icon = Icons.error;
            color = Colors.red;
            break;
        }

        return GestureDetector(
          onTap: () => _showStatusDialog(context, offlineManager),
          child: Icon(icon, size: size, color: color),
        );
      },
    );
  }

  void _showStatusDialog(BuildContext context, OfflineManager offlineManager) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Estado de Conexión'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offlineManager.getStatusMessage()),
              if (offlineManager.pendingOperations > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Operaciones pendientes: ${offlineManager.pendingOperations}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (offlineManager.lastError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Último error: ${offlineManager.lastError}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (offlineManager.status == OfflineStatus.syncError)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  offlineManager.forceSync();
                },
                child: const Text('Reintentar'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
