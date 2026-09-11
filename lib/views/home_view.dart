import 'package:aullet/repositories/category_viewmodel.dart';
import 'package:aullet/viewmodels/expense_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../utils/icon_map.dart';
import '../utils/color_utils.dart';
import 'new_expense_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseViewModel>().loadExpenses();
      context.read<CategoryViewModel>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final catVM = context.watch<CategoryViewModel>();

    return Scaffold(
      body: expenseVM.isLoading || catVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(expenseVM, catVM),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () => Navigator.pushNamed(context, '/statistics'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewExpensePage()),
          ).then((_) {
            context.read<ExpenseViewModel>().loadExpenses();
          });
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBody(ExpenseViewModel expenseVM, CategoryViewModel catVM) {
    final expenses = expenseVM.expenses;
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Non ci sono spese inserite',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi Spesa'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewExpensePage()),
                ).then((_) {
                  context.read<ExpenseViewModel>().loadExpenses();
                });
              },
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final cat = catVM.categories.firstWhere(
          (c) => c.id == exp.categoryId,
          orElse: () => Category(id: '', name: 'Unknown', icon: 'category', color: 'FF000000'),
        );
        final iconData = iconMap[cat.icon] ?? Icons.category;
        final color = parseHexColor(cat.color);
        final date = exp.date;
        final formattedDate = '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';

        return ListTile(
          leading: Icon(iconData, color: color),
          title: Text(
            exp.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            '€ ${exp.amount.toStringAsFixed(2)} - $formattedDate${exp.description != null && exp.description!.isNotEmpty ? '\n${exp.description}' : ''}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewExpensePage(expenseToEdit: exp),
                    ),
                  ).then((_) {
                    context.read<ExpenseViewModel>().loadExpenses();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  if (exp.id != null) {
                    await context.read<ExpenseViewModel>().deleteExpense(exp.id!);
                    if (!context.mounted) return;
                    context.read<ExpenseViewModel>().loadExpenses();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}