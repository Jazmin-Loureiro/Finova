import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'info_icon_widget.dart';

class SimulationResultCard extends StatefulWidget {
  final Map<String, dynamic> resultado;
  final String? ultimaActualizacion;

  const SimulationResultCard({
    super.key,
    required this.resultado,
    this.ultimaActualizacion,
  });

  @override
  State<SimulationResultCard> createState() => _SimulationResultCardState();
}

String _formatDate(dynamic dateInput) {
  try {
    if (dateInput == null) return 'N/D';
    final date = dateInput is String
        ? DateTime.parse(dateInput).toLocal()
        : (dateInput as DateTime).toLocal();
    final formatter = DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'es_ES');
    return formatter.format(date);
  } catch (_) {
    return dateInput.toString();
  }
}

const Map<String, String> _symbolByCode = {
  'USD': r'$',
  'ARS': r'$',
  'EUR': '€',
  'BRL': r'R$',
  'CLP': r'$',
  'COP': r'$',
  'MXN': r'$',
};

String _fmt(double value, String code) {
  final symbol = _symbolByCode[code.toUpperCase()] ?? r'$';
  final absValue = value.abs();
  final formatted = NumberFormat.currency(
    locale: 'en_US', // siempre símbolo antes del número
    symbol: symbol,
    decimalDigits: 2,
  ).format(absValue);

  if (value < 0) {
    // Colocamos el signo después del símbolo (ej: $-100.00)
    return '$symbol-${NumberFormat("#,##0.00", "en_US").format(absValue)}';
  }

  return formatted;
}


double _asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

