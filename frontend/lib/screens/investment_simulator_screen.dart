import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final _formKeyPf = GlobalKey<FormState>();
  final _formKeyCrypto = GlobalKey<FormState>();
  final _formKeyStock = GlobalKey<FormState>();
  final _formKeyBond = GlobalKey<FormState>();

  late TabController _tabController;
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Plazo Fijo', 'icon': Icons.savings_outlined},
    {'label': 'Cripto', 'icon': Icons.currency_bitcoin_outlined},
    {'label': 'Acciones', 'icon': Icons.show_chart_outlined},
    {'label': 'Bonos', 'icon': Icons.account_balance_outlined},
  ];

  final TextEditingController montoController = TextEditingController();
  final TextEditingController diasController = TextEditingController();

  final TextEditingController montoCryptoController = TextEditingController();
  final TextEditingController diasCryptoController = TextEditingController();

  final TextEditingController montoStockController = TextEditingController();
  final TextEditingController diasStockController = TextEditingController();

  final TextEditingController montoBondController = TextEditingController();
  final TextEditingController diasBondController = TextEditingController();

  Map<String, dynamic>? resultadoPf;
  Map<String, dynamic>? resultadoCrypto;
  Map<String, dynamic>? resultadoStock;
  Map<String, dynamic>? resultadoBond;

  bool isLoadingPf = false;
  bool isLoadingCrypto = false;
  bool isLoadingStock = false;
  bool isLoadingBond = false;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // 👉 limpia resultado/cargas al cambiar de pestaña
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          resultadoPf = null;
          resultadoCrypto = null;
          resultadoStock = null;
          resultadoBond = null;
          isLoadingPf = false;
          isLoadingCrypto = false;
          isLoadingStock = false;
          isLoadingBond = false;
        });
      }
    });
  }

  // Selecciones por tab
  String coin = 'bitcoin';
  String stock = 'AAPL';
  String bono  = 'TLT';

  // Cotización visible debajo del selector (se actualiza al cambiarlo)
  double? quoteCrypto;
  double? quoteStock;
  double? quoteBond;
  String? fuenteCrypto;
  String? fuenteStock;
  String? fuenteBond;
  DateTime? lastUpdateCrypto;
  DateTime? lastUpdateStock;
  DateTime? lastUpdateBond;


  String? quoteFuente;

  // 🔹 Carga de cotización de un activo específico
