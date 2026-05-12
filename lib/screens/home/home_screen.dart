import 'package:flutter/material.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';
import '../tasks/tasks_screen.dart';
import '../../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Download progress: null = not downloading, 0-100 = in progress.
  int? _downloadProgress;

  static const _screens = <Widget>[
    CalendarScreen(),
    TasksScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;

    final apkUrl = update['apk_url'] as String?;
    final releaseNotes =
        update['release_notes'] as String? ?? 'A new version is ready.';
    final newVersion = update['version'] as String? ?? '';

    if (apkUrl == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Update available${newVersion.isNotEmpty ? ' — v$newVersion' : ''}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(releaseNotes),
                if (_downloadProgress != null) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _downloadProgress! / 100),
                  const SizedBox(height: 6),
                  Text(
                    '$_downloadProgress%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              if (_downloadProgress == null)
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Later'),
                ),
              if (_downloadProgress == null)
                FilledButton(
                  onPressed: () {
                    setDialogState(() => _downloadProgress = 0);
                    UpdateService.downloadAndInstall(
                      apkUrl,
                      onProgress: (p) {
                        if (mounted) {
                          setState(() => _downloadProgress = p);
                          setDialogState(() {});
                        }
                      },
                      onError: (err) {
                        if (mounted) {
                          setState(() => _downloadProgress = null);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update failed: $err')),
                          );
                        }
                      },
                    );
                  },
                  child: const Text('Update now'),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: cs.outline.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => TasksScreen.showAddTaskSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
