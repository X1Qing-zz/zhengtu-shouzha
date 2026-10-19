import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_store.dart';
import '../widgets/nav_bar.dart';
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

  void _select(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppStore>();
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(onNavigate: _select),
          const CalendarPage(),
          const DiaryPage(),
          const TasksPage(),
          const LedgerPage(),
        ],
      ),
      bottomNavigationBar: AppNavBar(index: _index, onTap: _select),
    );
  }
}
