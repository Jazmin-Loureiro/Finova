import 'package:flutter/material.dart';
import 'package:frontend/screens/register_list_screen.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_scaffold.dart';
import '../models/money_maker.dart';
import 'money_maker_form_screen.dart';
import '../widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../providers/register_provider.dart';

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
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MoneyMakerFormScreen()),).then((newMaker) async {
              if (newMaker != null && newMaker is MoneyMaker) {
                // Recargar lista desde el servidor
                await _loadMoneyMakers();
                // Enfocar el nuevo MoneyMaker
                final provider = context.read<RegisterProvider>();
                final updatedMoneyMakers = provider.moneyMakers;
              //  Buscar por ID si existe 
                int newIndex = updatedMoneyMakers.indexWhere((m) => m.id == newMaker.id);
                if (newIndex == -1) {
                  newIndex = updatedMoneyMakers.indexWhere((m) => m.name == newMaker.name);
                }
                if (newIndex == -1) newIndex = updatedMoneyMakers.length - 1;

                if (!mounted) return;
                setState(() => selectedIndex = newIndex);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (pageController!.hasClients) {
                    pageController!.animateToPage(
                      newIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
                await provider.loadRegisters(updatedMoneyMakers[newIndex].id);
              }
            });
          },
          /**Esto podria ser un widget */
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child:  Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary,),
          ),
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
                        height: 180,
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
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        m.name,
                                        style: TextStyle(
                                           color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        m.currency?.name ?? '',
                                        style: TextStyle(
                                           color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${m.currency?.symbol}${m.balance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                           color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 26,
                                        ),
                                      ),
                                      if (currencyBase != m.currency?.code)
                                        Text(
                                          '≈ $currencySymbol${m.balanceConverted.toStringAsFixed(2)}',
                                          style: TextStyle(
                                             color: Theme.of(context).colorScheme.onPrimary,
                                            fontSize: 20,
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
                                        color: scheme.primary, 
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: scheme.primary
                                            .withAlpha(100),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child:  Icon(
                                        Icons.edit,
                                        size: 20,
                                         color: Theme.of(context).colorScheme.onPrimary,
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
                            // color: Theme.of(context).colorScheme.onPrimary,
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
                  const SizedBox(height: 10),
                  // 🔹 Lista de registros
                  Expanded(
                    child: registers.isEmpty
                        ? const Center(child: Text("Sin registros"))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            //itemCount: registers.length,
                            itemCount: registers.length > 4 ? 4 : registers.length,
                            itemBuilder: (context, index) {
                              final r = registers[index];
                              final tipo =
                                  r.type == "income" ? "Ingreso" : "Gasto";
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  leading: Icon(
                                    r.type == "income"
                                        ? Icons.arrow_downward
                                        : Icons.arrow_upward,
                                    color: r.type == "income"
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  title: Text(
                                    r.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Categoria: ${r.category.name}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$tipo - ${r.currency.code} ${r.currency.symbol}${r.balance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            // color: Theme.of(context).colorScheme.onPrimary
                                             ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    dateFormat.format(r.created_at),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          Color.fromARGB(255, 51, 50, 50),
                                    ),
                                  ),
                                  isThreeLine: true,
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