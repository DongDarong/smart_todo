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
      Provider.of<TodoViewModel>(context, listen: false)
          .loadTodos(widget.uid);
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

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search todos...',
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => vm.setSearchQuery(v),
                )
              : const Text('Smart Todo'),
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
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Overdue'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Active filters / search chips
            if (vm.searchQuery.isNotEmpty || vm.statusFilter != TodoStatusFilter.all || vm.priorityFilters.isNotEmpty || vm.dateFrom != null || vm.dateTo != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (vm.searchQuery.isNotEmpty)
                      Chip(
                        label: Text('Search: "${vm.searchQuery}"'),
                        onDeleted: () => vm.setSearchQuery(''),
                      ),
                    if (vm.statusFilter != TodoStatusFilter.all)
                      Chip(
                        label: Text(vm.statusFilter == TodoStatusFilter.completed ? 'Status: Completed' : 'Status: Pending'),
                        onDeleted: () => vm.setStatusFilter(TodoStatusFilter.all),
                      ),
                    if (vm.priorityFilters.isNotEmpty)
                      Chip(
                        label: Text('Priority: ${vm.priorityFilters.join(', ')}'),
                        onDeleted: () => vm.setPriorityFilters({}),
                      ),
                    if (vm.dateFrom != null || vm.dateTo != null)
                      Chip(
                        label: Text('Date: ${vm.dateFrom != null ? vm.dateFrom!.toLocal().toString().split(' ')[0] : 'Any'} → ${vm.dateTo != null ? vm.dateTo!.toLocal().toString().split(' ')[0] : 'Any'}'),
                        onDeleted: () => vm.setDateRange(null, null),
                      ),
                    ActionChip(
                      label: const Text('Clear All'),
                      onPressed: vm.clearFilters,
                    ),
                  ],
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTodoDialog(context, vm),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // =========================================================
  // TODO LIST
  // =========================================================
  Widget _buildTodoList(List<TodoModel> list, TodoViewModel vm) {
    if (list.isEmpty) {
      return const Center(child: Text('No tasks'));
    }

    final sorted = vm.sortByPriority(list);

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (_, index) {
        final todo = sorted[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Checkbox(
              value: todo.isDone,
              onChanged: (_) => vm.toggleDone(todo, widget.uid),
            ),
            title: Text(
              todo.title,
              style: TextStyle(
                decoration:
                    todo.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: todo.dueDate != null
                ? Text(
                    'Due: ${todo.dueDate!.toLocal().toString().split(' ')[0]} | Priority: ${todo.priority}',
                  )
                : Text('Priority: ${todo.priority}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTodoDialog(context, vm, todo);
                } else if (value == 'delete') {
                  _confirmDelete(context, vm, todo.id);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ADD TODO
  // =========================================================
  void _showAddTodoDialog(
      BuildContext context, TodoViewModel vm) {
    final TextEditingController controller =
        TextEditingController();

    DateTime? dueDate;
    int priority = 2;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration:
                  const InputDecoration(hintText: 'Todo title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority: '),
                DropdownButton<int>(
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                  ],
                  onChanged: (v) {
                    if (v != null) priority = v;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Pick Due Date'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (picked != null) dueDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Add'),
          ),
        ],
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
    final TextEditingController controller =
        TextEditingController(text: todo.title);

    DateTime? dueDate = todo.dueDate;
    int priority = todo.priority;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration:
                  const InputDecoration(hintText: 'Todo title'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority: '),
                DropdownButton<int>(
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Low')),
                    DropdownMenuItem(value: 2, child: Text('Medium')),
                    DropdownMenuItem(value: 3, child: Text('High')),
                  ],
                  onChanged: (v) {
                    if (v != null) priority = v;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: const Text('Pick Due Date'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: dueDate ?? DateTime.now(),
                );
                if (picked != null) dueDate = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DELETE CONFIRM
  // =========================================================
  void _confirmDelete(
    BuildContext context,
    TodoViewModel vm,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Todo'),
        content:
            const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<TodoStatusFilter>(
                        title: const Text('All'),
                        value: TodoStatusFilter.all,
                        groupValue: selectedStatus,
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TodoStatusFilter>(
                        title: const Text('Completed'),
                        value: TodoStatusFilter.completed,
                        groupValue: selectedStatus,
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<TodoStatusFilter>(
                        title: const Text('Pending'),
                        value: TodoStatusFilter.pending,
                        groupValue: selectedStatus,
                        onChanged: (v) => setState(() => selectedStatus = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDate: from ?? DateTime.now(),
                          );
                          if (picked != null) setState(() => from = picked);
                        },
                        child: Text(from != null ? 'From: ${from!.toLocal().toString().split(' ')[0]}' : 'Pick From Date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDate: to ?? DateTime.now(),
                          );
                          if (picked != null) setState(() => to = picked);
                        },
                        child: Text(to != null ? 'To: ${to!.toLocal().toString().split(' ')[0]}' : 'Pick To Date'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        vm.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        vm.setStatusFilter(selectedStatus);
                        vm.setPriorityFilters(selectedPriorities);
                        vm.setDateRange(from, to);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
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
        title: const Text('Logout'),
        content:
            const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<AuthViewModel>(
                context,
                listen: false,
              ).logout();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
