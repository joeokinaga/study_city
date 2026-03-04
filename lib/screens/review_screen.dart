import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/review_item.dart';
import '../models/subject.dart';
import '../viewmodels/review_view_model.dart';
import '../viewmodels/subject_view_model.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  String get _uid => fb.FirebaseAuth.instance.currentUser?.uid ?? '';
  int _initialCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reviewVM = ref.read(reviewViewModelProvider);
      reviewVM.completedCount = 0;
      await reviewVM.loadTodayItems(_uid);
      setState(() {
        _initialCount =
            reviewVM.todayItems.length + reviewVM.completedCount;
      });
    });
  }

  Future<void> _handleReview(ReviewItem item, int difficulty) async {
    await ref.read(reviewViewModelProvider).processReview(
          _uid,
          item,
          difficulty,
        );
  }

  @override
  Widget build(BuildContext context) {
    final reviewVM = ref.watch(reviewViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Review'),
        actions: [
          if (_initialCount > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${reviewVM.completedCount} / $_initialCount',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
        ],
      ),
      body: reviewVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(reviewVM, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        tooltip: 'Add Review Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ReviewViewModel reviewVM, ThemeData theme) {
    // All completed
    if (reviewVM.todayItems.isEmpty && reviewVM.completedCount > 0) {
      return _buildCompletionView(reviewVM, theme);
    }

    // No items at all
    if (reviewVM.todayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'No reviews for today',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Review list
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reviewVM.todayItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildReviewCard(reviewVM.todayItems[index], theme);
      },
    );
  }

  Widget _buildCompletionView(ReviewViewModel reviewVM, ThemeData theme) {
    final totalExp = reviewVM.completedCount * 20;
    final totalCoins = reviewVM.completedCount * 10;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: const Text('🎉', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 16),
          Text(
            'All reviews done!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You completed ${reviewVM.completedCount} reviews',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text('+$totalExp EXP',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(width: 24),
                  Icon(Icons.monetization_on, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Text('+$totalCoins Coins',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewItem item, ThemeData theme) {
    final intervalLabel =
        item.repetitions == 0 ? 'First review' : 'Review after ${item.interval} days';

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (item.detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.detail,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              intervalLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReview(item, 0),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!),
                    ),
                    child: const Text('Hard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReview(item, 3),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[800],
                      side: BorderSide(color: Colors.orange[300]!),
                    ),
                    child: const Text('Good'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleReview(item, 5),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[300]!),
                    ),
                    child: const Text('Easy'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final detailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Subject? selectedSubject;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Review Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Quadratic formula',
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
                const SizedBox(height: 16),
                StreamBuilder<List<Subject>>(
                  stream: ref
                      .read(subjectViewModelProvider)
                      .streamSubjects(_uid),
                  builder: (context, snapshot) {
                    final subjects = snapshot.data ?? [];
                    return DropdownButtonFormField<Subject>(
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items: subjects.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.icon} ${s.name}'),
                        );
                      }).toList(),
                      onChanged: (v) => selectedSubject = v,
                      validator: (v) => v == null ? 'Please select a subject' : null,
                    );
                  },
                ),
              ],
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
                final now = DateTime.now();
                final item = ReviewItem(
                  id: '${_uid}_${now.millisecondsSinceEpoch}',
                  userId: _uid,
                  title: titleController.text.trim(),
                  detail: detailController.text.trim(),
                  subjectId: selectedSubject?.id ?? '',
                  nextReviewDate: now.add(const Duration(days: 1)),
                  createdAt: now,
                );
                await ref.read(reviewViewModelProvider).addReviewItem(item);
                setState(() => _initialCount++);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
