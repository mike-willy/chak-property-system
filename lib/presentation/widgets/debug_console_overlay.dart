import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/debug_logger.dart';

class DebugConsoleOverlay extends StatelessWidget {
  final Widget child;

  const DebugConsoleOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 300,
          child: Consumer<DebugLogger>(
            builder: (context, logger, _) {
              if (!logger.isVisible) return const SizedBox.shrink();
              
              return Material(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.grey[900],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Debug Console',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                                onPressed: logger.clear,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: logger.toggleVisibility,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: logger.logs.length,
                        itemBuilder: (context, index) {
                          // Show newest at bottom (or reverse if desired, but standard console is append)
                          // Let's reverse to show newest at top for mobile convenience? 
                          // No, standard log is better.
                          final log = logger.logs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Text(
                              log,
                              style: const TextStyle(
                                color: Colors.greenAccent, 
                                fontFamily: 'monospace', 
                                fontSize: 12
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Positioned(
          right: 16,
          bottom: 100, // Above typical FAB location
          child: Consumer<DebugLogger>(
             builder: (context, logger, _) {
               if (logger.isVisible) return const SizedBox.shrink();
               return FloatingActionButton.small(
                 backgroundColor: Colors.redAccent,
                 child: const Icon(Icons.bug_report, color: Colors.white),
                 onPressed: logger.toggleVisibility,
               );
             }
          ),
        ),
      ],
    );
  }
}
