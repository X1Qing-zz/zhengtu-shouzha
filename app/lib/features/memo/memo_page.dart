import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/compass_mark.dart';
import 'memo_export.dart';

enum _ExportKind { image, text }

/// A memory-only scratch page hidden to the left of Today.
///
/// Nothing here touches SQLite, SharedPreferences or the backup service. The
/// text survives page swipes because the page stays alive, and disappears when
/// the process ends.
class MemoPage extends StatefulWidget {
  const MemoPage({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> with AutomaticKeepAliveClientMixin {
  static const int _maxChars = 2000;
  static const double _exportCardWidth = 360;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _exportCardKey = GlobalKey();

  bool _showExportCard = false;
  _ExportKind? _busyKind;
  String _cardText = '';
  DateTime _exportDate = DateTime.now();

  bool get _busy => _busyKind != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasText => _controller.text.trim().isNotEmpty;

  int get _charCount => _controller.text.runes.length;

  void _close() {
    _focusNode.unfocus();
    widget.onClose();
  }

  Future<void> _clear() async {
    if (_controller.text.isEmpty) return;
    final confirmed = await confirmAction(
      context,
      title: '清空这页？',
      message: '这页文字没有副本，清空后就找不回来了。',
      confirmLabel: '清空',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _exportImage() async {
    if (_busy || !_hasText) return;
    final text = _controller.text.trim();
    final createdAt = DateTime.now();
    _focusNode.unfocus();
    setState(() {
      _busyKind = _ExportKind.image;
      _showExportCard = true;
      _cardText = text;
      _exportDate = createdAt;
    });

    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _exportCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('卡片还没有准备好');
      final image = await boundary.toImage(pixelRatio: 2.4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('无法生成图片');
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${memoImageFileName(createdAt)}');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (mounted) setState(() => _showExportCard = false);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '征途手札 · 勿忘',
          subject: '勿忘 · ${fullDateLabel(createdAt)}',
        ),
      );
      if (mounted) {
        showAppSnack(context, '卡片已生成，可在系统面板里保存或发送');
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(context, '卡片生成失败，再试一次');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyKind = null;
          _showExportCard = false;
        });
      }
    }
  }

  Future<void> _exportText() async {
    if (_busy || !_hasText) return;
    final text = _controller.text.trim();
    final createdAt = DateTime.now();
    _focusNode.unfocus();
    setState(() => _busyKind = _ExportKind.text);

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${memoTextFileName(createdAt)}');
      await file.writeAsString(
        memoPlainText(text: text, createdAt: createdAt),
        flush: true,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          text: '征途手札 · 勿忘',
          subject: '勿忘 · ${fullDateLabel(createdAt)}',
        ),
      );
      if (mounted) {
        showAppSnack(context, 'TXT 已生成，可在系统面板里保存或发送');
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(context, 'TXT 生成失败，再试一次');
      }
    } finally {
      if (mounted) setState(() => _busyKind = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.colors;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          if (_showExportCard)
            Positioned(
              left: 0,
              top: 0,
              width: _exportCardWidth,
              child: RepaintBoundary(
                key: _exportCardKey,
                child: MemoExportCard(
                  text: _cardText,
                  createdAt: _exportDate,
                  width: _exportCardWidth,
                ),
              ),
            ),
          // Opaque shield: the export card is painted behind this so it always
          // has a live layer, while never being visible on screen.
          Positioned.fill(child: ColoredBox(color: c.bg)),
          SafeArea(
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: c.accent.withValues(alpha: c.isDark ? 0.38 : 0.28),
                    width: 0.9,
                  ),
                ),
                child: Column(
                  children: [
                    _buildTopBar(c),
                    _buildTitle(c, now),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      color: c.accent.withValues(alpha: 0.24),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          maxLength: _maxChars,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          cursorColor: c.accent,
                          cursorWidth: 1.4,
                          style: AppText.serifStyle(
                            size: 17,
                            weight: FontWeight.w400,
                            color: c.ink,
                            height: 1.95,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            counterText: '',
                            hintText: '写下此刻不想忘记的事……',
                            hintStyle: AppText.serifStyle(
                              size: 16,
                              weight: FontWeight.w400,
                              color: c.muted.withValues(alpha: 0.75),
                              height: 1.9,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(c),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: c.inkSoft),
                  const SizedBox(width: 3),
                  Text(
                    '今日',
                    style: AppText.sans(
                      size: 12,
                      weight: FontWeight.w500,
                      color: c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            'ONLY FOR NOW',
            style: AppText.eyebrow(
              color: c.accent.withValues(alpha: 0.78),
              size: 8.2,
            ),
          ),
          const Spacer(),
          if (_hasText)
            IconButton(
              onPressed: _busy ? null : _clear,
              tooltip: '清空',
              icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.muted),
              style: IconButton.styleFrom(
                minimumSize: const Size(38, 38),
                padding: EdgeInsets.zero,
              ),
            )
          else
            const SizedBox(width: 38, height: 38),
        ],
      ),
    );
  }

