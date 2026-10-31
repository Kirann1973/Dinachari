import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../providers.dart';
import '../services/widget_sync.dart';
import 'archived_screen.dart';
import 'habit_editor.dart';
import 'history_screen.dart';
import 'plant_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';

enum Section {
  today('Today', Icons.today_outlined, Icons.today),
  history('History', Icons.history, Icons.history),
  stats('Graphs', Icons.bar_chart_outlined, Icons.bar_chart),
  plant('Plant', Icons.local_florist_outlined, Icons.local_florist),
  archived('Archived', Icons.inventory_2_outlined, Icons.inventory_2);

  const Section(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Lets any screen switch the shell to another section.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.go, required super.child});

  final ValueChanged<Section> go;

  static ShellScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => false;
}

/// The app frame: a side menu (a drawer on phones, a panel you can hide on
/// wider screens) with Today, History, Graphs, Plant and Archived.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initial = Section.today});

  /// The section shown first.
  final Section initial;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Section _section = widget.initial;
  bool _panelOpen = true;

  static const _wide = 720.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pick up ticks made on the widget, and roll "today" over at midnight.
      WidgetSync.applyPending(ref.read(habitRepositoryProvider))
          .then((_) => ref.invalidate(habitsProvider));
    }
  }

  void _go(Section s) {
    setState(() => _section = s);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keeps reminders booked whenever habits or reminders change.
    ref.watch(reminderSchedulerProvider);

    final wide = MediaQuery.sizeOf(context).width >= _wide;
    final body = switch (_section) {
      Section.today => const TodayView(),
      Section.history => const HistoryScreen(),
      Section.stats => const StatsView(),
      Section.plant => const PlantView(),
      Section.archived => const ArchivedView(),
    };

    return ShellScope(
      go: _go,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: wide
            ? null
            : Drawer(
                backgroundColor: DC.background,
                child: SafeArea(
                  child: _Menu(selected: _section, onSelect: _go),
                ),
              ),
        floatingActionButton: _section == Section.today
            ? FloatingActionButton.extended(
                onPressed: () => openHabitEditor(context),
                icon: const Icon(Icons.add),
                label: const Text(
                  'New habit',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : null,
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    width: _panelOpen ? 232 : 0,
                    child: _panelOpen
                        ? _Menu(selected: _section, onSelect: _go)
                        : null,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      section: _section,
                      menuOpen: wide && _panelOpen,
                      onMenu: () {
                        if (wide) {
                          setState(() => _panelOpen = !_panelOpen);
                        } else {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      },
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: body,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.section,
    required this.menuOpen,
    required this.onMenu,
  });

  final Section section;
  final bool menuOpen;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final isToday = section == Section.today;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 17, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: menuOpen ? 'Hide menu' : 'Show menu',
            color: Colors.white,
            onPressed: onMenu,
            icon: Icon(menuOpen ? Icons.menu_open : Icons.menu),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Dinachari' : section.label,
                  style: const TextStyle(
                    fontFamily: DC.display,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (isToday)
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: const TextStyle(fontSize: 14, color: DC.onDark),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.selected, required this.onSelect});

  final Section selected;
  final ValueChanged<Section> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF151A28),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Text(
              'Dinachari',
              style: TextStyle(
                fontFamily: DC.display,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          for (final s in Section.values) ...[
            if (s == Section.archived)
              const Divider(color: Colors.white12, height: 24),
            _MenuItem(
              section: s,
              selected: s == selected,
              onTap: () => onSelect(s),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? DC.accentDeep : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Semantics(
            selected: selected,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    selected ? section.selectedIcon : section.icon,
                    color: selected ? Colors.white : DC.onDark,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    section.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : DC.onDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