Future<void> _loadQuote(String type, String symbol) async {
  try {
    final q = await api.marketQuote(type: type, symbol: symbol);
    final price = (q?['price_usd'] is num)
        ? (q!['price_usd'] as num).toDouble()
        : double.tryParse('${q?['price_usd']}');

    setState(() {
      if (type == 'cripto') {
        quoteCrypto = price;
        fuenteCrypto = q?['fuente']?.toString();
        lastUpdateCrypto = DateTime.now();
      } else if (type == 'accion') {
        quoteStock = price;
        fuenteStock = q?['fuente']?.toString();
        lastUpdateStock = DateTime.now();
      } else if (type == 'bono') {
        quoteBond = price;
        fuenteBond = q?['fuente']?.toString();
        lastUpdateBond = DateTime.now();
      }
    });
  } catch (e) {
    setState(() {
      if (type == 'cripto') {
        quoteCrypto = null; fuenteCrypto = null;
      } else if (type == 'accion') {
        quoteStock = null; fuenteStock = null;
      } else if (type == 'bono') {
        quoteBond = null; fuenteBond = null;
      }
    });
  }
}



  Future<void> simulateInvestment() async {
    if (!_formKeyPf.currentState!.validate()) return;

    setState(() {
      isLoadingPf = true;
      resultadoPf = null;
    });

    try {
      final monto = double.tryParse(montoController.text) ?? 100000;
      final dias = int.tryParse(diasController.text) ?? 30;

      final data = await api.simulatePlazoFijo(monto: monto, dias: dias);

      setState(() {
        resultadoPf = data;
      });
    } catch (e) {
      setState(() {
        resultadoPf = {'error': 'Error al conectar con el servidor'};
      });
    } finally {
      setState(() => isLoadingPf = false);
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
                    _buildCrypto(theme, surface, textColor, primary),
                    _buildStock(theme, surface, textColor, primary),
                    _buildBond(theme, surface, textColor, primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _quoteCard({
  required String title,
  required double? price,
  required String? fuente,
  required DateTime? lastUpdate,
  required Color surface,
  required Color textColor,
}) {
  if (price == null) return const SizedBox.shrink();

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: surface.withOpacity(0.10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: textColor.withOpacity(0.12), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💱 Cotización actual — $title',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: textColor,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${price.toStringAsFixed(2)} USD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        if (fuente != null)
          Text(
            'Fuente: $fuente',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
        if (lastUpdate != null)
          Text(
            'Actualizado: ${DateFormat('dd/MM HH:mm').format(lastUpdate)}',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
          ),
      ],
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
                    onPressed: isLoadingPf ? null : simulateInvestment,
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
        if (isLoadingPf)
          const LoadingWidget(message: "Simulando inversión..."),
        if (!isLoadingPf && resultadoPf != null) ...[
          const SizedBox(height: 20),
          if (resultadoPf!['error'] != null)
            Text(
              resultadoPf!['error'],
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            )
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

  Widget _buildCrypto(ThemeData theme, Color surface, Color textColor, Color primary) {
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
              "esperando que su valor aumente con el tiempo.\n\n"
              "Estas inversiones son volátiles: pueden ofrecer altos rendimientos, "
              "pero también pérdidas importantes en poco tiempo.",
        ),
      ),
      const SizedBox(height: 25),

        // Card de cotización para cripto
    _quoteCard(
      title: coin.toUpperCase(),
      price: quoteCrypto,
      fuente: fuenteCrypto,
      lastUpdate: lastUpdateCrypto,
      surface: surface,
      textColor: textColor,
    ),


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
                  if (monto > 1000000) return 'Máximo USD 1.000.000';
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
                value: coin,
                decoration: InputDecoration(
                  labelText: 'Criptomoneda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'bitcoin', child: Text('Bitcoin (BTC)')),
                  DropdownMenuItem(value: 'ethereum', child: Text('Ethereum (ETH)')),
                  DropdownMenuItem(value: 'solana', child: Text('Solana (SOL)')),
                  DropdownMenuItem(value: 'dogecoin', child: Text('Dogecoin (DOGE)')),
                ],
                onChanged: (v) async {
                  setState(() => coin = v ?? 'bitcoin');
                  await _loadQuote('cripto', coin);
                },
              ),

              if (quoteCrypto != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cotización actual',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    Text('\$${quoteCrypto!.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (quoteFuente != null)
                  Text('Fuente: $quoteFuente',
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
              ],

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoadingCrypto ? null : () async {
                    if (!_formKeyCrypto.currentState!.validate()) return;
                    setState(() { isLoadingCrypto = true; resultadoCrypto = null; });
                    final monto = double.tryParse(montoCryptoController.text) ?? 1000;
                    final dias = int.tryParse(diasCryptoController.text) ?? 30;
                    await _loadQuote('cripto', coin);
                    final data = await api.simulateCrypto(monto: monto, coin: coin, dias: dias);
                    setState(() { resultadoCrypto = data; isLoadingCrypto = false; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Text(resultadoCrypto!['error'], style: const TextStyle(color: Colors.red))
        else
          SimulationResultCard(
            resultado: resultadoCrypto!,
            ultimaActualizacion: resultadoCrypto!['ultima_actualizacion']?.toString(),
          ),
      ],
    ],
  );
}


Widget _buildStock(ThemeData theme, Color surface, Color textColor, Color primary) {
  return ListView(
    physics: const BouncingScrollPhysics(),
    children: [
      const SizedBox(height: 10),
      Center(
        child: Text(
          "Simulá inversión en Acciones",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Center(
        child: InfoIcon(
          title: "¿Qué son las acciones?",
          message:
              "Las acciones representan una parte de la propiedad de una empresa. "
              "Invertir en ellas te permite beneficiarte de sus ganancias si su valor sube.\n\n"
              "Su precio puede variar día a día dependiendo del mercado, noticias, y desempeño de la empresa.",
        ),
      ),
      const SizedBox(height: 25),

_quoteCard(
  title: stock.toUpperCase(),
  price: quoteStock,
  fuente: fuenteStock,
  lastUpdate: lastUpdateStock,
  surface: surface,
  textColor: textColor,
),


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
          key: _formKeyStock,
          child: Column(
            children: [
              TextFormField(
                controller: montoStockController,
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
                  if (monto == null || monto < 100) return 'Mínimo USD 100';
                  if (monto > 1000000) return 'Máximo USD 1.000.000';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: diasStockController,
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: stock,
                decoration: InputDecoration(
                  labelText: 'Acción',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'AAPL', child: Text('Apple (AAPL)')),
                  DropdownMenuItem(value: 'TSLA', child: Text('Tesla (TSLA)')),
                  DropdownMenuItem(value: 'MSFT', child: Text('Microsoft (MSFT)')),
                  DropdownMenuItem(value: 'GOOGL', child: Text('Google (GOOGL)')),
                ],
                onChanged: (v) async {
                  setState(() => stock = v ?? 'AAPL');
                  await _loadQuote('accion', stock);
                },
              ),

              if (quoteStock != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cotización actual',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    Text('\$${quoteStock!.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (quoteFuente != null)
                  Text('Fuente: $quoteFuente',
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
              ],

              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoadingStock ? null : () async {
                    if (!_formKeyStock.currentState!.validate()) return;
                    setState(() { isLoadingStock = true; resultadoStock = null; });
                    final monto = double.tryParse(montoStockController.text) ?? 1000;
                    final dias = int.tryParse(diasStockController.text) ?? 30;
                    await _loadQuote('accion', stock);
                    final data = await api.simulateStock(monto: monto, symbol: stock, dias: dias);

                    setState(() { resultadoStock = data; isLoadingStock = false; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (isLoadingStock)
        const LoadingWidget(message: "Simulando acción..."),
      if (!isLoadingStock && resultadoStock != null) ...[
        const SizedBox(height: 20),
        if (resultadoStock!['error'] != null)
          Text(resultadoStock!['error'], style: const TextStyle(color: Colors.red))
        else
          SimulationResultCard(
            resultado: resultadoStock!,
            ultimaActualizacion: resultadoStock!['ultima_actualizacion']?.toString(),
          ),
      ],
    ],
  );
}

Widget _buildBond(ThemeData theme, Color surface, Color textColor, Color primary) {
  return ListView(
    physics: const BouncingScrollPhysics(),
    children: [
      const SizedBox(height: 10),
      Center(
        child: Text(
          "Simulá inversión en Bonos",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Center(
        child: InfoIcon(
          title: "¿Qué son los bonos?",
          message:
              "Los bonos son instrumentos de deuda emitidos por gobiernos o empresas. "
              "Cuando invertís en un bono, le estás prestando dinero al emisor a cambio de recibir intereses periódicos.\n\n"
              "Suelen ser inversiones más estables que las acciones, pero con menor rentabilidad esperada.",
        ),
      ),
      const SizedBox(height: 25),

  _quoteCard(
  title: bono.toUpperCase(),
  price: quoteBond,
  fuente: fuenteBond,
  lastUpdate: lastUpdateBond,
  surface: surface,
  textColor: textColor,
),


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
          key: _formKeyBond,
          child: Column(
            children: [
              TextFormField(
                controller: montoBondController,
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
                  if (monto == null || monto < 100) return 'Mínimo USD 100';
                  if (monto > 1000000) return 'Máximo USD 1.000.000';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: bono,
                decoration: InputDecoration(
                  labelText: 'Bono / ETF',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'TLT', child: Text('iShares 20+ Treasury (TLT)')),
                  DropdownMenuItem(value: 'BND', child: Text('Vanguard Total Bond (BND)')),
                  DropdownMenuItem(value: 'LQD', child: Text('iShares Corp Bond (LQD)')),
                  DropdownMenuItem(value: 'IEF', child: Text('iShares 7-10y Treasury (IEF)')),
                ],
                onChanged: (v) async {
                  setState(() => bono = v ?? 'TLT');
                  await _loadQuote('bono', bono);
                },
              ),

              if (quoteBond != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cotización actual',
                        style: TextStyle(color: textColor.withOpacity(0.8))),
                    Text('\$${quoteBond!.toStringAsFixed(2)} USD',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (quoteFuente != null)
                  Text('Fuente: $quoteFuente',
                      style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: diasBondController,
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
                  if (dias == null || dias < 7) return 'Mínimo 7 días';
                  if (dias > 730) return 'Máximo 730 días';
                  return null;
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoadingBond ? null : () async {
                    if (!_formKeyBond.currentState!.validate()) return;
                    setState(() { isLoadingBond = true; resultadoBond = null; });
                    final monto = double.tryParse(montoBondController.text) ?? 1000;
                    final dias = int.tryParse(diasBondController.text) ?? 30;
                    await _loadQuote('bono', bono);
                    final data = await api.simulateBond(monto: monto, bono: bono, dias: dias);

                    setState(() { resultadoBond = data; isLoadingBond = false; });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      if (isLoadingBond)
        const LoadingWidget(message: "Simulando bono..."),
      if (!isLoadingBond && resultadoBond != null) ...[
        const SizedBox(height: 20),
        if (resultadoBond!['error'] != null)
          Text(resultadoBond!['error'], style: const TextStyle(color: Colors.red))
        else
          SimulationResultCard(
            resultado: resultadoBond!,
            ultimaActualizacion: resultadoBond!['ultima_actualizacion']?.toString(),
          ),
      ],
    ],
  );
}


}