  Widget _buildTitle(AppColors c, DateTime now) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompassMark(
                size: 16,
                color: c.accent,
                accent: c.ink,
                stroke: 2.2,
              ),
              const SizedBox(width: 7),
              Text(
                '勿忘',
                style: AppText.eyebrow(color: c.accent, size: 9),
              ),
              const Spacer(),
              Text(
                '${two(now.month)}.${two(now.day)} · ${weekdayLabel(now)}',
                style: AppText.sans(
                  size: 10,
                  color: c.inkSoft.withValues(alpha: 0.72),
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '勿忘',
                style: AppText.serifStyle(
                  size: 32,
                  color: c.ink,
                  height: 1.1,
                  letterSpacing: 5,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '一张只在此刻存在的纸',
                  style: AppText.sans(
                    size: 10.5,
                    color: c.inkSoft.withValues(alpha: 0.78),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppColors c) {
    final canExport = _hasText && !_busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '$_charCount / $_maxChars',
                style: AppText.sans(size: 9.5, color: c.muted),
              ),
              const Spacer(),
              Icon(
                Icons.memory_rounded,
                size: 11,
                color: c.muted.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '仅保存在内存',
                style: AppText.sans(size: 9.5, color: c.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canExport ? _exportImage : null,
                  icon: _busyKind == _ExportKind.image
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: c.accent,
                          ),
                        )
                      : const Icon(Icons.image_outlined, size: 17),
                  label: const Text('导出卡片'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.ink,
                    side: BorderSide(color: c.accent.withValues(alpha: 0.34)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canExport ? _exportText : null,
                  icon: _busyKind == _ExportKind.text
                      ? SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: c.bg,
                          ),
                        )
                      : const Icon(Icons.description_outlined, size: 17),
                  label: const Text('导出 TXT'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.bg,
                    disabledBackgroundColor: c.ink.withValues(alpha: 0.35),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The solid, season-tinted card that becomes the exported PNG.
class MemoExportCard extends StatelessWidget {
  const MemoExportCard({
    super.key,
    required this.text,
    required this.createdAt,
    this.width = 360,
  });

  final String text;
  final DateTime createdAt;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      color: c.bg,
      padding: const EdgeInsets.all(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: c.accent.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompassMark(
                  size: 15,
                  color: c.accent,
                  accent: c.ink,
                  stroke: 2.2,
                ),
                const SizedBox(width: 7),
                Text(
                  '勿忘 · WUWANG',
                  style: AppText.eyebrow(color: c.accent, size: 8.2),
                ),
                const Spacer(),
                Text(
                  '${two(createdAt.month)}.${two(createdAt.day)}',
                  style: AppText.sans(
                    size: 9.5,
                    color: c.inkSoft.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              '勿忘',
              style: AppText.serifStyle(
                size: 30,
                color: c.ink,
                height: 1.1,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 1,
              color: c.accent.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 22),
            Text(
              text.trim(),
              maxLines: 140,
              overflow: TextOverflow.ellipsis,
              style: AppText.serifStyle(
                size: 15.5,
                weight: FontWeight.w400,
                color: c.ink,
                height: 1.95,
                letterSpacing: 0.45,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Text(
                  '征途手札 · 勿忘',
                  style: AppText.sans(
                    size: 9,
                    weight: FontWeight.w600,
                    color: c.inkSoft.withValues(alpha: 0.75),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Text(
                  fullDateLabel(createdAt),
                  style: AppText.sans(
                    size: 8.2,
                    color: c.muted.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
