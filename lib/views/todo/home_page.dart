import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/todo_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../data/models/todo_model.dart';

class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<TodoViewModel>(context, listen: false).loadTodos(widget.uid);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<TodoViewModel>(context);
    final themeVM = Provider.of<ThemeViewModel>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: (v) => vm.setSearchQuery(v),
                )
              : const Text('Smart Todo', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _searchController.clear();
                    vm.setSearchQuery('');
                  }
                  _isSearching = !_isSearching;
                });
              },
            ),
            IconButton(
              icon: Icon(themeVM.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => themeVM.toggleDarkMode(),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterSheet(context, vm),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmLogout(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Overdue'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.surface,
                colorScheme.primaryContainer.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Active filters / search chips
              if (vm.searchQuery.isNotEmpty ||
                  vm.statusFilter != TodoStatusFilter.all ||
                  vm.priorityFilters.isNotEmpty ||
                  vm.dateFrom != null ||
                  vm.dateTo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (vm.searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text('Search: "${vm.searchQuery}"'),
                              onDeleted: () => vm.setSearchQuery(''),
                            ),
                          ),
                        if (vm.statusFilter != TodoStatusFilter.all)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(vm.statusFilter == TodoStatusFilter.completed
                                  ? 'Status: Completed'
                                  : 'Status: Pending'),
                              onDeleted: () => vm.setStatusFilter(TodoStatusFilter.all),
                            ),
                          ),
                        if (vm.priorityFilters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text('Priority: ${vm.priorityFilters.join(', ')}'),
                              onDeleted: () => vm.setPriorityFilters({}),
                            ),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear All'),
                          onPressed: vm.clearFilters,
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildTodoList(vm.applyFilters(vm.todayTodos), vm),
                    _buildTodoList(vm.applyFilters(vm.upcomingTodos), vm),
                    _buildTodoList(vm.applyFilters(vm.completedTodos), vm),
                    _buildTodoList(vm.applyFilters(vm.overdueTodos), vm),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddTodoDialog(context, vm),
          label: const Text('New Task'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  // =========================================================
  // TODO LIST
  // =========================================================
  Widget _buildTodoList(List<TodoModel> list, TodoViewModel vm) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.inbox_outlined, size: 64, color: colorScheme.primary.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              Text('No tasks found', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or add a new task to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final sorted = vm.sortByPriority(list);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              color: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showEditTodoDialog(context, vm, todo),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: todo.isDone,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        onChanged: (_) => vm.toggleDone(todo, widget.uid),
                      ),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration: todo.isDone ? TextDecoration.lineThrough : null,
                        color: todo.isDone ? colorScheme.onSurfaceVariant : colorScheme.onSurface,
                        fontWeight: todo.priority == 3 ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          if (todo.dueDate != null) ...[
                            Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              todo.dueDate!.toLocal().toString().split(' ')[0],
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            todo.priority == 1 ? 'Low' : todo.priority == 2 ? 'Medium' : 'High',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditTodoDialog(context, vm, todo);
                        } else if (value == 'delete') {
                          _confirmDelete(context, vm, todo.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
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
    DateTime? dueDate;
    int priority = 2;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dueDate == null ? 'Set Due Date' : dueDate!.toLocal().toString().split(' ')[0]),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  vm.addTodo(
                    controller.text.trim(),
                    widget.uid,
                    dueDate: dueDate,
                    priority: priority,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EDIT TODO
  // =========================================================
  void _showEditTodoDialog(BuildContext context, TodoViewModel vm, TodoModel todo) {
    final TextEditingController controller = TextEditingController(text: todo.title);
    DateTime? dueDate = todo.dueDate;
    int priority = todo.priority;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: priority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dueDate == null ? 'Set Due Date' : dueDate!.toLocal().toString().split(' ')[0]),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  vm.editTodo(
                    todo,
                    widget.uid,
                    newTitle: controller.text.trim(),
                    newDueDate: dueDate,
                    newPriority: priority,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
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
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
                  Text('Filter Tasks', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  for (final p in [1, 2, 3])
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(p == 1 ? 'Low' : p == 2 ? 'Medium' : 'High'),
                        selected: selectedPriorities.contains(p),
                        onSelected: (sel) => setState(() => sel ? selectedPriorities.add(p) : selectedPriorities.remove(p)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      child: Text(from != null ? from!.toLocal().toString().split(' ')[0] : 'From'),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 16)),
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
                      child: Text(to != null ? to!.toLocal().toString().split(' ')[0] : 'To'),
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
  // LOGOUT CONFIRM
  // =========================================================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Provider.of<AuthViewModel>(context, listen: false).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}