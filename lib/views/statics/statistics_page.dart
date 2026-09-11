import 'package:aullet/viewmodels/statistics_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedYear = DateTime.now().year;
  int _year1 = DateTime.now().year;
  int? _month1;
  int _year2 = DateTime.now().year;
  int? _month2;
  Map<String, dynamic>? _comparison;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatisticsViewModel>().loadExpenses();
    });
  }

  Future<void> _doCompare() async {
    final vm = context.read<StatisticsViewModel>();
    final result = await vm.comparePeriods(_year1, _month1, _year2, _month2);
    setState(() => _comparison = result);
  }

  Widget _buildYearDropdown({required bool isFirst}) {
    final vm = context.watch<StatisticsViewModel>();
    final years = vm.allExpenses.map((e) => e.date.year).toSet().toList()..sort();
    final value = isFirst ? _year1 : _year2;
    return DropdownButton<int>(
      value: value,
      items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
      onChanged: (y) {
        if (y != null) setState(() => isFirst ? _year1 = y : _year2 = y);
      },
    );
  }

  Widget _buildMonthDropdown({required bool isFirst}) {
    final value = isFirst ? _month1 : _month2;
    return DropdownButton<int?>(
      value: value,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Tutti i mesi')),
        ...List.generate(12, (i) => i + 1).map((m) {
          return DropdownMenuItem<int?>(
            value: m,
            child: Text(_monthName(m)),
          );
        }),
      ],
      onChanged: (m) {
        if (isFirst) {
          _month1 = m;
        } else {
          _month2 = m;
        }
        setState(() {});
      },
    );
  }

  String _monthName(int month) {
    const months = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();
    final years = vm.allExpenses
        .map((e) => e.date.year)
        .toSet()
        .toList()
        ..sort();
    
    if (!years.contains(_selectedYear)) {
      years.insert(0, _selectedYear);
    }

    final monthlyTotals = vm.calculateMonthlyExpenses(_selectedYear);
    final maxMonthlyVal = monthlyTotals.values.isEmpty 
        ? 100.0 
        : monthlyTotals.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          items: years.map((y) {
                            return DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                          onChanged: (y) {
                            if (y != null) setState(() => _selectedYear = y);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int?>(
                          value: vm.monthFilter,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Tutti i mesi'),
                            ),
                            ...List.generate(12, (i) => i + 1).map((m) {
                              return DropdownMenuItem<int?>(
                                value: m,
                                child: Text(m.toString()),
                              );
                            }),
                          ],
                          onChanged: (m) => vm.setMonthFilter(m),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxMonthlyVal == 0 ? 100 : maxMonthlyVal * 1.2,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                const monthNames = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
                                int index = v.toInt() - 1;
                                if (index >= 0 && index < monthNames.length) {
                                  return Text(monthNames[index], style: const TextStyle(fontSize: 10));
                                }
                                return const Text('');
                              },
                              reservedSize: 28,
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(12, (index) {
                          int monthNumber = index + 1;
                          double val = monthlyTotals[monthNumber] ?? 0.0;
                          return BarChartGroupData(
                            x: monthNumber,
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                width: 14,
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const Text(
                    'Confronto Periodi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildYearDropdown(isFirst: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMonthDropdown(isFirst: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildYearDropdown(isFirst: false)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildMonthDropdown(isFirst: false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _doCompare,
                    child: const Text('Confronta'),
                  ),
                  const SizedBox(height: 24),
                  if (_comparison != null) ...[
                    Text('Totale Periodo 1: \$${(_comparison!["period1"] as double).toStringAsFixed(2)}'),
                    Text('Totale Periodo 2: \$${(_comparison!["period2"] as double).toStringAsFixed(2)}'),
                    Text('Differenza: \$${(_comparison!["difference"] as double).toStringAsFixed(2)}'),
                    Text('Variazione %: ${(_comparison!["percentChange"] as double).toStringAsFixed(1)}%'),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          alignment: BarChartAlignment.spaceAround,
                          maxY: [
                            _comparison!['period1'] as double,
                            _comparison!['period2'] as double,
                          ].reduce((a, b) => a > b ? a : b) * 1.2,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (x, meta) {
                                  if (x.toInt() == 0) return const Text('P1');
                                  return const Text('P2');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [BarChartRodData(toY: _comparison!['period1'], width: 28)],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [BarChartRodData(toY: _comparison!['period2'], width: 28)],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],    
                ],
              ),
            ),
    );
  }
}