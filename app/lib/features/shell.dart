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
import 'memo/memo_page.dart';
import 'tasks/tasks_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  bool _memoOpen = false;
  late final PageController _pageController = PageController(initialPage: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _index && !_memoOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      _index = index;
      _memoOpen = false;
    });
    _pageController.animateToPage(
      index + 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    if (page == 0) {
      if (_memoOpen) return;
      HapticFeedback.selectionClick();
      setState(() => _memoOpen = true);
      return;
    }

    final index = page - 1;
    if (index == _index && !_memoOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      _index = index;
      _memoOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    return PopScope(
      canPop: !_memoOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _memoOpen) _select(0);
      },
      child: Scaffold(
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
                _KeepAlivePage(child: MemoPage(onClose: () => _select(0))),
                _KeepAlivePage(child: HomePage(onNavigate: _select)),
                const _KeepAlivePage(child: TasksPage()),
                const _KeepAlivePage(child: DiaryPage()),
                const _KeepAlivePage(child: LedgerPage()),
                const _KeepAlivePage(child: CalendarPage()),
              ],
            ),
          ],
        ),
        bottomNavigationBar:
            _memoOpen ? null : AppNavBar(index: _index, onTap: _select),
      ),
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
