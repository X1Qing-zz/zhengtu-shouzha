import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_info.dart';
import '../core/theme.dart';
import '../state/app_store.dart';
import '../widgets/common.dart';
import '../widgets/compass_mark.dart';
import 'launch/launch_targets.dart';
import 'shell.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _enter({bool skipName = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final store = context.read<AppStore>();
    await store.completeOnboarding(name: skipName ? null : _nameController.text);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => const RootShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.02, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.bg, c.sunken.withValues(alpha: 0.8), c.bg],
                ),
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.22,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.accent.withValues(alpha: c.isDark ? 0.16 : 0.12),
                    c.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            left: -size.width * 0.3,
            child: Container(
              width: size.width,
              height: size.width,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.moss.withValues(alpha: c.isDark ? 0.06 : 0.045),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    28,
                    18,
                    28,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CompassMark(
                              key: LaunchTargets.onboardingCompass,
                              size: 28,
                              color: c.ink,
                              accent: c.accent,
                              stroke: 2.4,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ZHENGTU · SHOUZHA',
                              style: AppText.eyebrow(color: c.muted, size: 9.5),
                            ),
                            const Spacer(),
                            TagChip(label: kAppVersionShort, color: c.moss, dense: true),
                          ],
                        ),
                        const SizedBox(height: 54),
                        CompassMark(size: 96, color: c.ink, accent: c.accent, rotating: true),
                        const SizedBox(height: 34),
                        Text(
                          '征途手札',
                          style: AppText.serifStyle(
                            size: 46,
                            color: c.ink,
                            height: 1.1,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '把平凡的日子，写成一场冒险。',
                          style: AppText.serifStyle(
                            size: 16,
                            weight: FontWeight.w400,
                            color: c.inkSoft,
                            letterSpacing: 1.6,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          '在这里，你会记下每日手札、主线与支线、每一笔开销，\n也会收到天气情报和一点恰到好处的谏言。',
                          style: AppText.sans(size: 13, color: c.muted, height: 1.95),
                        ),
                        const SizedBox(height: 56),
                        Text(
                          '冒险者，怎么称呼你？',
                          style: AppText.sans(
                            size: 11,
                            weight: FontWeight.w600,
                            color: c.inkSoft,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _enter(),
                          style: AppText.serifStyle(size: 18, color: c.ink),
                          decoration: fieldDecoration(
                            context,
                            hint: '留空的话，就叫你「冒险者」',
                            prefix: Icon(Icons.person_outline_rounded, size: 19, color: c.muted),
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: '启程',
                          icon: Icons.north_east_rounded,
                          loading: _busy,
                          onPressed: _enter,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : () => _enter(skipName: true),
                            child: Text(
                              '先随便逛逛',
                              style: AppText.sans(size: 12, color: c.muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
