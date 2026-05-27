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
import '../services/firestore_service.dart';
import '../viewmodels/subject_view_model.dart';
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
        const SnackBar(content: Text('Please select a subject')),
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

    // Capture minutes before resetting, then reset UI immediately.
    final minutes = _displayElapsed.inMinutes;
    setState(() => _displayElapsed = Duration.zero);

    final reward = await timerVM.stopTimer(_uid);

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
        title: const Text('Study Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You studied for $minutes minutes'),
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
            const Text('Add this to your review list?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
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
    final detailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Review Item'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Review title',
                  hintText: 'e.g. Basics of calculus',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: detailController,
                decoration: const InputDecoration(
                  labelText: 'Detail (optional)',
                  hintText: 'e.g. Chapter 3, p.45-52',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              final item = ReviewItem(
                id: '${_uid}_${now.millisecondsSinceEpoch}',
                userId: _uid,
                title: titleController.text.trim(),
                detail: detailController.text.trim(),
                subjectId: subject?.id ?? '',
                nextReviewDate: now.add(const Duration(days: 1)),
                createdAt: now,
              );
              final repo = ReviewItemRepository(FirestoreService());
              await repo.saveReviewItem(item);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Add'),
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
              title: const Text('Add Subject'),
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
                          labelText: 'Subject name',
                          hintText: 'e.g. Math',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Please enter a subject name' : null,
                      ),
                      const SizedBox(height: 20),
                      const Text('Icon',
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
                      const Text('Color',
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final scaffold = ScaffoldMessenger.of(context);
                    try {
                      await ref
                          .read(subjectViewModelProvider)
                          .createSubject(
                            _uid,
                            nameController.text.trim(),
                            selectedIcon,
                            selectedColor,
                          );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      scaffold
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                            content: Text('Subject added!')));
                    } catch (e) {
                      scaffold
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text('Failed to add subject: $e')));
                    }
                  },
                  child: const Text('Add'),
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

    return PopScope(
      canPop: !timerVM.isRunning,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && timerVM.isRunning) {
          if (_displayElapsed.inSeconds < 60) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Study for at least 1 minute before stopping'),
              ),
            );
          } else {
            _stopTimer();
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: timerVM.isRunning
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
        title: const Text('Study Timer'),
        actions: [
          if (!timerVM.isRunning)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Manage Subjects',
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
                  'Add a subject to get started',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                ),
              ],
            )
          // --- Dropdown + add button ---
          : Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Select Subject',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Subject>(
                        value: timerVM.selectedSubject,
                        hint: const Text('Choose a subject'),
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
                  tooltip: 'Add Subject',
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
      final secondsElapsed = _displayElapsed.inSeconds;
      final canStop = secondsElapsed >= 60;
      final remaining = 60 - secondsElapsed;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 56,
            child: FilledButton.icon(
              onPressed: canStop ? _stopTimer : null,
              icon: const Icon(Icons.stop),
              label: Text(
                canStop ? 'Stop' : 'Stop (${remaining}s)',
                style: const TextStyle(fontSize: 18),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
          if (!canStop) ...[
            const SizedBox(height: 8),
            Text(
              'Minimum 1 minute required',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      );
    }
    return SizedBox(
      width: 200,
      height: 56,
      child: FilledButton.icon(
        onPressed: _startTimer,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start', style: TextStyle(fontSize: 18)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
