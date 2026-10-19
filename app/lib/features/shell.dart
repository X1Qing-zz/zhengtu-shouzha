import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../widgets/nav_bar.dart';
import '../widgets/season_backdrop.dart';
import 'calendar/calendar_page.dart';
import 'diary/diary_page.dart';
import 'home/home_page.dart';
import 'ledger/ledger_page.dart';
import 'tasks/tasks_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const SeasonBackdrop(),
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              _KeepAlivePage(child: HomePage(onNavigate: _select)),
              const _KeepAlivePage(child: TasksPage()),
              const _KeepAlivePage(child: DiaryPage()),
              const _KeepAlivePage(child: LedgerPage()),
              const _KeepAlivePage(child: CalendarPage()),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(index: _index, onTap: _select),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
