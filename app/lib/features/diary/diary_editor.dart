import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/date_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/app_store.dart';
import '../../widgets/common.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key, this.entry, required this.initialDate});

  final DiaryEntry? entry;
  final DateTime initialDate;

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late DateTime _date;
  late DateTime _createdAt;
  int? _entryId;
  Mood? _mood;
  late List<String> _images;
  final List<String> _removedImages = [];
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _entryId = entry?.id;
    _date = dateOnly(entry?.date ?? widget.initialDate);
    _createdAt = entry?.createdAt ?? DateTime.now();
    _mood = entry?.mood;
    _images = List.of(entry?.images ?? const []);
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(text: entry?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
  }

  void _loadEntry(DiaryEntry entry) {
    setState(() {
      _entryId = entry.id;
      _date = dateOnly(entry.date);
      _createdAt = entry.createdAt;
      _mood = entry.mood;
      _images = List.of(entry.images);
      _removedImages.clear();
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _dirty = false;
    });
  }

  Future<void> _pickDate() async {
    final store = context.read<AppStore>();
    final now = today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: '选择这一天',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null || !mounted) return;
    final target = dateOnly(picked);
    final existing = store.diaryForDay(target);
    if (existing != null && existing.id != _entryId) {
      final open = await confirmAction(
        context,
        title: '这一天已有手札',
        message: '要打开「${existing.displayTitle}」吗？当前未保存的内容会被替换。',
        confirmLabel: '打开',
      );
      if (open && mounted) _loadEntry(existing);
      return;
    }
    setState(() {
      _date = target;
      _dirty = true;
    });
  }

  Future<void> _addImages() async {
    if (_images.length >= 9) {
      showAppSnack(context, '一页手札最多放 9 张照片');
      return;
    }
    final store = context.read<AppStore>();
    final picked = await store.pickDiaryImages(limit: 9 - _images.length);
    if (picked.isEmpty || !mounted) return;
    setState(() {
      _images.addAll(picked);
      _dirty = true;
    });
  }

  void _removeImage(String path) {
    setState(() {
      _images.remove(path);
      if (widget.entry?.images.contains(path) == true) {
        _removedImages.add(path);
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty && _images.isEmpty) {
      showAppSnack(context, '写点什么再收进手札吧');
      return;
    }
    setState(() => _saving = true);
    final store = context.read<AppStore>();
    final entry = DiaryEntry(
      id: _entryId,
      date: _date,
      title: title,
      content: content,
      images: List.of(_images),
      mood: _mood,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
    try {
      await store.saveDiary(entry);
      if (_removedImages.isNotEmpty) {
        await store.deleteImageFiles(_removedImages);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('手札已收好')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnack(context, '保存没有成功，再试一次');
    }
  }

  Future<void> _handleBack() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await confirmAction(
      context,
      title: '要放下这一页吗？',
      message: '未保存的文字和照片会离开。',
      confirmLabel: '放下',
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isToday = isSameDay(_date, today());
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: c.inkSoft,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _entryId == null ? 'NEW PAGE' : 'EDIT PAGE',
                            style: AppText.eyebrow(color: c.muted, size: 9),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isToday ? '今天的手札' : dayTitle(_date),
                            style: AppText.serifStyle(size: 16, color: c.ink),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _save,
                      style: TextButton.styleFrom(
                        backgroundColor: c.ink,
                        foregroundColor: c.bg,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.6, color: c.bg),
                            )
                          : Text(
                              '收好',
                              style: AppText.sans(size: 13, weight: FontWeight.w600, color: c.bg),
                            ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _pickDate,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 14, color: c.accent),
                                const SizedBox(width: 7),
                                Text(
                                  fullDateLabel(_date),
                                  style: AppText.sans(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: c.inkSoft,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.expand_more_rounded, size: 15, color: c.muted),
                              ],
                            ),
                          ),
                          if (!isToday) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() {
                                _date = today();
                                _dirty = true;
                              }),
                              child: TagChip(label: '回到今天', color: c.moss, dense: true),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 26),
                      TextField(
                        controller: _titleController,
                        maxLines: 2,
                        minLines: 1,
                        onChanged: (_) => _markDirty(),
                        style: AppText.serifStyle(
                          size: 27,
                          color: c.ink,
                          height: 1.45,
                          letterSpacing: 0.8,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: '给今天起个标题…',
                          hintStyle: AppText.serifStyle(
                            size: 27,
                            weight: FontWeight.w500,
                            color: c.muted.withValues(alpha: 0.55),
                            height: 1.45,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 0.8,
                        color: c.line.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(
                              '心情',
                              style: AppText.sans(
                                size: 11,
                                weight: FontWeight.w600,
                                color: c.muted,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final mood in Mood.values)
                                  _MoodChip(
                                    mood: mood,
                                    selected: _mood == mood,
                                    onTap: () => setState(() {
                                      _mood = _mood == mood ? null : mood;
                                      _dirty = true;
                                    }),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _contentController,
                        minLines: 12,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        onChanged: (_) => setState(() => _dirty = true),
                        style: AppText.sans(size: 15, color: c.ink, height: 2.0, letterSpacing: 0.2),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: '此刻，风从哪里来？\n\n写下今天遇见的、想到的、\n还有那些想留住的瞬间…',
                          hintStyle: AppText.sans(size: 14, color: c.muted.withValues(alpha: 0.7), height: 2.0),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            '影像',
                            style: AppText.sans(size: 11, weight: FontWeight.w600, color: c.muted, letterSpacing: 1),
                          ),
                          const SizedBox(width: 8),
                          Text('${_images.length} / 9', style: AppText.sans(size: 10, color: c.muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final path in _images)
                            _ImageTile(
                              path: path,
                              onRemove: () => _removeImage(path),
                              onTap: () => _preview(path),
                            ),
                          if (_images.length < 9)
                            _AddImageTile(onTap: _addImages),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '${_contentController.text.replaceAll(RegExp(r'\s'), '').length} 字',
                              style: AppText.sans(size: 10, color: c.muted, letterSpacing: 1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '这一页，只属于你',
                              style: AppText.serifStyle(
                                size: 11,
                                weight: FontWeight.w400,
                                color: c.muted.withValues(alpha: 0.8),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _preview(String path) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
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

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood, required this.selected, required this.onTap});

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft.withValues(alpha: 0.75) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? c.accent.withValues(alpha: 0.55) : c.line,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              mood.label,
              style: AppText.sans(
                size: 10.5,
                weight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? c.ink : c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.path, required this.onRemove, required this.onTap});

  final String path;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(path),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 96,
                height: 96,
                color: c.sunken,
                child: Icon(Icons.broken_image_outlined, size: 18, color: c.muted),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 22, color: c.muted),
            const SizedBox(height: 6),
            Text('添加照片', style: AppText.sans(size: 10, color: c.muted)),
          ],
        ),
      ),
    );
  }
}
