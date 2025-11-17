import 'package:flutter/material.dart';
import 'package:frontend/models/balance_item.dart';
import 'package:frontend/models/currency.dart';
import 'package:frontend/widgets/statistics/sumary_bar_widget.dart';
import 'package:frontend/widgets/statistics/category_summary_chart_widget.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/loading_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();

  bool isLoading = true;
  late TabController _tabController;

  Map<String, double> incomeTotals = {};
  Map<String, double> expenseTotals = {};
  Map<String, Color> incomeColors = {};
  Map<String, Color> expenseColors = {};
  Map<String, String> incomeIcons = {};
  Map<String, String> expenseIcons = {};
  Map<String, BalanceItem> balancesByCurrency = {};
  Map<String, BalanceItem> balancesByMoneyMaker = {};

  Currency? userCurrency;

  int selectedRange = 30; // valores: 7, 30, 365

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }


    Map<String, double> _safeToDoubleMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data.map((key, value) =>
        MapEntry(key.toString(), (value as num).toDouble()));
    }
    return {}; 
  }

  Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('0xff$hex'));
  }


  Map<String, Color> _parseColors(dynamic json) {
    if (json is Map) {
      return json.map((key, value) {
        if (value is String) {
          return MapEntry(key.toString(), hexToColor(value));
        }
        return MapEntry(key.toString(), Colors.grey);
      });
    }
    return {};
  }


Future<void> _loadStatistics() async {
  try {

    final data = await api.getStatistics(selectedRange);
    userCurrency = Currency.fromJson(data['user_currency']);
    incomeTotals = _safeToDoubleMap(data['totals']['income']);
    expenseTotals = _safeToDoubleMap(data['totals']['expense']);

    incomeColors  = _parseColors(data['colors']['income']);
    expenseColors = _parseColors(data['colors']['expense']);

    incomeIcons = data['icons']?['income'] is Map
        ? Map<String, String>.from(data['icons']['income'])
        : {};
    expenseIcons = data['icons']?['expense'] is Map
        ? Map<String, String>.from(data['icons']['expense'])
        : {};

    final currencyMap = Map<String, dynamic>.from(
      data['balances']['by_currency'],
    );

    balancesByCurrency = {
      for (var entry in currencyMap.entries)
        entry.key: BalanceItem.fromJson(entry.value, entry.key),
    };

    final mmMap = Map<String, dynamic>.from(
      data['balances']['by_money_maker'],
    );

    balancesByMoneyMaker = {
      for (var entry in mmMap.entries)
        entry.key: BalanceItem.fromJson(entry.value, entry.key),
    };

  } catch (e) {
    debugPrint("Error loading statistics: $e");
  } finally {
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Estadísticas',
      currentRoute: 'statistics',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Ingresos'),
              Tab(text: 'Gastos'),
              Tab(text: 'Saldo'),
            ],
          ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: LoadingWidget(message: 'Cargando estadísticas...'),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        children: [
                          _rangeChips(),
                          Expanded(
                            child: CategorySummaryChartWidget(
                              title: "Ingresos por categoría",
                              subtitle: "¿De dónde proviene mi dinero?",
                              totals: incomeTotals,
                              userCurrency: userCurrency,
                              colorsMap: incomeColors,
                              iconsMap: incomeIcons,   // <-- nuevo
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          _rangeChips(),
                          Expanded(
                            child: CategorySummaryChartWidget(
                              title: "Gastos por categoría",
                              subtitle: "¿En qué estoy gastando más?",
                              totals: expenseTotals,
                              userCurrency: userCurrency,
                              colorsMap: expenseColors,
                              iconsMap: expenseIcons,   // <-- nuevo
                            ),
                          ),
                        ],
                      ),
                      ListView(
                        padding: const EdgeInsets.only(top: 12),
                        children: [
                          SummaryBarCardWidget(
                            title: "Saldo por divisas",
                            subtitle: "¿Cuánto tengo en cada moneda?",
                            totals: balancesByCurrency,
                            userCurrency: userCurrency,
                            showTotal: false,
                          ),

                          SummaryBarCardWidget(
                            title: "Saldo por cuentas",
                            subtitle: "¿Dónde tengo mi dinero?",
                            totals: balancesByMoneyMaker,
                            userCurrency: userCurrency,
                            showTotal: false,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }


    Widget _rangeChips() {
      final theme = Theme.of(context);
      final ranges = {
        7: "7 días",
        30: "30 días",
        365: "1 año",
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: ranges.entries.map((entry) {
              final isSelected = selectedRange == entry.key;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedRange = entry.key);
                    _loadStatistics();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
}