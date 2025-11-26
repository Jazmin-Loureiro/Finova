import 'package:flutter/material.dart';
import 'package:frontend/helpers/format_utils.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/generic_selector.dart';
import 'package:frontend/widgets/loading_widget.dart';
import 'package:frontend/widgets/register_item_widget.dart';
import 'package:frontend/widgets/custom_refresh_wrapper.dart';
import '../../services/api_service.dart';
import '../../models/register.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_scaffold.dart';

class RegisterListScreen extends StatefulWidget {
  final int? moneyMakerId;
  final String? moneyMakerName;

  const RegisterListScreen({
    super.key,
     this.moneyMakerId,
     this.moneyMakerName,
  });

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Register> allRegisters = [];
  Map<String, List<Register>> groupedByDate = {};
  String? symbol = '';

  // ==== FILTROS ====
  String selectedType = "all"; 
  String? selectedCategory;
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchRegisters(),
      getSymbol(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchRegisters() async {
    try {
      allRegisters = await api.getAllRegister( moneyMakerId: widget.moneyMakerId, type: selectedType, category: selectedCategory,  from: selectedFromDate, to: selectedToDate, search: searchQuery,);
    _applyGrouping();
  } catch (e) {
    allRegisters = [];
    _applyGrouping();
  }
}

  Future<void> getSymbol() async {
    final user = await api.getUser();
    symbol = user?['currency_symbol'];
  }

  void _applyGrouping() {
    final Map<String, List<Register>> map = {};
    for (var r in allRegisters) {
      final key = DateFormat('dd/MM/yyyy').format(r.created_at.toLocal());
      map[key] = (map[key] ?? [])..add(r);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        final da = DateFormat('dd/MM/yyyy').parse(a);
        final db = DateFormat('dd/MM/yyyy').parse(b);
        return db.compareTo(da);
      });
    setState(() {
      groupedByDate = {for (var k in sortedKeys) k: map[k]!};
    });
  }

    void _openSelector<T>({
      required String title,
      required List<T> items,
      required String Function(T) itemLabel,
      required ValueChanged<T> onSelected,
      }) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => GenericSelector<T>(
            title: title,
            items: items,
            itemLabel: itemLabel,
            onSelected: onSelected,
          ),
        );
      }

  // SELECTOR TIPO
  void _openTypeSelector() {
    _openSelector<String>(
      title: "Tipo",
      items: ["all", "income", "expense"],
      itemLabel: (v) {
        switch (v) {
          case "income": return "Ingresos";
          case "expense": return "Gastos";
          default: return "Todos";
        }
      },
      onSelected: (v) {
        selectedType = v;
        _fetchRegisters();
      },
    );
  }

  //  SELECTOR CATEGORÍA
  void _openCategorySelector() {
    final categories =
        allRegisters.map((r) => r.category.name).toSet().toList();

    _openSelector<String>(
      title: "Categoría",
      items: ["Todas", ...categories],
      itemLabel: (v) => v,
      onSelected: (v) {
        selectedCategory = v == "Todas" ? null : v;
        _fetchRegisters();
      },
    );
  }

  //  SELECTOR FECHA
  void _openDateSelector() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (range != null) {
      selectedFromDate = DateTime(range.start.year, range.start.month, range.start.day);
      selectedToDate = DateTime(range.end.year, range.end.month, range.end.day);
      _fetchRegisters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
    title: widget.moneyMakerName != null
        ? 'Registros de ${widget.moneyMakerName}'
        : 'Registros',
      currentRoute: '/registers',
      showNavigation: false,
      body: isLoading
          ? const Center(child: LoadingWidget())
          : CustomRefreshWrapper(
              onRefresh: _fetchRegisters,
              padding: const EdgeInsets.only(bottom: 20),
              child: ListView(
                padding: const EdgeInsets.only(top: 10),
                children: [
                  // ==== FILTROS ====
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Tipo
                        FilterChip(
                          labelStyle: TextStyle(fontSize: 16),
                          selectedColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
                          label: Row(
                            children: [
                              Text(selectedType == "all" ? "Tipo: Todos"
                                    : selectedType == "income"
                                     ? "Ingresos" : "Gastos",
                              ),
                              if (selectedType != "all")
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close, size: 16),
                                ),
                            ],
                          ),
                          selected: selectedType != "all",
                          onSelected: (_) {
                            if (selectedType != "all") {
                              selectedType = "all";
                              _fetchRegisters();
                            } else {
                              _openTypeSelector();
                            }
                          },
                        ),

                        const SizedBox(width: 10),

                        // Categoría
                        FilterChip(
                          labelStyle: TextStyle(fontSize: 16),
                          selectedColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
                          label: Row(
                            children: [
                              Text(selectedCategory ?? "Categoría: Todas"),
                              if (selectedCategory != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close, size: 16),
                                ),
                            ],
                          ),
                          selected: selectedCategory != null,
                          onSelected: (_) {
                            if (selectedCategory != null) {
                              selectedCategory = null;
                              _fetchRegisters();
                            } else {
                              _openCategorySelector();
                            }
                          },
                        ),

                        const SizedBox(width: 10),

                        // Fecha
                        FilterChip(
                          labelStyle: TextStyle(fontSize: 16),
                          selectedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          label: Row(
                            children: [
                              Text(
                                selectedFromDate == null ? "Fecha"
                                    : "${DateFormat('dd/MM/yyyy').format(selectedFromDate!)} → " "${DateFormat('dd/MM/yyy').format(selectedToDate!)}",
                              ),
                              if (selectedFromDate != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(Icons.close, size: 16),
                                ),
                            ],
                          ),
                          selected: selectedFromDate != null,
                          onSelected: (_) {
                            if (selectedFromDate != null) {
                              selectedFromDate = null;
                              selectedToDate = null;
                              _fetchRegisters();
                            } else {
                              _openDateSelector();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Buscador
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _fetchRegisters();
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar registro...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==== LISTA ====
                  if (groupedByDate.isEmpty)
                    const EmptyStateWidget(
                      title: "Sin registros",
                      message: "No hay movimientos con estos filtros.",
                      icon: Icons.receipt_long,
                    )
                  else
                    ...groupedByDate.entries.map((entry) {
                      final date = entry.key;
                      final items = entry.value;
                      final totalOfDay = items.fold<double>( 0,(sum, r) => sum + (r.type == "income" ? r.balance : -r.balance));
                      final parsed = DateFormat('dd/MM/yyyy').parse(date);

                      final prettyDate = DateFormat( "d 'de' MMMM 'de' yyyy",Localizations.localeOf(context).toString(),).format(parsed);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                            Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // FECHA (izquierda)
                              Text(
                                prettyDate,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),

                            if (widget.moneyMakerId != null) // Mostrar total solo si es vista por fuente
                              Text(
                                formatCurrency(
                                  totalOfDay,
                                  Localizations.localeOf(context).toString(),
                                  symbolOverride: symbol,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),

                            ],
                          ),
                        ),

                          ...items.map(
                            (r) => RegisterItemWidget(
                              register: r,
                              dateFormat: DateFormat('dd/MM/yyyy'),
                              fromHex: (hex) {
                                hex = hex.toUpperCase().replaceAll("#", "");
                                if (hex.length == 6) hex = "FF$hex";
                                return Color(int.parse(hex, radix: 16));
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}
