import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/todo_viewmodel.dart';
import '../../data/models/todo_model.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  final String uid;

  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Load todos when screen opens
    Future.microtask(() {
      Provider.of<TodoViewModel>(context, listen: false)
          .loadTodos(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final todoVM = Provider.of<TodoViewModel>(context);

    return Scaffold(
      appBar: AppBar(
  title: const Text('Smart Todo'),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StatisticsPage(),
          ),
        );
      },
    ),
  ],
),

      body: todoVM.todos.isEmpty
          ? const Center(
              child: Text(
                'No todos yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: todoVM.todos.length,
              itemBuilder: (context, index) {
                final TodoModel todo = todoVM.todos[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (_) {
                        todoVM.toggleDone(todo, widget.uid);
                      },
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        decoration: todo.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: todo.reminderTime != null
                        ? Text(
                            'Reminder: ${todo.reminderTime}',
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _confirmDelete(context, todoVM, todo.id);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= ADD TODO WITH REMINDER =================
  void _showAddTodoDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    DateTime? reminderTime;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter todo title',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.alarm),
              label: const Text('Pick Reminder'),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );

                if (date == null) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time == null) return;

                reminderTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
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
                Provider.of<TodoViewModel>(
                  context,
                  listen: false,
                ).addTodo(
                  controller.text.trim(),
                  widget.uid,
                  reminderTime: reminderTime,
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

  // ================= DELETE CONFIRM =================
  void _confirmDelete(
    BuildContext context,
    TodoViewModel vm,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
}
