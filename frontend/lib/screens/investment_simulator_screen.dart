import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/simulation_result_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/info_icon_widget.dart';

class InvestmentSimulatorScreen extends StatefulWidget {
  const InvestmentSimulatorScreen({super.key});

  @override
  State<InvestmentSimulatorScreen> createState() =>
      _InvestmentSimulatorScreenState();
}

class _InvestmentSimulatorScreenState extends State<InvestmentSimulatorScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TabController _tabController;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Plazo Fijo', 'icon': Icons.savings_outlined},
    {'label': 'Cripto', 'icon': Icons.currency_bitcoin_outlined},
    {'label': 'Acciones', 'icon': Icons.show_chart_outlined},
    {'label': 'Bonos', 'icon': Icons.account_balance_outlined},
  ];

  final TextEditingController montoController = TextEditingController();
  final TextEditingController diasController = TextEditingController();

  Map<String, dynamic>? resultado;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  Future<void> simulateInvestment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      resultado = null;
    });

    try {
      final monto = double.tryParse(montoController.text) ?? 100000;
      final dias = int.tryParse(diasController.text) ?? 30;

      final data = await api.simulatePlazoFijo(monto: monto, dias: dias);

      setState(() {
        resultado = data;
      });
    } catch (e) {
      setState(() {
        resultado = {'error': 'Error al conectar con el servidor'};
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final background = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return CustomScaffold(
      title: 'Simulador de Inversiones',
      currentRoute: 'investment_simulation',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              background.withOpacity(0.97),
              background.withOpacity(0.85),
              primary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 🔹 Tabs superiores (estilo ChallengeScreen)
            Container(
              width: double.infinity,
              color: surface.withOpacity(0.15),
              child: TabBar(
                controller: _tabController,
                isScrollable: true, // 👉 evita cortes de texto
                tabAlignment: TabAlignment.center, // 👉 centra visualmente las pestañas
                labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                labelColor: primary,
                unselectedLabelColor: textColor.withOpacity(0.7),
                indicatorColor: primary,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStatePropertyAll(primary.withOpacity(0.06)),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
                tabs: _tabs
                    .map(
                      (t) => Tab(
                        icon: Icon(t['icon'], size: 20),
                        text: t['label'],
                      ),
                    )
                    .toList(),
              ),

            ),

            // 🔹 Contenido de cada tab
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlazoFijo(theme, surface, textColor, primary),
                    _buildComingSoon('Cripto', theme),
                    _buildComingSoon('Acciones', theme),
                    _buildComingSoon('Bonos', theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlazoFijo(
      ThemeData theme, Color surface, Color textColor, Color primary) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Simulá tu Plazo Fijo",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: InfoIcon(
            title: "¿Qué es un plazo fijo?",
            message:
                "Es una inversión donde depositás dinero durante un tiempo determinado "
                "y obtenés intereses al finalizar. No podés retirarlo antes del vencimiento.\n\n"
                "Ejemplo: \$100.000 a 30 días genera una ganancia aprox. de \$9.410 con una TNA del 114,4%.",
          ),
        ),
        const SizedBox(height: 25),

        // 💳 Tarjeta principal translúcida
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: surface.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto a invertir',
                    prefixIcon: Icon(Icons.attach_money, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá un monto';
                    }
                    final monto = double.tryParse(value);
                    if (monto == null || monto < 1000) {
                      return 'El monto mínimo es \$1.000';
                    }
                    if (monto > 10000000) {
                      return 'El máximo es \$10.000.000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: diasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Días de inversión',
                    prefixIcon: Icon(Icons.calendar_today, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá los días';
                    }
                    final dias = int.tryParse(value);
                    if (dias == null || dias < 30) {
                      return 'El mínimo es 30 días';
                    }
                    if (dias > 365) {
                      return 'El máximo es 365 días';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // 🟩 Botón principal Finova
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : simulateInvestment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: const Text('Simular inversión'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 35),

        // 🔹 Loading o resultado
        if (isLoading)
          const LoadingWidget(message: "Simulando inversión..."),
        if (!isLoading && resultado != null) ...[
          const SizedBox(height: 20),
          if (resultado!['error'] != null)
            Text(
              resultado!['error'],
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            )
          else
            SimulationResultCard(
              resultado: resultado!,
              ultimaActualizacion:
                  resultado!['ultima_actualizacion']?.toString(),
            ),
        ],
      ],
    );
  }

  Widget _buildComingSoon(String label, ThemeData theme) {
    final textColor = theme.colorScheme.onSurface;
    return Center(
      child: Text(
        '$label próximamente',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textColor.withOpacity(0.6),
        ),
      ),
    );
  }
}
