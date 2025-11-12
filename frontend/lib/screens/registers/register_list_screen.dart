import 'package:flutter/material.dart';
import 'package:frontend/widgets/category_summary_chart_widget.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:frontend/widgets/month_header_widget.dart';
import 'package:frontend/widgets/register_item_widget.dart';
import 'package:frontend/widgets/custom_refresh_wrapper.dart';
import '../../services/api_service.dart';
import '../../models/register.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_scaffold.dart';

class RegisterListScreen extends StatefulWidget {
  final int moneyMakerId;
  final String moneyMakerName;
  const RegisterListScreen({
    super.key,
    required this.moneyMakerId,
    required this.moneyMakerName,
  });

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Register> registers = [];
  String? symbol = '';

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchRegisters();
    getSymbol();
  }

  Future<void> _fetchRegisters() async {
    setState(() => isLoading = true);
    try {
      registers = await api.getRegistersByMoneyMaker(widget.moneyMakerId);
      registers = registers.where((r) {
        return r.created_at.year == selectedDate.year &&
            r.created_at.month == selectedDate.month;
      }).toList();
    } catch (e) {
      registers = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> getSymbol() async {
    final user = await api.getUser();
    final currencySymbol = user?['currency_symbol'];
    setState(() => symbol = currencySymbol?.toString());
  }

  Map<String, double> getTotalsByCategory() {
    final Map<String, double> totals = {};
    for (var r in registers) {
      final category = r.category.name;
      totals[category] = (totals[category] ?? 0) + r.balance;
    }
    return totals;
  }

  Map<String, Color> getCategoryColors() {
    final Map<String, Color> map = {};
    for (var r in registers) {
      map[r.category.name] =
          Color(int.parse('0xff${r.category.color.substring(1)}'));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final totals = getTotalsByCategory();
    final colorsMap = getCategoryColors();
    final hasData = totals.values.any((v) => v > 0);

    return CustomScaffold(
      title: 'Registros de ${widget.moneyMakerName}',
      currentRoute: '/registers',
      body: isLoading
          ? const Center(child: LoadingWidget())
          : CustomRefreshWrapper(
              onRefresh: _fetchRegisters, 
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  MonthHeaderWidget(
                    date: selectedDate,
                    onPrevious: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month - 1,
                        );
                      });
                      _fetchRegisters();
                    },
                    onNext: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month + 1,
                        );
                      });
                      _fetchRegisters();
                    },
                  ),

                  const SizedBox(height: 10),

                  if (hasData)
                    CategorySummaryChartWidget(
                      totals: totals,
                      colorsMap: colorsMap,
                      symbol: symbol,
                    ),
                  const SizedBox(height: 8),

                  registers.isEmpty
                      ? const EmptyStateWidget(
                          title: "Aún no hay registros.",
                          message: "No has reservado ninguna cantidad aún.",
                          icon: Icons.receipt_long,
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: registers.length,
                          itemBuilder: (context, index) {
                            final r = registers[index];
                            return RegisterItemWidget(
                              register: r,
                              dateFormat: dateFormat,
                              fromHex: (hex) {
                                hex = hex.toUpperCase().replaceAll("#", "");
                                if (hex.length == 6) hex = "FF$hex";
                                return Color(int.parse(hex, radix: 16));
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
