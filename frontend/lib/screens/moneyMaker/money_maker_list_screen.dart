import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/register_list_screen.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/info_icon_widget.dart';
import 'package:frontend/widgets/register_item_widget.dart';
import 'package:intl/intl.dart';
import 'package:frontend/helpers/format_utils.dart';
import '../../widgets/custom_scaffold.dart';
import '../../models/money_maker.dart';
import 'money_maker_form_screen.dart';
import '../../widgets/loading_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/register_provider.dart';

class MoneyMakerListScreen extends StatefulWidget {
  final int? initialMoneyMakerId; 
  const MoneyMakerListScreen({super.key, this.initialMoneyMakerId});

  @override
  State<MoneyMakerListScreen> createState() => _MoneyMakerListScreenState();
}

class _MoneyMakerListScreenState extends State<MoneyMakerListScreen> {
  bool isLoading = true;
  int selectedIndex = 0;
  PageController? pageController;
  bool isPageLoading = false;

  Color fromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse(hexColor, radix: 16));
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(viewportFraction: 0.85);
    _loadMoneyMakers(); 
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

              //  Esperar a que se monte el PageView
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
              ? const EmptyStateWidget(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "No hay fuentes de dinero",
                  message:
                      "Agrega una fuente de dinero para comenzar a gestionar tus finanzas.",
                ): Column(
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
                            isPageLoading = true;
                            await context.read<RegisterProvider>().loadRegisters(moneyMakers[index].id);
                             if (mounted) {
                              setState(() => isPageLoading = false);
                            }
                          },
                          itemBuilder: (context, index) {
                          final m = moneyMakers[index];
                          final isSelected = selectedIndex == index;

                          //  Detectar color base y definir contraste
                          final baseColor = fromHex(m.color);
                          bool isColorDark(Color color) {
                            double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
                            return luminance < 0.5;
                          }

                          final isDark = isColorDark(baseColor);
                          final textColor = isDark ? Colors.white : Colors.black87;
                          final subTextColor = isDark ? Colors.white.withOpacity(0.9) : Colors.black;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.symmetric(
                              horizontal: isSelected ? 0 : 10,
                          //    vertical: isSelected ? 5 : 10,
                            ),
                            decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              baseColor.withOpacity(0.9),
                              baseColor.withOpacity(0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          //  Borde dinámico según el brillo del color
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.6)   // borde blanco sobre fondo oscuro
                                : Colors.black.withOpacity(0.5),  // borde negro sobre fondo claro
                            width: 1,
                          ),
                        ),
                            child: Stack(
                              children: [
                                // Fondo decorativo
                                Positioned(
                                  bottom: -40,
                                  right: -30,
                                  child: Icon(
                                    Icons.blur_on,
                                    size: 160,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.black.withOpacity(0.05),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            m.name,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w600,                     
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 1),

                                      Text(
                                        m.type.toUpperCase(),
                                        style: TextStyle(
                                          color: subTextColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 1),

                                      Text(
                                        '${m.currency?.symbol}${formatCurrency(m.balance, m.currency?.code ?? currencyBase)}${m.currency?.code ?? ''}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      if (currencyBase != m.currency?.code)
                                        Row(
                                          children: [
                                            Text(
                                              '≈ $currencySymbol${formatCurrency(m.balanceConverted, currencyBase)} ${m.currency?.code ?? ''}',
                                              style: TextStyle(
                                                color: subTextColor,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InfoIcon(
                                              title: 'Conversión de moneda',
                                              message: 
                                                  'Fuente: Open Exchange Rates\n'
                                                  'Última actualización: ${DateFormat('dd/MM/yyyy').format(m.currency!.updatedAt!)}\n\n'
                                                  'Este valor es un estimativo. Las tasas pueden variar según el mercado y el momento de la conversión.',
                                              iconSize: 18,
                                            ),
                                          ],
                                        ),
                                      const Spacer(),
                                      if (m.balance_reserved > 0)
                                        Text(
                                          'Reservado: ${m.currency?.symbol}${formatCurrency(m.balance_reserved, m.currency?.code ?? currencyBase)}${m.currency?.code ?? ''}',
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 16,
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
                                          builder: (context) => MoneyMakerFormScreen(moneyMaker: m),
                                        ),
                                      ).then((_) async {
                                        await _loadMoneyMakers();
                                        if (moneyMakers.isNotEmpty) {
                                          await context
                                              .read<RegisterProvider>()
                                              .loadRegisters(moneyMakers[selectedIndex].id);
                                        }
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark ? Colors.white30 : Colors.black26,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(Icons.edit, color: textColor, size: 18),
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
                child: isPageLoading
                  ? const Center (child: CircularProgressIndicator())
                    : registers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.account_balance_wallet_outlined,
                        title: "No hay transacciones",
                        message: "Agrega un registro de dinero para comenzar a gestionar tus finanzas.",
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: registers.length > 4 ? 4 : registers.length,
                        itemBuilder: (context, index) {
                          final r = registers[index];
                          return RegisterItemWidget(
                            register: r,
                            dateFormat: dateFormat,
                            fromHex: fromHex,
                          );
                        },
                      ),
              ),
                ],
              ),
  );
}
}