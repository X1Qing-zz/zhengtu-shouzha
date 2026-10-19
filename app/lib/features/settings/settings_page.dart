import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_info.dart';
import '../../core/date_utils.dart';
import '../../core/season.dart';
import '../../core/season_visuals.dart';
import '../../core/theme.dart';
import '../../data/backup_service.dart';
import '../../state/app_store.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';
import '../../widgets/season_backdrop.dart';
import '../weather/weather_page.dart';
import '../weekly/weekly_review_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final c = context.colors;
    final initial = store.name.trim().isEmpty ? '旅' : store.name.trim().substring(0, 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: SeasonBackdrop()),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: c.inkSoft,
                ),
                const Spacer(),
                Text('MY JOURNEY', style: AppText.eyebrow(color: c.muted, size: 9)),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),
            PaperCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: c.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accent.withValues(alpha: 0.45), width: 1.4),
                    ),
                    alignment: Alignment.center,
                    child: Text(initial, style: AppText.serifStyle(size: 24, color: c.bg)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: AppText.serifStyle(size: 21, color: c.ink)),
                        const SizedBox(height: 4),
                        Text(
                          '征途的第 ${store.recordDays} 个脚印 · ${store.cityName}',
                          style: AppText.sans(size: 10.5, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _editName(context, store),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                      decoration: BoxDecoration(
                        color: c.sunken.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '修改称呼',
                        style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: c.inkSoft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            _SectionLabel('外观'),
            const SizedBox(height: 10),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6_outlined, size: 17, color: c.accent),
                      const SizedBox(width: 9),
                      Text('主题', style: AppText.sans(size: 13, weight: FontWeight.w500, color: c.ink)),
                      const Spacer(),
                      Text(
                        _themeLabel(store.themeMode),
                        style: AppText.sans(size: 10.5, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PillSelector(
                    options: const ['跟随系统', '浅色', '深色'],
                    selected: store.themeMode.index,
                    onChanged: (index) => store.setThemeMode(ThemeMode.values[index]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.eco_outlined, size: 13, color: c.moss),
                      const SizedBox(width: 6),
                      Text(
                        '当前季节配色：${Season.of(DateTime.now()).label} · ${Season.of(DateTime.now()).paletteName}',
                        style: AppText.sans(size: 10.5, color: c.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final season in Season.values)
                        Expanded(
                          child: _SeasonSwatch(
                            season: season,
                            current: season == Season.of(DateTime.now()),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel('天气情报'),
            const SizedBox(height: 10),
            PaperCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.near_me_outlined,
                    title: '当前城市',
                    subtitle: store.cityName,
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
                    onTap: () => showAppSheet<void>(context, const CitySearchSheet()),
                  ),
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  _SettingRow(
                    icon: Icons.gps_fixed_rounded,
                    title: '自动定位',
                    subtitle: '开启后优先使用当前位置',
                    trailing: Switch.adaptive(
                      value: store.autoLocation,
                      activeTrackColor: c.accent,
                      onChanged: (value) async {
                        await store.setAutoLocation(value);
                        if (!context.mounted) return;
                        final error = store.weatherError;
                        if (value && error != null) {
                          showAppSnack(context, error);
                        }
                      },
                    ),
                    onTap: null,
                  ),
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  _SettingRow(
                    icon: Icons.refresh_rounded,
                    title: '刷新天气',
                    subtitle: store.weather == null
                        ? '还没有获取到天气'
                        : '${store.weather!.condition} ${store.weather!.temp.round()}°',
                    trailing: store.weatherLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 1.8, color: c.accent),
                          )
                        : Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
                    onTap: () => store.loadWeather(force: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel('我的数据'),
            const SizedBox(height: 10),
            PaperCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: StatBlock(value: '${store.totalDiaries}', label: '手札 / 篇', tone: c.accent)),
                      Expanded(child: StatBlock(value: '${store.totalDoneCount}', label: '完成任务', tone: c.moss)),
                      Expanded(child: StatBlock(value: '${store.expenses.length}', label: '账目 / 笔', tone: c.terra)),
                      Expanded(child: StatBlock(value: '${store.recordDays}', label: '足迹 / 天', tone: c.ink)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  _SettingRow(
                    icon: Icons.auto_awesome_outlined,
                    title: '冒险周报',
                    subtitle: '这一周的统计、手札精灵建议与分享卡片',
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WeeklyReviewPage()),
                    ),
                  ),
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: c.mossSoft.withValues(alpha: c.isDark ? 0.45 : 0.55),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 13, color: c.moss),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '所有记录都只保存在这台设备上，不会上传。',
                              style: AppText.sans(size: 10, color: c.inkSoft.withValues(alpha: 0.85)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel('备份与恢复'),
            const SizedBox(height: 10),
            PaperCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.archive_outlined,
                    title: '导出备份',
                    subtitle: _backupSubtitle(store.lastBackupAt),
                    trailing: Icon(Icons.ios_share_rounded, size: 17, color: c.muted),
                    onTap: () => _exportBackup(context, store),
                  ),
                  if (store.latestBackupFile != null) ...[
                    Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                    _SettingRow(
                      icon: Icons.settings_backup_restore_rounded,
                      title: '恢复最近备份',
                      subtitle: '应用内保留的上一次导出',
                      trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
                      onTap: () => _restoreLatest(context, store),
                    ),
                  ],
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  _SettingRow(
                    icon: Icons.restore_rounded,
                    title: '从备份恢复',
                    subtitle: '选择 ZIP，替换当前全部记录与照片',
                    trailing: Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
                    onTap: () => _restoreBackup(context, store),
                  ),
                  Divider(height: 1, color: c.line.withValues(alpha: 0.6)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 13, color: c.muted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '备份 ZIP 内含全部手札、任务、账目、设置与照片，请妥善保管。',
                            style: AppText.sans(size: 10, color: c.muted, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel('关于'),
            const SizedBox(height: 10),
            PaperCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CompassMark(size: 34, color: c.ink, accent: c.accent, stroke: 2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('征途手札', style: AppText.serifStyle(size: 17, color: c.ink)),
                            const SizedBox(height: 2),
                            Text('Version $kAppVersionLabel', style: AppText.sans(size: 9.5, color: c.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '写给每一个把日常生活当作冒险的人。\n记录手札、任务、开销与天气，\n在时间里看见自己怎样长大。',
                    style: AppText.sans(size: 11.5, color: c.inkSoft, height: 1.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '天气数据：Open-Meteo · 定位：系统服务\n手札照片：仅存于应用专属目录',
                    style: AppText.sans(size: 9.5, color: c.muted, height: 1.8),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: '征途手札',
                      applicationVersion: kAppVersion,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '开源许可',
                          style: AppText.sans(size: 10.5, weight: FontWeight.w500, color: c.accent),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.arrow_outward_rounded, size: 12, color: c.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                '每一步，都算数',
                style: AppText.serifStyle(
                  size: 11,
                  weight: FontWeight.w400,
                  color: c.muted.withValues(alpha: 0.8),
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }

  String _backupSubtitle(DateTime? last) {
    if (last == null) return '把全部记录与照片打包成 ZIP';
    return '上次备份：${relativeDay(last)} ${timeHm(last)}';
  }

  String _errorText(Object error) =>
      error is BackupException ? error.message : '操作没有完成，请再试一次';

  Future<void> _exportBackup(BuildContext context, AppStore store) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BusyDialog(message: '正在把手札与照片装进 ZIP…'),
    );
    File? file;
    String? error;
    try {
      file = await store.exportBackup();
    } catch (e) {
      error = _errorText(e);
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (file == null) {
      showAppSnack(context, error ?? '导出没有成功');
      return;
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          text: '我的征途手札备份 · ${relativeDay(DateTime.now())}',
          subject: '征途手札备份',
        ),
      );
      if (context.mounted) {
        showAppSnack(context, '备份已生成，可在系统分享面板里保存到文件');
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, '备份已生成，但系统分享没有打开');
      }
    }
  }

  Future<void> _restoreLatest(BuildContext context, AppStore store) async {
    final file = store.latestBackupFile;
    if (file == null) {
      showAppSnack(context, '应用内还没有可用的备份');
      return;
    }
    await _restoreFile(context, store, file);
  }

  Future<void> _restoreBackup(BuildContext context, AppStore store) async {
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        dialogTitle: '选择征途手札备份',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
    } catch (_) {
      if (context.mounted) showAppSnack(context, '无法打开文件选择器');
      return;
    }
    if (picked == null) return;

    File file;
    try {
      if (picked.path != null) {
        file = File(picked.path!);
      } else {
        final directory = await getTemporaryDirectory();
        file = File('${directory.path}/import_${DateTime.now().millisecondsSinceEpoch}.zip');
        await file.writeAsBytes(await picked.readAsBytes(), flush: true);
      }
    } catch (_) {
      if (context.mounted) showAppSnack(context, '这个文件读不出来');
      return;
    }

    await _restoreFile(context, store, file);
  }

  Future<void> _restoreFile(BuildContext context, AppStore store, File file) async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BusyDialog(message: '正在检查备份内容…'),
    );
    BackupPackage? package;
    String? error;
    try {
      package = await store.readBackup(file);
    } catch (e) {
      error = _errorText(e);
    }
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (package == null) {
      showAppSnack(context, error ?? '这不像一份有效的备份');
      return;
    }

    final confirmed = await confirmAction(
      context,
      title: '恢复这份备份？',
      message: '备份时间：${relativeDay(package.exportedAt)} ${timeHm(package.exportedAt)}\n'
          '包含 ${package.diaryCount} 篇手札、${package.taskCount} 条任务、'
          '${package.expenseCount} 笔账目、${package.imageCount} 张照片。\n\n'
          '恢复会替换当前全部记录与照片，且无法撤销。',
      confirmLabel: '恢复',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _BusyDialog(message: '正在把记录与照片放回手札…'),
    );
    try {
      final result = await store.restoreBackup(package);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showAppSnack(
        context,
        '已恢复 ${result.diaries} 篇手札、${result.tasks} 条任务、${result.expenses} 笔账目',
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showAppSnack(context, _errorText(e));
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  Future<void> _editName(BuildContext context, AppStore store) async {
    final c = context.colors;
    var name = store.name;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('怎么称呼你？', style: AppText.serifStyle(size: 20, color: c.ink)),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: store.name,
                autofocus: true,
                onChanged: (value) => name = value,
                style: AppText.serifStyle(size: 17, color: c.ink),
                decoration: fieldDecoration(context, hint: '冒险者'),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('取消', style: AppText.sans(size: 13, color: c.muted)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(name),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.ink,
                      foregroundColor: c.bg,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null) {
      await store.setName(result);
    }
  }
}

class _SeasonSwatch extends StatelessWidget {
  const _SeasonSwatch({required this.season, required this.current});

  final Season season;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final palette = AppColors.forSeason(season, Brightness.light);
    return Semantics(
      label: '${season.label} · ${season.paletteName}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: SeasonVisuals.hero(season, palette),
                ),
                border: Border.all(
                  color: current ? c.ink : c.line,
                  width: current ? 1.8 : 0.8,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              season.shortLabel,
              style: AppText.sans(
                size: 9.5,
                weight: current ? FontWeight.w600 : FontWeight.w400,
                color: current ? c.ink : c.muted,
              ),
            ),
            Text(
              season.paletteName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 7.5, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusyDialog extends StatelessWidget {
  const _BusyDialog({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 1.8, color: c.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    message,
                    style: AppText.sans(size: 12.5, color: c.inkSoft, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: AppText.sans(size: 10.5, weight: FontWeight.w600, color: c.muted, letterSpacing: 2),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 17, color: c.accent),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.sans(size: 13, weight: FontWeight.w500, color: c.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.sans(size: 10, color: c.muted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
