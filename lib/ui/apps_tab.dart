import 'package:flutter/material.dart';

class AppsTab extends StatefulWidget {
  final Future<List<Map<String, String>>> Function() onFetchApps;
  final Function(String) onLaunchApp;

  const AppsTab({
    super.key,
    required this.onFetchApps,
    required this.onLaunchApp,
  });

  @override
  State<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<AppsTab> {
  List<Map<String, String>> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    final apps = await widget.onFetchApps();
    if (mounted) {
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    }
  }

  // Pre-defined vibrant colors for the tiles
  final List<Color> _tileColors = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent.shade700,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.pinkAccent,
    Colors.indigoAccent,
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Keine Apps gefunden',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApps,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2E),
              ),
              child: const Text('Erneut laden'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApps,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _apps.length,
        itemBuilder: (context, index) {
          final app = _apps[index];
          final color = _tileColors[index % _tileColors.length];
          return GestureDetector(
            onTap: () => widget.onLaunchApp(app['identifier']!),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  app['name'] ?? 'Unknown App',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
