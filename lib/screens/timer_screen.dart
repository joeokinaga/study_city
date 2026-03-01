import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/review_item.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../repositories/review_item_repository.dart';
import '../repositories/subject_repository.dart';
import '../services/firestore_service.dart';
import '../viewmodels/timer_view_model.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  StreamSubscription<Duration>? _timerSub;
  Duration _displayElapsed = Duration.zero;

  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _iconOptions = [
    '📚', '📐', '🔬', '🎨', '🎵', '🌍',
    '💻', '📝', '🧪', '⚡', '🧮', '📖',
  ];

  static const _colorOptions = [
    '#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#009688',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerViewModelProvider).loadSubjects(_uid);
    });
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _startTimer() {
    final timerVM = ref.read(timerViewModelProvider);
    if (timerVM.selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('科目を選択してください')),
      );
      return;
    }
    timerVM.startTimer();
    WakelockPlus.enable();
    _timerSub = timerVM.timerStream.listen((elapsed) {
      setState(() => _displayElapsed = elapsed);
    });
  }

  Future<void> _stopTimer() async {
    final timerVM = ref.read(timerViewModelProvider);
    _timerSub?.cancel();
    WakelockPlus.disable();

    final reward = await timerVM.stopTimer(_uid);
    final minutes = _displayElapsed.inMinutes;

    setState(() => _displayElapsed = Duration.zero);

    if (!mounted) return;
    _showCompletionDialog(minutes, reward, timerVM.selectedSubject);
  }

  Future<void> _showCompletionDialog(
    int minutes,
    Reward reward,
    Subject? subject,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('学習完了!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$minutes分 勉強しました'),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text('+${reward.exp} EXP'),
                const SizedBox(width: 16),
                Icon(Icons.monetization_on, size: 18, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text('+${reward.coins} Coins'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('この内容を復習リストに追加しますか？'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('スキップ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('追加する'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _showAddReviewDialog(subject);
    }
  }

  Future<void> _showAddReviewDialog(Subject? subject) async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('復習アイテムを追加'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: '復習内容のタイトル',
              hintText: '例: 微分積分の基礎',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (v) =>
                v == null || v.isEmpty ? 'タイトルを入力してください' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              final item = ReviewItem(
                id: '${_uid}_${now.millisecondsSinceEpoch}',
                userId: _uid,
                title: titleController.text.trim(),
                subjectId: subject?.id ?? '',
                nextReviewDate: now.add(const Duration(days: 1)),
                createdAt: now,
              );
              final repo = ReviewItemRepository(FirestoreService());
              await repo.saveReviewItem(item);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add a new subject inline (without leaving timer screen)
  Future<void> _showAddSubjectDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedIcon = _iconOptions[0];
    String selectedColor = _colorOptions[0];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('科目を追加'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: '科目名',
                          hintText: '例: 数学',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? '科目名を入力してください' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text('アイコン',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _iconOptions.map((icon) {
                          final isSelected = icon == selectedIcon;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedIcon = icon),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(icon,
                                  style: const TextStyle(fontSize: 22)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Text('カラー',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        children: _colorOptions.map((hex) {
                          final isSelected = hex == selectedColor;
                          final color = _parseColor(hex);
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = hex),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      size: 18, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final now = DateTime.now();
                    final subject = Subject(
                      id: '${_uid}_${now.millisecondsSinceEpoch}',
                      userId: _uid,
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                      createdAt: now,
                    );
                    final repo = SubjectRepository(FirestoreService());
                    await repo.createSubject(subject);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final timerVM = ref.watch(timerViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('学習タイマー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '科目管理',
            onPressed: () => context.go('/subjects'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subject selector
              _buildSubjectSelector(timerVM, theme),
              const SizedBox(height: 48),

              // Timer display
              _buildTimerDisplay(timerVM, theme),
              const SizedBox(height: 48),

              // Start/Stop button
              _buildTimerButton(timerVM, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSelector(TimerViewModel timerVM, ThemeData theme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: timerVM.subjects.isEmpty
          // --- Empty state: no subjects yet ---
          ? Column(
              children: [
                Icon(Icons.library_books,
                    size: 48, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text(
                  'まず科目を追加しましょう',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('科目を追加'),
                ),
              ],
            )
          // --- Dropdown + add button ---
          : Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: '科目を選択',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Subject>(
                        value: timerVM.selectedSubject,
                        hint: const Text('選択してください'),
                        isExpanded: true,
                        isDense: true,
                        items: timerVM.subjects.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text('${s.icon} ${s.name}'),
                          );
                        }).toList(),
                        onChanged: timerVM.isRunning
                            ? null
                            : (subject) {
                                if (subject != null) {
                                  timerVM.selectSubject(subject);
                                }
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: timerVM.isRunning ? null : _showAddSubjectDialog,
                  icon: const Icon(Icons.add),
                  tooltip: '科目を追加',
                ),
              ],
            ),
    );
  }

  Widget _buildTimerDisplay(TimerViewModel timerVM, ThemeData theme) {
    final display =
        timerVM.isRunning ? _displayElapsed : Duration.zero;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          child: CircularProgressIndicator(
            value: timerVM.isRunning ? null : 0,
            strokeWidth: 6,
            color: timerVM.isRunning
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        Text(
          _formatDuration(display),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            fontFamily: 'monospace',
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerButton(TimerViewModel timerVM, ThemeData theme) {
    if (timerVM.isRunning) {
      return SizedBox(
        width: 200,
        height: 56,
        child: FilledButton.icon(
          onPressed: _stopTimer,
          icon: const Icon(Icons.stop),
          label: const Text('停止', style: TextStyle(fontSize: 18)),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
    return SizedBox(
      width: 200,
      height: 56,
      child: FilledButton.icon(
        onPressed: _startTimer,
        icon: const Icon(Icons.play_arrow),
        label: const Text('開始', style: TextStyle(fontSize: 18)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
