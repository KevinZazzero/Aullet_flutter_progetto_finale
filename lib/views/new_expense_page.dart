import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aullet/models/expense.dart';
import 'package:aullet/models/category.dart';
import 'package:aullet/repositories/category_viewmodel.dart';
import 'package:aullet/viewmodels/expense_viewmodel.dart';

class NewExpensePage extends StatefulWidget {
  final Expense? expenseToEdit;

  const NewExpensePage({super.key, this.expenseToEdit});

  @override
  State<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends State<NewExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  Category? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    if (widget.expenseToEdit != null) {
      _titleController.text = widget.expenseToEdit!.title;
      _descriptionController.text = widget.expenseToEdit!.description ?? '';
      _amountController.text = widget.expenseToEdit!.amount.toString();
      _selectedDate = widget.expenseToEdit!.date;
    } else {
      _selectedDate = DateTime.now();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catVM = context.read<CategoryViewModel>();
      await catVM.loadCategories();

      if (widget.expenseToEdit != null && catVM.categories.isNotEmpty) {
        setState(() {
          _selectedCategory = catVM.categories.firstWhere(
            (cat) => cat.id == widget.expenseToEdit!.categoryId,
            orElse: () => catVM.categories.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      try {
        final expenseVM = context.read<ExpenseViewModel>();
        final amount = double.parse(_amountController.text);
        final title = _titleController.text;
        final description = _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text;

        if (widget.expenseToEdit == null) {
          await expenseVM.addExpense(
            amount: amount,
            title: title,
            description: description,
            date: _selectedDate,
            categoryId: _selectedCategory!.id,
          );
        } else {
          final updatedExpense = Expense(
            id: widget.expenseToEdit!.id,
            title: title,
            description: description,
            amount: amount,
            date: _selectedDate,
            categoryId: _selectedCategory!.id,
            userId: widget.expenseToEdit!.userId,
          );
          await expenseVM.updateExpense(updatedExpense);
        }

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore nel salvataggio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catVM = context.watch<CategoryViewModel>();
    final isEditing = widget.expenseToEdit != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifica Spesa' : 'Nuova Spesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Inserisci un titolo'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione (opzionale)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Importo (€)'),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Inserisci un importo';
                  if (double.tryParse(value) == null)
                    return 'Inserisci un numero valido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                hint: const Text('Seleziona Categoria'),
                items: catVM.categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat.name));
                }).toList(),
                onChanged: (cat) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleziona una categoria' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitExpense,
                child: Text(isEditing ? 'Aggiorna Spesa' : 'Salva Spesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
