import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/todo_viewmodel.dart';
import '../../data/models/todo_model.dart';
import '../notepad/notepad_list_widget.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _mainTabController; // Todo List vs Notepad
  late TabController _todoTabController; // Today, Upcoming, etc.
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<NotepadListWidgetState> _notepadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _todoTabController = TabController(length: 4, vsync: this);
    // Listen for main tab changes to rebuild FAB with animation
    _mainTabController.addListener(_onMainTabChanged);
    Future.microtask(() {
      Provider.of<TodoViewModel>(context, listen: false).loadTodos(widget.uid);
    });
  }

  void _onMainTabChanged() {
    if (!mounted) return;
    setState(() {});
  }


  @override
  void dispose() {
    _searchController.dispose();
    _mainTabController.removeListener(_onMainTabChanged);
    _mainTabController.dispose();
    _todoTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TodoViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search todos...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search),
                  hintStyle: TextStyle(color: theme.hintColor),
                  isDense: true,
                ),
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                onChanged: (v) => vm.setSearchQuery(v),
              )
            : Text(
                'Memoro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  vm.setSearchQuery('');
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'filter') {
                _showFilterSheet(context, vm);
              } else if (value == 'refresh') {
                _refreshTodos(context, vm);
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage(uid: widget.uid)),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 12),
                    Text('Filter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Reload'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.primaryContainer.withAlpha((0.1 * 255).round()),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top-level tabs: Todo List vs Notepad
            TabBar(
              controller: _mainTabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 13 : 14,
              ),
              tabs: const [
                Tab(text: 'Todo List'),
                Tab(text: 'Notepad'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  // ============ TODO LIST TAB ============
                  Column(
                    children: [
                      // Sub-tabs for Todo List
                      TabBar(
                        controller: _todoTabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                        tabs: const [
                          Tab(text: 'Today'),
                          Tab(text: 'Upcoming'),
                          Tab(text: 'Completed'),
                          Tab(text: 'Overdue'),
                        ],
                      ),
                      // Active filters display
                      if (vm.searchQuery.isNotEmpty ||
                          vm.statusFilter != TodoStatusFilter.all ||
                          vm.priorityFilters.isNotEmpty ||
                          vm.dateFrom != null ||
                          vm.dateTo != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: 8,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (vm.searchQuery.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        'Search: "${vm.searchQuery}"',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                      ),
                                      onDeleted: () => vm.setSearchQuery(''),
                                    ),
                                  ),
                                if (vm.statusFilter != TodoStatusFilter.all)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        vm.statusFilter ==
                                                TodoStatusFilter.completed
                                            ? 'Status: Completed'
                                            : 'Status: Pending',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                      ),
                                      onDeleted: () =>
                                          vm.setStatusFilter(TodoStatusFilter.all),
                                    ),
                                  ),
                                if (vm.priorityFilters.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      label: Text(
                                        'Priority: ${vm.priorityFilters.join(', ')}',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                        ),
                                      ),
                                      onDeleted: () => vm.setPriorityFilters({}),
                                    ),
                                  ),
                                ActionChip(
                                  avatar:
                                      Icon(Icons.clear_all, size: isSmallScreen ? 16 : 18),
                                  label: Text(
                                    'Clear All',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 12 : 13,
                                    ),
                                  ),
                                  onPressed: vm.clearFilters,
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Todo List TabBarView
                      Expanded(
                        child: TabBarView(
                          controller: _todoTabController,
                          children: [
                            _buildTodoList(
                                vm.applyFilters(vm.todayTodos), vm, isSmallScreen),
                            _buildTodoList(
                                vm.applyFilters(vm.upcomingTodos), vm, isSmallScreen),
                            _buildTodoList(
                                vm.applyFilters(vm.completedTodos), vm, isSmallScreen),
                            _buildTodoList(
                                vm.applyFilters(vm.overdueTodos), vm, isSmallScreen),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ============ NOTEPAD TAB ============
                  NotepadListWidget(
                    key: _notepadKey,
                    uid: widget.uid,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: _mainTabController.index == 0
            ? FloatingActionButton.extended(
                key: const ValueKey('fab_task'),
                onPressed: () {
                  final vm = Provider.of<TodoViewModel>(context, listen: false);
                  _showAddTodoDialog(context, vm);
                },
                label: const Text('New Task'),
                icon: const Icon(Icons.add),
              )
            : FloatingActionButton.extended(
                key: const ValueKey('fab_note'),
                onPressed: () => _notepadKey.currentState?.addNote(),
                label: const Text('New Note'),
                icon: const Icon(Icons.add),
              ),
      ),
    );
  }

  Future<void> _refreshTodos(BuildContext context, TodoViewModel vm) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reloading tasks...'),
        duration: Duration(seconds: 1),
      ),
    );
    await vm.loadTodos(widget.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tasks reloaded'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // =========================================================
  // TODO LIST
  // =========================================================
  Widget _buildTodoList(List<TodoModel> list, TodoViewModel vm, bool isSmallScreen) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final cardMargin = isSmallScreen ? 12.0 : 16.0;
    final cardPadding = isSmallScreen ? 8.0 : 12.0;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 24 : 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha((0.05 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: isSmallScreen ? 48 : 64,
                  color: colorScheme.primary.withAlpha((0.5 * 255).round()),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or add a new task to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = vm.sortByPriority(list);

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 8 : 12,
        horizontal: isSmallScreen ? 8 : 0,
      ),
      itemCount: sorted.length,
      itemBuilder: (_, index) {
        final todo = sorted[index];
        final priorityColor = todo.priority == 3
            ? Colors.red
            : todo.priority == 2
            ? Colors.orange
            : Colors.green;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width - 16 : 800,
            ),
            child: Card(
              margin: EdgeInsets.symmetric(
                horizontal: cardMargin,
                vertical: 4,
              ),
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 20),
                onTap: () => _showEditTodoDialog(context, vm, todo),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: cardPadding),
                  child: ListTile(
                    dense: isSmallScreen,
                    leading: Transform.scale(
                      scale: isSmallScreen ? 1.0 : 1.2,
                      child: Checkbox(
                        value: todo.isDone,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        onChanged: (_) => vm.toggleDone(todo, widget.uid),
                      ),
                    ),
                    title: Text(
                      todo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isDone
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        fontWeight: todo.priority == 3
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todo.description != null &&
                              todo.description!.isNotEmpty) ...[
                            Text(
                              todo.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: isSmallScreen ? 12 : 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                          ],
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (todo.dueDate != null) ...[
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: isSmallScreen ? 12 : 14,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    todo.dueDate!
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  todo.priority == 1
                                      ? 'Low'
                                      : todo.priority == 2
                                      ? 'Med'
                                      : 'High',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: isSmallScreen ? 11 : 12,
                                  ),
                                ),
                                if (todo.reminderTime != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.alarm_outlined,
                                    size: isSmallScreen ? 12 : 14,
                                  ),
                                  const SizedBox(width: 2),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: isSmallScreen ? 120 : 180,
                                    ),
                                    child: Text(
                                      todo.reminderTime!
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontSize: isSmallScreen ? 10 : 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: isSmallScreen
                        ? null
                        : PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditTodoDialog(context, vm, todo);
                              } else if (value == 'delete') {
                                _confirmDelete(context, vm, todo.id);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                    onLongPress: isSmallScreen
                        ? () => _confirmDelete(context, vm, todo.id)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ADD TODO
  // =========================================================
  void _showAddTodoDialog(BuildContext context, TodoViewModel vm) {
    final TextEditingController controller = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? dueDate;
    DateTime? reminderTime;
    int priority = 2;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'New Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Low')),
                      DropdownMenuItem(value: 2, child: Text('Medium')),
                      DropdownMenuItem(value: 3, child: Text('High')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => priority = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.calendar_today_outlined, size: isSmallScreen ? 18 : 20),
                      label: Text(
                        dueDate == null
                            ? 'Set Due Date'
                            : dueDate!.toLocal().toString().split(' ')[0],
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => dueDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.alarm_outlined, size: isSmallScreen ? 18 : 20),
                      label: Text(
                        reminderTime == null
                            ? 'Set Reminder'
                            : reminderTime!.toLocal().toString().substring(0, 16),
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: DateTime.now(),
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                        );
                        if (pickedTime == null) return;
                        final combined = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setDialogState(() => reminderTime = combined);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            vm.addTodo(
                              controller.text.trim(),
                              widget.uid,
                              description: descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              dueDate: dueDate,
                              reminderTime: reminderTime,
                              priority: priority,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create Task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EDIT TODO
  // =========================================================
  void _showEditTodoDialog(
    BuildContext context,
    TodoViewModel vm,
    TodoModel todo,
  ) {
    final TextEditingController controller = TextEditingController(
      text: todo.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: todo.description ?? '',
    );
    DateTime? dueDate = todo.dueDate;
    DateTime? reminderTime = todo.reminderTime;
    int priority = todo.priority;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Low')),
                      DropdownMenuItem(value: 2, child: Text('Medium')),
                      DropdownMenuItem(value: 3, child: Text('High')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => priority = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.calendar_today_outlined, size: isSmallScreen ? 18 : 20),
                      label: Text(
                        dueDate == null
                            ? 'Set Due Date'
                            : dueDate!.toLocal().toString().split(' ')[0],
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: dueDate ?? DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => dueDate = picked);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(Icons.alarm_outlined, size: isSmallScreen ? 18 : 20),
                      label: Text(
                        reminderTime == null
                            ? 'Set Reminder'
                            : reminderTime!.toLocal().toString().substring(0, 16),
                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: reminderTime ?? DateTime.now(),
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            reminderTime ?? DateTime.now(),
                          ),
                        );
                        if (pickedTime == null) return;
                        final combined = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                        setDialogState(() => reminderTime = combined);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            vm.editTodo(
                              todo,
                              widget.uid,
                              newTitle: controller.text.trim(),
                              newDescription: descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              newDueDate: dueDate,
                              newReminderTime: reminderTime,
                              newPriority: priority,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DELETE CONFIRM
  // =========================================================
  void _confirmDelete(BuildContext context, TodoViewModel vm, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              vm.deleteTodo(id, widget.uid);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILTER SHEET
  // =========================================================
  void _showFilterSheet(BuildContext context, TodoViewModel vm) {
    TodoStatusFilter selectedStatus = vm.statusFilter;
    final Set<int> selectedPriorities = Set<int>.from(vm.priorityFilters);
    DateTime? from = vm.dateFrom;
    DateTime? to = vm.dateTo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Tasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TodoStatusFilter.values.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(s.name.toUpperCase()),
                        selected: selectedStatus == s,
                        onSelected: (val) => setState(() => selectedStatus = s),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Priority',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  for (final p in [1, 2, 3])
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(
                          p == 1
                              ? 'Low'
                              : p == 2
                              ? 'Medium'
                              : 'High',
                        ),
                        selected: selectedPriorities.contains(p),
                        onSelected: (sel) => setState(
                          () => sel
                              ? selectedPriorities.add(p)
                              : selectedPriorities.remove(p),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Date Range',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: from ?? DateTime.now(),
                        );
                        if (picked != null) setState(() => from = picked);
                      },
                      child: Text(
                        from != null
                            ? from!.toLocal().toString().split(' ')[0]
                            : 'From',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: to ?? DateTime.now(),
                        );
                        if (picked != null) setState(() => to = picked);
                      },
                      child: Text(
                        to != null
                            ? to!.toLocal().toString().split(' ')[0]
                            : 'To',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        vm.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        vm.setStatusFilter(selectedStatus);
                        vm.setPriorityFilters(selectedPriorities);
                        vm.setDateRange(from, to);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGOUT CONFIRM (moved to SettingsPage)
  // =========================================================
}

