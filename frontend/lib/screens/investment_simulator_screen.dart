import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/simulation_result_card_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/info_icon_widget.dart';
import '../widgets/empty_state_widget.dart';

class InvestmentSimulatorScreen extends StatefulWidget {
  const InvestmentSimulatorScreen({super.key});

  @override
  State<InvestmentSimulatorScreen> createState() =>
      _InvestmentSimulatorScreenState();
}

class _InvestmentSimulatorScreenState extends State<InvestmentSimulatorScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();

  final _formKeyPf = GlobalKey<FormState>();
  final _formKeyCrypto = GlobalKey<FormState>();

  late TabController _tabController;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Plazo Fijo', 'icon': Icons.savings_outlined},
    {'label': 'Cripto', 'icon': Icons.currency_bitcoin_outlined},
  ];

  final TextEditingController montoController = TextEditingController();
  final TextEditingController diasController = TextEditingController();

  final TextEditingController montoCryptoController = TextEditingController();
  final TextEditingController diasCryptoController = TextEditingController();

  Map<String, dynamic>? resultadoPf;
  Map<String, dynamic>? resultadoCrypto;

  bool isLoadingPf = false;
  bool isLoadingCrypto = false;

  // Datos de cotización
  String coin = 'bitcoin';
  double? quoteCrypto;
  String? fuenteCrypto;
  DateTime? lastUpdateCrypto;

  int? userCurrencyId;
  bool isLoadingCurrency = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _checkCurrency();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          resultadoPf = null;
          resultadoCrypto = null;
          isLoadingPf = false;
          isLoadingCrypto = false;
        });
      }
    });
  }

  Future<void> _checkCurrency() async {
    final id = await api.getUserCurrency();
    setState(() {
      userCurrencyId = id;
      isLoadingCurrency = false;
    });
  }


  // Carga cotización cripto
  Future<void> _loadQuote(String coin) async {
    try {
      final q = await api.marketQuote(type: 'cripto', symbol: coin);
      final price = (q?['price_usd'] is num)
          ? (q!['price_usd'] as num).toDouble()
          : double.tryParse('${q?['price_usd']}');
      setState(() {
        quoteCrypto = price;
        fuenteCrypto = q?['fuente']?.toString();
        lastUpdateCrypto = DateTime.now();
      });
    } catch (_) {
      setState(() {
        quoteCrypto = null;
        fuenteCrypto = null;
      });
    }
  }

  Future<void> simulatePlazoFijo() async {
    if (!_formKeyPf.currentState!.validate()) return;

    setState(() {
      isLoadingPf = true;
      resultadoPf = null;
    });

    try {
      final monto = double.tryParse(montoController.text) ?? 100000;
      final dias = int.tryParse(diasController.text) ?? 30;
      final data = await api.simulatePlazoFijo(monto: monto, dias: dias);
      setState(() => resultadoPf = data);
    } catch (_) {
      setState(() => resultadoPf = {'error': 'Error al conectar con el servidor'});
    } finally {
      setState(() => isLoadingPf = false);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    return CustomScaffold(
      title: 'Simulador de Inversiones',
      currentRoute: 'investment_simulation',
      showNavigation: false,
      body: Column(
        children: [
          // 🔹 Tabs superiores (idéntico a ChallengeScreen)
          Container(
            color: surface.withOpacity(0.15),
            child: TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: textColor.withOpacity(0.7),
              indicatorColor: primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
              tabs: _tabs
                  .map((t) => Tab(
                        icon: Icon(t['icon'], size: 20),
                        text: t['label'],
                      ))
                  .toList(),
            ),
          ),

          // 🔹 Contenido de cada tab — mismo alto, swipe suave
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildPlazoFijo(theme, surface, textColor, primary),
                _buildCrypto(theme, surface, textColor, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPlazoFijo(
    ThemeData theme, Color surface, Color 
    textColor, Color primary) {
      if (isLoadingCurrency) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userCurrencyId != 3) {
      return const EmptyStateWidget(
        icon: Icons.savings_rounded,
        title: "Simulador no disponible",
        message:
            "El simulador de Plazo Fijo solo está habilitado para usuarios con moneda base ARS. "
            "Podés cambiarla desde tu perfil si querés acceder a esta herramienta.",
      );
    }

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

        // Formulario
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
            key: _formKeyPf,
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
                    if (value == null || value.isEmpty) return 'Ingresá un monto';
                    final monto = double.tryParse(value);
                    if (monto == null || monto < 1000) {
                      return 'El monto mínimo es \$1.000';
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
                    if (value == null || value.isEmpty) return 'Ingresá los días';
                    final dias = int.tryParse(value);
                    if (dias == null || dias < 30) {
                      return 'El mínimo es 30 días';
                    }
                    if (dias > 365) return 'Máximo 365 días';
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoadingPf ? null : simulatePlazoFijo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

        if (isLoadingPf)
          const LoadingWidget(message: "Simulando inversión..."),
        if (!isLoadingPf && resultadoPf != null) ...[
          const SizedBox(height: 20),
          if (resultadoPf!['error'] != null)
            Text(resultadoPf!['error'],
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center)
          else
            SimulationResultCard(
              resultado: resultadoPf!,
              ultimaActualizacion:
                  resultadoPf!['ultima_actualizacion']?.toString(),
            ),
        ],
      ],
    );
  }

  Widget _buildCrypto(
      ThemeData theme, Color surface, Color textColor, Color primary) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Text(
            "Simulá tu inversión en Cripto",
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
            title: "¿Qué es una inversión cripto?",
            message:
                "Invertir en criptomonedas significa comprar activos digitales como Bitcoin o Ethereum, "
                "esperando que su valor aumente con el tiempo. Son volátiles, por lo que el riesgo es mayor.",
          ),
        ),
        const SizedBox(height: 25),

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
            key: _formKeyCrypto,
            child: Column(
              children: [
                TextFormField(
                  controller: montoCryptoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto a invertir (USD)',
                    prefixIcon: Icon(Icons.attach_money, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresá un monto';
                    final monto = double.tryParse(v);
                    if (monto == null || monto < 10) return 'Mínimo USD 10';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: diasCryptoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Días estimados',
                    prefixIcon: Icon(Icons.calendar_today, color: primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresá los días';
                    final dias = int.tryParse(v);
                    if (dias == null || dias < 1) return 'Mínimo 1 día';
                    if (dias > 365) return 'Máximo 365 días';
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                DropdownButtonFormField<String>(
                  initialValue: coin,
                  decoration: InputDecoration(
                    labelText: 'Criptomoneda',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'bitcoin', child: Text('Bitcoin (BTC)')),
                    DropdownMenuItem(
                        value: 'ethereum', child: Text('Ethereum (ETH)')),
                    DropdownMenuItem(
                        value: 'solana', child: Text('Solana (SOL)')),
                    DropdownMenuItem(
                        value: 'dogecoin', child: Text('Dogecoin (DOGE)')),
                  ],
                  onChanged: (v) async {
                    setState(() => coin = v ?? 'bitcoin');
                    await _loadQuote(coin);
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoadingCrypto
                        ? null
                        : () async {
                            if (!_formKeyCrypto.currentState!.validate()) return;
                            setState(() {
                              isLoadingCrypto = true;
                              resultadoCrypto = null;
                            });
                            final monto =
                                double.tryParse(montoCryptoController.text) ??
                                    1000;
                            final dias =
                                int.tryParse(diasCryptoController.text) ?? 30;
                            await _loadQuote(coin);
                            final data = await api.simulateCrypto(
                                monto: monto, coin: coin, dias: dias);
                            setState(() {
                              resultadoCrypto = data;
                              isLoadingCrypto = false;
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
        if (isLoadingCrypto)
          const LoadingWidget(message: "Simulando inversión..."),
        if (!isLoadingCrypto && resultadoCrypto != null) ...[
          const SizedBox(height: 20),
          if (resultadoCrypto!['error'] != null)
            Text(resultadoCrypto!['error'],
                style: const TextStyle(color: Colors.red))
          else
            SimulationResultCard(
              resultado: resultadoCrypto!,
              ultimaActualizacion:
                  resultadoCrypto!['ultima_actualizacion']?.toString(),
            ),
        ],
      ],
    );
  }
}
