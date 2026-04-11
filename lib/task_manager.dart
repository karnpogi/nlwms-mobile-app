class TaskManager {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  final List<Map<String, dynamic>> _tasks = [];

  List<Map<String, dynamic>> get tasks => _tasks;

  void addTask(Map<String, dynamic> task) {
    _tasks.add(task);
  }

  void removeTask(int index) {
    _tasks.removeAt(index);
  }
  
  void updateTask(int index, Map<String, dynamic> updatedTask) {
  if (index >= 0 && index < _tasks.length) {
    _tasks[index] = updatedTask;
  }
}

}
