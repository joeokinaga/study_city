import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/subject.dart';
import '../viewmodels/subject_view_model.dart';

class SubjectManagementScreen extends ConsumerStatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  ConsumerState<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends ConsumerState<SubjectManagementScreen> {
  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';

  static const _iconOptions = [
    '📚', '📐', '🔬', '🎨', '🎵', '🌍',
    '💻', '📝', '🧪', '⚡', '🧮', '📖',
  ];

  static const _colorOptions = [
    '#2196F3', // Blue
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#F44336', // Red
    '#009688', // Teal
  ];

  String _formatStudyTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h時間${m}分';
    return '$m分';
  }

  Color _parseColor(String hex) {
    final code = hex.replaceFirst('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }

  Future<void> _confirmDelete(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('科目を削除'),
        content: Text('「${subject.name}」を削除してよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(subjectViewModelProvider)
          .deleteSubject(_uid, subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${subject.name}」を削除しました')),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
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
                      // Name
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

                      // Icon picker
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

                      // Color picker
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
                    await ref.read(subjectViewModelProvider).createSubject(
                          _uid,
                          nameController.text.trim(),
                          selectedIcon,
                          selectedColor,
                        );
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

  @override
  Widget build(BuildContext context) {
    final subjectVM = ref.watch(subjectViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/timer'),
        ),
        title: const Text('科目管理'),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: subjectVM.streamSubjects(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    '＋ボタンから科目を追加しましょう',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildSubjectTile(subjects[index], theme);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: '科目を追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSubjectTile(Subject subject, ThemeData theme) {
    final color = _parseColor(subject.color);

    return Card(
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(subject.icon, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '学習時間: ${_formatStudyTime(subject.totalStudyTime)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[400]),
          tooltip: '削除',
          onPressed: () => _confirmDelete(subject),
        ),
      ),
    );
  }
}
