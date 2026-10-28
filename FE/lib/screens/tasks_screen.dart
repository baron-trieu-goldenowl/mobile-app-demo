import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum _Filter { all, today, upcoming, done }

class _TasksScreenState extends State<TasksScreen> {
  final _service = TaskService();
  List<Task> _tasks = [];
  bool _loading = true;
  bool _loadedOnce = false;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    AppShell.currentTab.addListener(_onTab);
  }

  @override
  void dispose() {
    AppShell.currentTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (AppShell.currentTab.value == 2) _load(silent: _loadedOnce);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    _loadedOnce = true;
    try {
      _tasks = await _service.getTasks();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit([Task? task]) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskSheet(task: task),
    );
    if (result == null) return;
    try {
      if (task == null) {
        await _service.createTask(result);
      } else {
        await _service.updateTask(task.id, result.toJson());
      }
      await _load(silent: true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  Future<void> _toggle(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    try {
      final updated = await _service.toggleComplete(task);
      setState(() => _tasks[index] = updated);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  Future<void> _delete(Task task) async {
    setState(() => _tasks.removeWhere((t) => t.id == task.id));
    try {
      await _service.deleteTask(task.id);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
      await _load(silent: true);
    }
  }

  static bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  List<Task> get _visible {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final list = _tasks
        .where(
          (t) => switch (_filter) {
            _Filter.all => !t.isDone,
            _Filter.today =>
              !t.isDone && t.dueAt != null && !t.dueAt!.isAfter(endOfToday),
            _Filter.upcoming =>
              !t.isDone && t.dueAt != null && t.dueAt!.isAfter(endOfToday),
            _Filter.done => t.isDone,
          },
        )
        .toList();
    const rank = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
    list.sort((a, b) {
      if (_filter == _Filter.done) {
        return (b.completedAt ?? DateTime(0)).compareTo(
          a.completedAt ?? DateTime(0),
        );
      }
      final byDue = (a.dueAt ?? DateTime(9999)).compareTo(
        b.dueAt ?? DateTime(9999),
      );
      return byDue != 0
          ? byDue
          : (rank[a.priority] ?? 9).compareTo(rank[b.priority] ?? 9);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final open = _tasks.where((t) => !t.isDone).length;
    final doneToday = _tasks
        .where(
          (t) => t.isDone && t.completedAt != null && _isToday(t.completedAt!),
        )
        .length;
    final visible = _visible;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-task',
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(s.addTask),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(s.tasks, style: theme.textTheme.headlineMedium),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                child: Text(
                  s.tasksSummary(open, doneToday),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _Filter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(switch (f) {
                            _Filter.all => s.allOpen,
                            _Filter.today => s.today,
                            _Filter.upcoming => s.upcoming,
                            _Filter.done => s.completed,
                          }),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visible.isEmpty)
                EmptyState(
                  icon: _filter == _Filter.done
                      ? Icons.inventory_2_outlined
                      : Icons.task_alt_rounded,
                  title: _filter == _Filter.done
                      ? s.noCompletedTasks
                      : s.noTasks,
                  subtitle: _filter == _Filter.done ? null : s.noTasksHint,
                )
              else
                for (final t in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(t.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(t),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: _TaskCard(
                        task: t,
                        s: s,
                        onToggle: () => _toggle(t),
                        onTap: () => _edit(t),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

Color priorityColor(String p) => switch (p) {
  'urgent' => AppColors.danger,
  'high' => AppColors.accent,
  'medium' => AppColors.event,
  _ => const Color(0xFF8A90A8),
};

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.s,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final AppStrings s;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = priorityColor(task.priority);
    final overdue =
        !task.isDone &&
        task.dueAt != null &&
        task.dueAt!.isBefore(DateTime.now());
    final locale = s.locale.languageCode;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
          child: Row(
            children: [
              IconButton(
                onPressed: onToggle,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    task.isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    key: ValueKey(task.isDone),
                    color: task.isDone ? AppColors.task : color,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _Pill(
                          label: s.priorityName(task.priority),
                          color: color,
                        ),
                        if (task.dueAt != null)
                          _Pill(
                            icon: Icons.schedule_rounded,
                            label: DateFormat(
                              'd MMM · HH:mm',
                              locale,
                            ).format(task.dueAt!),
                            color: overdue
                                ? AppColors.danger
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        if (task.reminderAt != null && !task.isDone)
                          _Pill(
                            icon: Icons.notifications_active_outlined,
                            label: s.reminder,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSheet extends StatefulWidget {
  const _TaskSheet({this.task});

  final Task? task;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final _titleCtrl = TextEditingController(text: widget.task?.title);
  late final _descCtrl = TextEditingController(text: widget.task?.description);
  late String _priority = widget.task?.priority ?? 'medium';
  late DateTime? _due = widget.task?.dueAt;

  /// Minutes before the due time; null = no reminder.
  late int? _remindBefore = _initialReminder();

  int? _initialReminder() {
    final t = widget.task;
    if (t?.reminderAt == null || t?.dueAt == null) return null;
    return t!.dueAt!.difference(t.reminderAt!).inMinutes;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _due ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(
      () => _due = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      Task(
        id: widget.task?.id ?? 0,
        title: title,
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        priority: _priority,
        status: widget.task?.status ?? 'todo',
        dueAt: _due,
        reminderAt: _due != null && _remindBefore != null
            ? _due!.subtract(Duration(minutes: _remindBefore!))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final locale = s.locale.languageCode;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.task == null ? s.addTask : s.editTask,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                autofocus: widget.task == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: s.taskTitleHint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: s.note,
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Text(s.priority, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in const ['low', 'medium', 'high', 'urgent'])
                    ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: priorityColor(p),
                        radius: 5,
                      ),
                      label: Text(s.priorityName(p)),
                      selected: _priority == p,
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHigh,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.event_rounded),
                      title: Text(
                        _due == null
                            ? s.addDueDate
                            : DateFormat(
                                'EEEE, d MMM · HH:mm',
                                locale,
                              ).format(_due!),
                      ),
                      trailing: _due == null
                          ? const Icon(Icons.chevron_right_rounded)
                          : IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => setState(() {
                                _due = null;
                                _remindBefore = null;
                              }),
                            ),
                      onTap: _pickDue,
                    ),
                    if (_due != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final m in const [null, 0, 15, 60, 1440])
                              ChoiceChip(
                                label: Text(s.reminderOption(m)),
                                selected: _remindBefore == m,
                                onSelected: (_) =>
                                    setState(() => _remindBefore = m),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _submit, child: Text(s.save)),
            ],
          ),
        ),
      ),
    );
  }
}
