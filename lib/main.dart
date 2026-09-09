import 'dart:math';
import 'package:flutter/material.dart';
import 'models/expense.dart';

void main() {
  runApp(const SmartExpenseTrackerApp());
}

class SmartExpenseTrackerApp extends StatelessWidget {
  const SmartExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ExpenseTrackerHomePage(),
    );
  }
}

class ExpenseTrackerHomePage extends StatefulWidget {
  const ExpenseTrackerHomePage({super.key});

  @override
  State<ExpenseTrackerHomePage> createState() => _ExpenseTrackerHomePageState();
}

class _ExpenseTrackerHomePageState extends State<ExpenseTrackerHomePage> {
  final List<Expense> _allExpenses = [];
  double _monthlyBudget = 0.0;
  String _selectedFilter = 'All';

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Other'];
  final List<String> _filterOptions = [
    'All',
    'Today',
    'This week',
    'This month',
    'Food',
    'Transport',
    'Shopping',
    'Other'
  ];

  // --- FILTERED DATA ---
  List<Expense> get _filteredExpenses {
    final now = DateTime.now();
    return _allExpenses.where((e) {
      if (_selectedFilter == 'Today') {
        return e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day;
      } else if (_selectedFilter == 'This week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return e.date.isAfter(startOfDay.subtract(const Duration(seconds: 1)));
      } else if (_selectedFilter == 'This month') {
        return e.date.year == now.year && e.date.month == now.month;
      } else if (_categories.contains(_selectedFilter)) {
        return e.category == _selectedFilter;
      }
      return true; // 'All'
    }).toList();
  }

  // --- METRIC CALCULATIONS ---
  double get _totalExpense =>
      _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

  double get _todayExpense {
    final now = DateTime.now();
    return _filteredExpenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _highestExpense => _filteredExpenses.isEmpty
      ? 0.0
      : _filteredExpenses.map((e) => e.amount).reduce(max);

  double get _lowestExpense => _filteredExpenses.isEmpty
      ? 0.0
      : _filteredExpenses.map((e) => e.amount).reduce(min);

  double get _averageExpense => _filteredExpenses.isEmpty
      ? 0.0
      : _totalExpense / _filteredExpenses.length;

  double _getCategoryTotal(String category) {
    return _filteredExpenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get _remainingBudget => _monthlyBudget - _totalExpense;

  String get _spendingStatus {
    if (_monthlyBudget <= 0) return 'No Budget Set';
    final percentage = (_totalExpense / _monthlyBudget) * 100;
    if (percentage < 50) return 'Safe (<50%)';
    if (percentage <= 80) return 'Moderate (50%-80%)';
    if (percentage <= 100) return 'Warning (80%-100%)';
    return 'Over Budget (>100%)';
  }

  Color get _statusColor {
    if (_monthlyBudget <= 0) return Colors.grey;
    final percentage = (_totalExpense / _monthlyBudget) * 100;
    if (percentage < 50) return Colors.green;
    if (percentage <= 80) return Colors.amber.shade700;
    if (percentage <= 100) return Colors.orange;
    return Colors.red;
  }

  // --- ACTIONS & DIALOGS ---
  void _addExpense(String title, double amount, String category, DateTime date) {
    setState(() {
      _allExpenses.insert(
        0,
        Expense(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          amount: amount,
          category: category,
          date: date,
        ),
      );
    });

    if (_monthlyBudget > 0 && _totalExpense > _monthlyBudget) {
      _showOverBudgetAlert();
    }
  }

  void _deleteExpense(String id) {
    setState(() {
      _allExpenses.removeWhere((item) => item.id == id);
    });
  }

  void _showOverBudgetAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Budget Exceeded!'),
        content: Text(
          'Your total spending (\$${_totalExpense.toStringAsFixed(2)}) has exceeded your budget of \$${_monthlyBudget.toStringAsFixed(2)}!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  void _openSetBudgetDialog() {
    final budgetController = TextEditingController(
      text: _monthlyBudget > 0 ? _monthlyBudget.toStringAsFixed(2) : '',
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget Amount',
              prefixText: '\$ ',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(budgetController.text);
                if (value == null || value < 0) {
                  setDialogState(() {
                    errorText = 'Budget cannot be negative or invalid';
                  });
                  return;
                }
                setState(() {
                  _monthlyBudget = value;
                });
                Navigator.of(ctx).pop();
                if (_monthlyBudget > 0 && _totalExpense > _monthlyBudget) {
                  _showOverBudgetAlert();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExpenseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddExpenseSheet(
        categories: _categories,
        onAdd: _addExpense,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Expense Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'Set Monthly Budget',
            onPressed: _openSetBudgetDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- BUDGET & STATUS CARD ---
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Monthly Budget', style: TextStyle(color: Colors.grey)),
                            Text(
                              '\$${_monthlyBudget.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Remaining Budget', style: TextStyle(color: Colors.grey)),
                            Text(
                              '\$${_remainingBudget.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _remainingBudget < 0 ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Spending Status:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            _spendingStatus,
                            style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- STATS OVERVIEW CARDS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Total Spent', '\$${_totalExpense.toStringAsFixed(2)}', Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard("Today's Total", '\$${_todayExpense.toStringAsFixed(2)}', Colors.teal),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCard('Highest', '\$${_highestExpense.toStringAsFixed(2)}', Colors.deepOrange),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard('Lowest', '\$${_lowestExpense.toStringAsFixed(2)}', Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard('Average', '\$${_averageExpense.toStringAsFixed(2)}', Colors.indigo),
                  ),
                ],
              ),
            ),

            // --- CATEGORY BREAKDOWN ---
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Category-wise Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        return Chip(
                          label: Text('$cat: \$${_getCategoryTotal(cat).toStringAsFixed(2)}'),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // --- FILTER BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Records:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    underline: Container(height: 2, color: Theme.of(context).primaryColor),
                    items: _filterOptions.map((f) {
                      return DropdownMenuItem(value: f, child: Text(f));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedFilter = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // --- EXPENSE LIST ---
            _filteredExpenses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No expenses found for this selection.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredExpenses.length,
                    itemBuilder: (ctx, i) {
                      final item = _filteredExpenses[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(item.category[0]),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${item.category} • ${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${item.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (alertCtx) => AlertDialog(
                                      title: const Text('Delete Expense'),
                                      content: Text('Are you sure you want to delete "${item.title}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(alertCtx).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            _deleteExpense(item.id);
                                            Navigator.of(alertCtx).pop();
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpenseModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- MODAL BOTTOM SHEET: ADD EXPENSE FORM ---
class _AddExpenseSheet extends StatefulWidget {
  final List<String> categories;
  final Function(String title, double amount, String category, DateTime date) onAdd;

  const _AddExpenseSheet({required this.categories, required this.onAdd});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.categories.first;
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Title cannot be empty');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than 0');
      return;
    }

    widget.onAdd(title, amount, _selectedCategory, _selectedDate);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.red.shade100,
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Expense Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (\$)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
  initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}