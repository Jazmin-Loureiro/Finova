import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/register_list_screen.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_scaffold.dart';
import '../../models/money_maker.dart';
import 'money_maker_form_screen.dart';
import '../../widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/register_provider.dart';

class MoneyMakerListScreen extends StatefulWidget {
  final int? initialMoneyMakerId; // <-- ID del MoneyMaker a enfocar cuando se crea uno
  const MoneyMakerListScreen({super.key, this.initialMoneyMakerId});

  @override
  State<MoneyMakerListScreen> createState() => _MoneyMakerListScreenState();
}

class _MoneyMakerListScreenState extends State<MoneyMakerListScreen> {
  bool isLoading = true;
  int selectedIndex = 0;
  PageController? pageController;

  Color fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.85);
    _loadMoneyMakers(); // usa el provider para cargar las fuentes de dinero
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }
 /// Cargar fuentes de dinero y enfocar si es necesario
  Future<void> _loadMoneyMakers() async {
    setState(() => isLoading = true);
    final provider = context.read<RegisterProvider>();
    await provider.loadMoneyMakers();
    if (provider.moneyMakers.isNotEmpty) {
      setState(() => selectedIndex = 0);
      await provider.loadRegisters(provider.moneyMakers[0].id);
    }
    setState(() => isLoading = false);
  }
 @override
Widget build(BuildContext context) {
  final dateFormat = DateFormat('dd/MM/yyyy');
  final scheme = Theme.of(context).colorScheme;
  //  Obtener datos del provider
  final registerProvider = context.watch<RegisterProvider>();
  final moneyMakers = registerProvider.moneyMakers;
  final registers = registerProvider.registers;
  final currencyBase = registerProvider.currencyBase;
  final currencySymbol = registerProvider.currencyBaseSymbol;

  return CustomScaffold(
    title: 'Fuentes de Dinero',
    currentRoute: 'money_makers',
    actions: [
       IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoneyMakerFormScreen()),
          ).then((value) async {
            if (value != null && value is MoneyMaker) {
              await _loadMoneyMakers();

              final provider = context.read<RegisterProvider>();
              final updatedMoneyMakers = provider.moneyMakers;

              int newIndex = updatedMoneyMakers.indexWhere((m) => m.id == value.id);
              if (newIndex == -1) newIndex = updatedMoneyMakers.length - 1;

              if (!mounted) return;
              setState(() => selectedIndex = newIndex);

              // ⚡ Esperar a que se monte el PageView
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (pageController != null && pageController!.hasClients) {
                  pageController!.animateToPage(
                    newIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          });
        },
      ),
      ],
      body: isLoading
          ? const LoadingWidget(message: "Cargando fuentes de dinero...")
          : moneyMakers.isEmpty
              ? const Center(child: Text("No hay fuentes de dinero"))
              : Column(
                  children: [
                    const SizedBox(height: 10),
                    if (pageController != null)
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: moneyMakers.length,
                          onPageChanged: (index) async {
                            setState(() => selectedIndex = index);
                            await context.read<RegisterProvider>().loadRegisters(moneyMakers[index].id);
                          },
                          itemBuilder: (context, index) {
                            final m = moneyMakers[index];
                            final isSelected = selectedIndex == index;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(
                                horizontal: isSelected ? 8 : 12,
                                vertical: isSelected ? 0 : 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [fromHex(m.color), fromHex(m.color)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: fromHex(m.color).withAlpha(100),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Stack(
                              children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Nombre de la fuente
                                    Text(
                                      m.name,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    // Nombre de la moneda
                                    Text(
                                      m.type ,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    // Balance principal 
                                        Text(
                                          '${m.currency?.symbol}${m.balance.toStringAsFixed(2)} ${m.currency?.code}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (currencyBase != m.currency?.code)
                                          Text(
                                            '≈ $currencySymbol${m.balanceConverted.toStringAsFixed(2)} $currencyBase',
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimary,
                                              fontSize: 20,
                                            ),
                                          ),
                                                                              const SizedBox(width: 8),
                                                                        // Balance reservado
                                      if (m.balance_reserved > 0)
                                        Text(
                                          'Reservado: ${m.currency?.symbol}${m.balance_reserved.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                              ),

                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MoneyMakerFormScreen(
                                            moneyMaker: m,
                                          ),
                                        ),
                                      ).then((_) async {
                                        await _loadMoneyMakers();
                                        if (moneyMakers.isNotEmpty) {
                                          await context.read<RegisterProvider>().loadRegisters(moneyMakers[selectedIndex].id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: scheme.primary,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child:  Icon(
                                        Icons.edit,
                                        size: 20,
                                         color: Theme.of(context).colorScheme.onSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Transacciones recientes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterListScreen(
                                  moneyMakerId: moneyMakers[selectedIndex].id,
                                  moneyMakerName: moneyMakers[selectedIndex].name,
                                ),
                              ),
                            );
                            if(updated == true || updated == null) {
                              pageController?.jumpToPage(selectedIndex);
                              await context.read<RegisterProvider>().loadRegisters(moneyMakers[selectedIndex].id);
                            }
                          },
                          child: Text(
                            "Ver mas",
                            style: TextStyle(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        
                  // Lista de registros
                  Expanded(
                    child: registers.isEmpty
                        ? const Center(child: Text("Sin registros"))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            //itemCount: registers.length,
                            itemCount: registers.length > 4 ? 4 : registers.length,
                            itemBuilder: (context, index) {
                              final r = registers[index];
                              final tipo =
                                  r.type == "income" ? "Ingreso" : "Gasto";
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icono principal
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: r.type == "income"
                                              ? Colors.green.withOpacity(0.15)
                                              : Colors.red.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          r.type == "income" ? Icons.arrow_downward : Icons.arrow_upward,
                                          color: r.type == "income" ? Colors.green : Colors.red,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Contenido principal
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Fila: Nombre + Tipo/Categoría a la izquierda, Fecha a la derecha
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Nombre + Tipo/Categoría
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        r.name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '$tipo • ${r.category.name}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Fecha a la derecha
                                                Text(
                                                  dateFormat.format(r.created_at),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 4),

                                            // Meta asociada (opcional)
                                            if (r.goal != null)
                                              Text(
                                                'Meta: ${r.goal!.name} - Reservado: ${r.currency.symbol}${r.reserved_for_goal}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                            const SizedBox(height: 4),

                                            // Monto
                                            Text(
                                              '${r.currency.symbol}${r.balance.toStringAsFixed(2)} ${r.currency.code}',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );

                            },
                          ),
                  ),
                ],
              ),
  );
}
}