import 'package:flutter/material.dart';
import 'package:frontend/screens/registers/register_list_screen.dart';
import 'package:frontend/widgets/empty_state_widget.dart';
import 'package:frontend/widgets/info_icon_widget.dart';
import 'package:frontend/widgets/register_item_widget.dart';
import 'package:frontend/widgets/custom_refresh_wrapper.dart';
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
    final registerProvider = context.watch<RegisterProvider>();
    final moneyMakers = registerProvider.moneyMakers;
    final registers = registerProvider.registers;
    final currencyBase = registerProvider.currencyBase;
    final currencySymbol = registerProvider.currencyBaseSymbol;

    return CustomScaffold(
      title: 'Fuentes de Dinero',
      currentRoute: 'money_makers',
      actions: [
        InfoIcon(
          title: 'Fuentes de dinero',
          message:
              'Las fuentes de dinero representan tus cuentas, billeteras o medios de pago.\n\n'
              'Finova te permite gestionar múltiples fuentes para tener un control total de tus finanzas.\n\n'
              'Además, podés asignar una moneda específica a cada fuente y administrar distintos tipos de divisas con el tipo de cambio actualizado en tiempo real.',
          iconSize: 25,
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: scheme.onPrimary),
            tooltip: 'Agregar nueva fuente de dinero',
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
                )
              : CustomRefreshWrapper(
                  onRefresh: _loadMoneyMakers,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      // Carrusel de fuentes
                      SizedBox(
                        height: 210,
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: moneyMakers.length,
                          onPageChanged: (index) async {
                            setState(() => selectedIndex = index);
                            isPageLoading = true;
                            await context.read<RegisterProvider>().loadRegisters(moneyMakers[index].id);
                            if (mounted) setState(() => isPageLoading = false);
                          },
                          itemBuilder: (context, index) {
                            final m = moneyMakers[index];
                            final isSelected = selectedIndex == index;
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
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6): Colors.black.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.name,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          m.type!.name,
                                          style: TextStyle(
                                            color: subTextColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '${m.currency?.symbol}${formatCurrency(m.balance, m.currency?.code ?? currencyBase)} ${m.currency?.code ?? ''}',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (m.balance_reserved > 0)
                                          Row(
                                            children: [
                                              Text(
                                                'Reserva: +${m.currency?.symbol}${formatCurrency(m.balance_reserved, m.currency?.code ?? currencyBase)} ${m.currency?.code ?? ''}',
                                                style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              InfoIcon(
                                                title: 'Dinero reservado',
                                                message:
                                                    'El dinero reservado corresponde a los fondos asignados a tus metas financieras.\n\n'
                                                    '🟣 No está disponible para:\n'
                                                    '• Gastos diarios\n'
                                                    '• Nuevas metas\n\n'
                                                    '🔓 Cuando una meta finaliza o se vence, ese dinero vuelve automáticamente a estar disponible.\n\n'
                                                    '💡 Consejo: Reservar fondos te ayuda a cumplir objetivos sin gastar por error el dinero destinado a tus metas.',
                                                iconSize: 20,
                                              ),
                                            ],
                                          ),
                                        const Spacer(),
                                        if (currencyBase != m.currency?.code)
                                          Row(
                                            children: [
                                              Text(
                                                'Total ≈ $currencySymbol${formatCurrency(m.balanceConverted, currencyBase)}',
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
                                                    'Este valor es estimativo y puede variar según el mercado.',
                                                iconSize: 20,
                                              ),
                                            ],
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
                                          color: isDark ? Colors.white.withOpacity(0.15): Colors.black12,
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

                      //Sección de transacciones recientes
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
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
                                if (updated == true || updated == null) {
                                  pageController?.jumpToPage(selectedIndex);
                                  await context.read<RegisterProvider>().loadRegisters(moneyMakers[selectedIndex].id);
                                }
                              },
                              child: Text(
                                "Ver más",
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

                      if (isPageLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (registers.isEmpty)
                        const EmptyStateWidget(
                          icon: Icons.account_balance_wallet_outlined,
                          title: "No hay transacciones",
                          message: "Agrega un registro de dinero para comenzar a gestionar tus finanzas.",
                        )
                      else
                        ...registers.take(4).map(
                          (r) => Padding( 
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: RegisterItemWidget(
                              register: r,
                              dateFormat: dateFormat,
                              fromHex: fromHex,
                            ),
                            ),
                        ),
                    ],
                  ),
                ),
    );
  }
}