class _SimulationResultCardState extends State<SimulationResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double porcentajeInteres; // puede ser negativo

  @override
  void initState() {
    super.initState();

    final r = widget.resultado;
    double monto = 0;
    double montoFinal = 0;

    switch (r['tipo']) {
      case 'plazo_fijo':
        monto = _asDouble(r['monto_inicial']);
        montoFinal = _asDouble(r['monto_final_estimado']);
        break;
      case 'cripto':
        // Gauge en USD para consistencia
        monto = _asDouble(r['monto_inicial']);
        montoFinal = _asDouble(r['monto_final_estimado_usd']);
        break;
      case 'prestamo':
      default:
        monto = _asDouble(r['capital']);
        montoFinal = _asDouble(r['total_a_pagar']);
        break;
    }

    final interes = (montoFinal - monto); // puede ser negativo
    porcentajeInteres = (monto > 0) ? (interes / monto) : 0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // el gauge solo acepta [0..1]; si es pérdida, lo dejamos en 0 pero mostramos el % en rojo
    _animation = Tween<double>(begin: 0, end: porcentajeInteres.clamp(0, 1))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDetails(Map<String, dynamic> r, Color textColor, Color primary) {
    final tipo = r['tipo']?.toString();

    // -------------------- PLAZO FIJO --------------------
    if (tipo == 'plazo_fijo') {
      final double montoInicial = _asDouble(r['monto_inicial']);
      final double montoFinal = _asDouble(r['monto_final_estimado']);
      final double interes = (montoFinal - montoInicial).clamp(0, double.infinity);
      final double rendimiento = _asDouble(r['rendimiento_estimado_%']);

      // Usamos ARS para PF (fuente BCRA); si querés hacerlo base-usuario también, pasame esos campos desde el backend.
      final formatterARS = (double v) => _fmt(v, 'ARS');

      final comp = r['comparativa'] ?? {};
      final estado = comp['estado'] ?? 'neutral';

      String estadoTexto;
      Color estadoColor;
      IconData estadoIcon;

      if (estado == 'positivo') {
        estadoTexto = 'El plazo fijo le gana a la inflación';
        estadoColor = Colors.greenAccent.shade400;
        estadoIcon = Icons.trending_up;
      } else if (estado == 'negativo') {
        estadoTexto = 'La inflación supera al plazo fijo';
        estadoColor = Colors.redAccent.shade200;
        estadoIcon = Icons.trending_down;
      } else {
        estadoTexto = 'Plazo fijo e inflación están equilibrados';
        estadoColor = Colors.grey;
        estadoIcon = Icons.drag_handle;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine('Monto invertido', formatterARS(montoInicial), textColor),
          _infoLine('Interés generado', formatterARS(interes), textColor),
          _infoLine('Monto total a recibir', formatterARS(montoFinal), textColor),
          _infoLine('Rendimiento estimado', '${rendimiento.toStringAsFixed(2)}%', textColor),
          const SizedBox(height: 10),
          _infoLine('TNA aplicada', '${r['tna']}%', textColor),
          _infoLine('Días de inversión', '${r['dias']}', textColor),
          const Divider(height: 25),
          Text('Comparativa con inflación',
              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _infoLine('Inflación mensual', '${comp['inflacion'] ?? 'N/D'}%', textColor),
          _infoLine('Diferencia', '${comp['resultado'] ?? 'N/D'}%', textColor),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estadoTexto,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 25),
          Text(r['descripcion'] ?? '', style: TextStyle(color: textColor.withOpacity(0.7))),
          const SizedBox(height: 12),
        ],
      );
    }

    // -------------------- CRIPTO --------------------
    if (tipo == 'cripto') {
      // USD SIEMPRE presente (compra cripto en USD).
      final double montoInicialUsd = _asDouble(r['monto_inicial']);
      final double montoFinalUsd   = _asDouble(r['monto_final_estimado_usd']);
      final double precioUsd       = _asDouble(r['precio_usd']);
      final double cantidad        = _asDouble(r['cantidad_comprada']);

      // Moneda base del usuario
      final String baseCode = (r['moneda_base'] ?? 'ARS').toString().toUpperCase();
      final double montoInicialBase = _asDouble(r['monto_inicial_base']);
      final double montoFinalBase   = _asDouble(r['monto_final_estimado_base']);

      final double variacion = _asDouble(r['variacion_%']);            // del periodo_base
      final double rendimiento = _asDouble(r['rendimiento_estimado_%']); // ajustado a días
      final String periodo = (r['periodo_base'] ?? '30d').toString();

      final double gananciaUsd  = montoFinalUsd - montoInicialUsd;
      final double gananciaBase = montoFinalBase - montoInicialBase;
      final bool gananciaPositiva = gananciaUsd >= 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Criptomoneda',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15)),
              const SizedBox(width: 6),
              const InfoIcon(
                title: '¿Qué es una criptomoneda?',
                message:
                    'Son activos digitales descentralizados cuyo precio varía según la oferta y la demanda.',
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoLine('Activo', '${r['activo'] ?? 'N/D'}', textColor),
          _infoLine('Cotización actual', _fmt(precioUsd, 'USD'), textColor),
          Row(
            children: [
              Expanded(
                child: _infoLine(
                  'Monto invertido',
                  '${_fmt(montoInicialUsd, "USD")} (${_fmt(montoInicialBase, baseCode)})',
                  textColor,
                ),
              ),
              const InfoIcon(
                title: 'Monto invertido',
                message:
                    'Las criptomonedas cotizan globalmente en dólares (USD). '
                    'El valor entre paréntesis muestra el equivalente en tu moneda local según la cotización actual.',
              ),
            ],
          ),
          _infoLine('Cantidad adquirida', '$cantidad ${r['activo'] ?? ''}', textColor),
          Row(
            children: [
              Expanded(
                child: _infoLine(
                  'Variación base ($periodo)',
                  '${variacion.toStringAsFixed(2)}%',
                  textColor,
                ),
              ),
              const InfoIcon(
                title: 'Variación base',
                message:
                    'Representa el cambio porcentual real de la criptomoneda en el período base (24h, 7d o 30d) '
                    'según CoinGecko. Este valor es la referencia para calcular el rendimiento estimado.',
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _infoLine(
                  'Rendimiento estimado (${r['dias']} días)',
                  '${rendimiento.toStringAsFixed(2)}%',
                  rendimiento >= 0
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent.shade200,
                ),
              ),
              const InfoIcon(
                title: '¿Cómo se calcula el rendimiento?',
                message:
                    'El rendimiento se estima usando la variación porcentual del activo (24h, 7d o 30d) '
                    'ajustada proporcionalmente a los días simulados. Si es positivo, ganás; si es negativo, perdés valor.',
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoLine(
                  'Ganancia estimada',
                  '${_fmt(gananciaUsd, "USD")} (${_fmt(gananciaBase, baseCode)})',
                  gananciaPositiva
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent.shade200,
                ),
              ),
              const InfoIcon(
                title: 'Ganancia estimada',
                message:
                    'Este valor refleja cuánto ganarías o perderías si el precio del activo variara según el período elegido. '
                    'Es una estimación basada en datos recientes del mercado y puede cambiar con la volatilidad.',
              ),
            ],
          ),
          _infoLine(
            'Monto estimado final',
            '${_fmt(montoFinalUsd, "USD")} (${_fmt(montoFinalBase, baseCode)})',
            textColor,
          ),
          const SizedBox(height: 12),
          Text(r['descripcion'] ?? '', style: TextStyle(color: textColor.withOpacity(0.7))),
          const SizedBox(height: 8),
        ],
      );
    }

    // -------------------- PRÉSTAMO --------------------
    final formatterARS = (double v) => _fmt(v, 'ARS');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLine('Monto solicitado', formatterARS(_asDouble(r['capital'])), textColor),
        _infoLine('Cantidad de cuotas', '${r['cuotas']} cuotas', textColor),
        _infoLine('Tasa mensual', '${r['tasa_mensual']}%', textColor),
        _infoLine('Cuota mensual', formatterARS(_asDouble(r['cuota_mensual'])), textColor),
        _infoLine('Total a pagar', formatterARS(_asDouble(r['total_a_pagar'])), textColor),
        _infoLine('Intereses totales', formatterARS(_asDouble(r['intereses_totales'])), textColor),
        _infoLine('CFT estimado', '${r['cft_estimado']}%', textColor),
        const Divider(height: 25),
        Row(
          children: [
            Text('Tipo de préstamo',
                style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15)),
            const SizedBox(width: 6),
            const InfoIcon(
              title: 'Préstamo tipo francés',
              message:
                  'Cuotas fijas; cada cuota combina interés y capital con proporción variable en el tiempo.',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (r['detalle_cuotas'] != null && r['detalle_cuotas'] is List) ...[
          const SizedBox(height: 15),
          ExpansionTile(
            title: Text("Ver evolución mes a mes",
                style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Capital')),
                    DataColumn(label: Text('Interés')),
                    DataColumn(label: Text('Cuota')),
                    DataColumn(label: Text('Saldo')),
                  ],
                  rows: (r['detalle_cuotas'] as List)
                      .map<DataRow>((c) => DataRow(cells: [
                            DataCell(Text('${c['n']}')),
                            DataCell(Text(formatterARS(_asDouble(c['capital'])))),
                            DataCell(Text(formatterARS(_asDouble(c['interes'])))),
                            DataCell(Text(formatterARS(_asDouble(c['cuota'])))),
                            DataCell(Text(formatterARS(_asDouble(c['saldo'])))),
                          ]))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;

    // Elegimos el % a mostrar (si es crypto o PF, usamos rendimiento; si es préstamo, usamos interes/monto)
    double pctLabel = porcentajeInteres * 100;
    final isLoss = pctLabel < 0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primary.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Resultado de la simulación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const InfoIcon(
                    title: 'Qué significa esta simulación',
                    message:
                        'El resultado muestra cómo evolucionaría tu inversión según datos reales del mercado. '
                        'Los valores pueden ser positivos (ganancia) o negativos (pérdida) dependiendo del comportamiento del activo.',
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: _animation.value, // [0..1] (si pérdida, 0)
                        strokeWidth: 10,
                        backgroundColor: primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${pctLabel.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isLoss ? Colors.redAccent.shade200 : textColor,
                          ),
                        ),
                        Text(isLoss ? 'Pérdida' : 'Interés',
                            style: TextStyle(
                                fontSize: 14, color: textColor.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildDetails(widget.resultado, textColor, primary),
              const Divider(height: 25),
              Text('Fuente: ${widget.resultado['fuente'] ?? 'BCRA'}',
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
              if (widget.ultimaActualizacion != null)
                Text('Actualizado: ${_formatDate(widget.ultimaActualizacion)}',
                    style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6))),
            ],
          ),
        );
      },
    );
  }

  Widget _infoLine(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
