import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'info_icon_widget.dart'; // 👈 asegúrate de tener este import correcto

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

class _SimulationResultCardState extends State<SimulationResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double porcentajeInteres;

  double _asDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }


  @override
  void initState() {
    super.initState();

    // ✅ cálculo unificado para todos los tipos
    final monto = (widget.resultado['monto_inicial'] ?? 0).toDouble();
    final montoFinal = (widget.resultado['monto_final_estimado'] ?? monto).toDouble();

    final interes = (montoFinal - monto).clamp(0, double.infinity);
    porcentajeInteres = monto > 0 ? (interes / monto) : 0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: porcentajeInteres)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDetails(Map<String, dynamic> r, Color textColor, Color primary) {
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    final tipo = r['tipo']?.toString();

    // 🔸 BLOQUE PLAZO FIJO (sin cambios)
    if (tipo == 'plazo_fijo') {
    final formatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    final double montoInicial = (r['monto_inicial'] ?? 0).toDouble();
    final double montoFinal   = (r['monto_final_estimado'] ?? 0).toDouble();
    final double interes      = (montoFinal - montoInicial).clamp(0, double.infinity);
    final double rendimiento  = (r['rendimiento_estimado_%'] ?? 0).toDouble();

    // 👇 Comparativa (se mantiene)
    final comp   = r['comparativa'] ?? {};
    final estado = comp['estado'] ?? 'neutral';

    String estadoTexto;
    Color estadoColor;
    IconData estadoIcon;

    if (estado == 'positivo') {
      estadoTexto = 'El plazo fijo le gana a la inflación';
      estadoColor = Colors.greenAccent.shade400;
      estadoIcon  = Icons.trending_up;
    } else if (estado == 'negativo') {
      estadoTexto = 'La inflación supera al plazo fijo';
      estadoColor = Colors.redAccent.shade200;
      estadoIcon  = Icons.trending_down;
    } else {
      estadoTexto = 'Plazo fijo e inflación están equilibrados';
      estadoColor = Colors.grey;
      estadoIcon  = Icons.drag_handle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLine('Monto invertido', formatter.format(montoInicial), textColor),
        _infoLine('Interés generado', formatter.format(interes), textColor),
        _infoLine('Monto total a recibir', formatter.format(montoFinal), textColor),
        _infoLine('Rendimiento estimado', '${rendimiento.toStringAsFixed(2)}%', textColor),

        const SizedBox(height: 10),
        _infoLine('TNA aplicada', '${r['tna']}%', textColor),
        _infoLine('Días de inversión', '${r['dias']}', textColor),

        const Divider(height: 25),
        Text(
          'Comparativa con inflación',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        _infoLine('TNA utilizada', '${r['tna']}%', textColor),
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
        Text(
          r['descripcion'] ?? '',
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        const SizedBox(height: 12),
        Text(
          'Fuente: ${r['fuente'] ?? 'BCRA'}',
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  //Cripto
  if (tipo == 'cripto') {
  final double montoInicialUsd = _asDouble(r['monto_inicial']);
  final double montoInicialArs = _asDouble(r['monto_inicial_ars']);
  final double montoFinalUsd   = _asDouble(r['monto_final_estimado_usd']);
  final double montoFinalArs   = _asDouble(r['monto_final_estimado_ars']);
  final double precioUsd       = _asDouble(r['precio_usd']);
  final double cantidad        = _asDouble(r['cantidad_comprada']);
  final double rendimiento     = _asDouble(r['rendimiento_estimado_%']);

  final extras = r['extras'] ?? {};
  final var24h = _asDouble(extras['change_percent']);        // 24h
  final var7d  = _asDouble(extras['change_percent_7d']);     // 7d
  final var30d = _asDouble(extras['change_percent_30d']);    // 30d

  final int dias = (r['dias'] is int)
      ? r['dias'] as int
      : int.tryParse('${r['dias'] ?? 0}') ?? 0;

  // 👉 Elegimos qué variación mostrar según días
  double variacionElegida;
  String variacionLabel;
  if (dias <= 2) {
    variacionElegida = var24h;
    variacionLabel = 'Variación 24h';
  } else if (dias <= 8) {
    variacionElegida = var7d;
    variacionLabel = 'Variación 7d';
  } else {
    variacionElegida = var30d;
    variacionLabel = 'Variación 30d';
  }

  final double gananciaUsd = (montoFinalUsd - montoInicialUsd);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Criptomoneda',
            style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15),
          ),
          const SizedBox(width: 6),
          const InfoIcon(
            title: '¿Qué es una criptomoneda?',
            message: 'Son activos digitales descentralizados cuyo precio cambia según oferta y demanda.',
          ),
        ],
      ),
      const SizedBox(height: 10),

      _infoLine('Activo', '${r['activo'] ?? 'N/D'}', textColor),
      _infoLine('Cotización actual', '\$${precioUsd.toStringAsFixed(2)} USD', textColor),
      _infoLine('Monto invertido', '\$${montoInicialUsd.toStringAsFixed(2)} USD (~\$${montoInicialArs.toStringAsFixed(0)} ARS)', textColor),
      _infoLine('Cantidad adquirida', '$cantidad ${r['activo'] ?? ''}', textColor),

      // 👉 Variación principal según días
      _infoLine(variacionLabel, '${variacionElegida.toStringAsFixed(2)}%', textColor),

      // 👉 “Todas las variaciones” en un desplegable opcional
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text('Ver variaciones 24h / 7d / 30d',
            style: TextStyle(color: textColor.withOpacity(0.85), fontWeight: FontWeight.w600)),
        children: [
          _infoLine('Variación 24h', '${var24h.toStringAsFixed(2)}%', textColor),
          _infoLine('Variación 7d',  '${var7d.toStringAsFixed(2)}%',  textColor),
          _infoLine('Variación 30d', '${var30d.toStringAsFixed(2)}%', textColor),
        ],
      ),

      // 👉 Ganancia debajo de variaciones (como pediste)
      _infoLine('Ganancia estimada',
          '\$${gananciaUsd.toStringAsFixed(2)} USD (~\$${(montoFinalArs - montoInicialArs).toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Monto estimado final',
          '\$${montoFinalUsd.toStringAsFixed(2)} USD (~\$${montoFinalArs.toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Rendimiento estimado', '${rendimiento.toStringAsFixed(2)}%', textColor),

      const SizedBox(height: 12),
      Text(r['descripcion'] ?? '', style: TextStyle(color: textColor.withOpacity(0.7))),
      const SizedBox(height: 8),
    ],
  );
}


  if (tipo == 'accion') {
  final double montoInicialUsd = _asDouble(r['monto_inicial']);
  final double montoInicialArs = _asDouble(r['monto_inicial_ars']);
  final double montoFinalUsd   = _asDouble(r['monto_final_estimado_usd']);
  final double montoFinalArs   = _asDouble(r['monto_final_estimado_ars']);
  final double precioUsd       = _asDouble(r['precio_usd']);
  final double cantidad        = _asDouble(r['cantidad_comprada']);
  final double rendimiento     = _asDouble(r['rendimiento_estimado_%']);

  final extras = r['extras'] ?? {};
  final varDiaria = _asDouble(extras['change_percent']);       // diaria
  final varYTD    = _asDouble(extras['percent_change_ytd']);   // YTD

  final double gananciaUsd = (montoFinalUsd - montoInicialUsd);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Acciones bursátiles',
            style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15),
          ),
          const SizedBox(width: 6),
          const InfoIcon(
            title: '¿Qué son las acciones?',
            message: 'Representan una parte de la propiedad de una empresa. Su precio refleja expectativas del mercado.',
          ),
        ],
      ),
      const SizedBox(height: 10),

      _infoLine('Acción', '${r['symbol'] ?? 'N/D'}', textColor),
      _infoLine('Cotización actual', '\$${precioUsd.toStringAsFixed(2)} USD', textColor),
      _infoLine('Monto invertido', '\$${montoInicialUsd.toStringAsFixed(2)} USD (~\$${montoInicialArs.toStringAsFixed(0)} ARS)', textColor),
      _infoLine('Cantidad adquirida', '$cantidad ${r['symbol'] ?? ''}', textColor),

      _infoLine('Variación diaria', '${varDiaria.toStringAsFixed(2)}%', textColor),
      _infoLine('Variación YTD',    '${varYTD.toStringAsFixed(2)}%',    textColor),

      _infoLine('Ganancia estimada',
          '\$${gananciaUsd.toStringAsFixed(2)} USD (~\$${(montoFinalArs - montoInicialArs).toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Monto estimado final',
          '\$${montoFinalUsd.toStringAsFixed(2)} USD (~\$${montoFinalArs.toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Rendimiento estimado', '${rendimiento.toStringAsFixed(2)}%', textColor),

      const SizedBox(height: 12),
      Text(r['descripcion'] ?? '', style: TextStyle(color: textColor.withOpacity(0.7))),
      const SizedBox(height: 8),
      Text('Fuente: ${r['fuente'] ?? 'TwelveData'}',
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12.5, fontStyle: FontStyle.italic)),
    ],
  );
}


  if (tipo == 'bono') {
  final double montoInicialUsd = _asDouble(r['monto_inicial']);
  final double montoInicialArs = _asDouble(r['monto_inicial_ars']);
  final double montoFinalUsd   = _asDouble(r['monto_final_estimado_usd']);
  final double montoFinalArs   = _asDouble(r['monto_final_estimado_ars']);
  final double precioUsd       = _asDouble(r['precio_usd']);
  final double cantidad        = _asDouble(r['cantidad_comprada']);
  final double rendimiento     = _asDouble(r['rendimiento_estimado_%']);

  final extras   = r['extras'] ?? {};
  final varDia   = _asDouble(extras['change_percent']);       // diaria
  final varYTD   = _asDouble(extras['percent_change_ytd']);   // YTD
  final divYield = _asDouble(extras['dividend_yield']);       // dividend

  final double gananciaUsd = (montoFinalUsd - montoInicialUsd);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(
            'Bonos / ETFs',
            style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 15),
          ),
          const SizedBox(width: 6),
          const InfoIcon(
            title: '¿Qué es un bono?',
            message: 'Es deuda emitida por gobiernos o empresas; el precio varía con tasas e inflaciones.',
          ),
        ],
      ),
      const SizedBox(height: 10),

      _infoLine('Bono', '${r['symbol'] ?? 'N/D'}', textColor),
      _infoLine('Cotización actual', '\$${precioUsd.toStringAsFixed(2)} USD', textColor),
      _infoLine('Monto invertido', '\$${montoInicialUsd.toStringAsFixed(2)} USD (~\$${montoInicialArs.toStringAsFixed(0)} ARS)', textColor),
      _infoLine('Cantidad adquirida', '$cantidad ${r['symbol'] ?? ''}', textColor),

      _infoLine('Variación diaria', '${varDia.toStringAsFixed(2)}%', textColor),
      _infoLine('Variación YTD',    '${varYTD.toStringAsFixed(2)}%',    textColor),
      _infoLine('Rendimiento por dividendo', '${divYield.toStringAsFixed(2)}%', textColor),

      _infoLine('Ganancia estimada',
          '\$${gananciaUsd.toStringAsFixed(2)} USD (~\$${(montoFinalArs - montoInicialArs).toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Monto estimado final',
          '\$${montoFinalUsd.toStringAsFixed(2)} USD (~\$${montoFinalArs.toStringAsFixed(0)} ARS)',
          textColor),

      _infoLine('Rendimiento estimado', '${rendimiento.toStringAsFixed(2)}%', textColor),

      const SizedBox(height: 12),
      Text(r['descripcion'] ?? '', style: TextStyle(color: textColor.withOpacity(0.7))),
      const SizedBox(height: 8),
      Text('Fuente: ${r['fuente'] ?? 'TwelveData'}',
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12.5, fontStyle: FontStyle.italic)),
    ],
  );
}

    // 🔹 BLOQUE PRÉSTAMO ADAPTADO CON INFOICON
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoLine('Monto solicitado', formatter.format(r['capital']), textColor),
        _infoLine('Cantidad de cuotas', '${r['cuotas']} cuotas', textColor),
        _infoLine('Tasa mensual', '${r['tasa_mensual']}%', textColor),
        _infoLine('Cuota mensual', formatter.format(r['cuota_mensual']), textColor),
        _infoLine('Total a pagar', formatter.format(r['total_a_pagar']), textColor),
        _infoLine('Intereses totales', formatter.format(r['intereses_totales']), textColor),
        _infoLine('CFT estimado', '${r['cft_estimado']}%', textColor),
        const Divider(height: 25),

        // 🧭 Tipo francés
        Row(
          children: [
            Text(
              'Tipo de préstamo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            InfoIcon(
              title: 'Préstamo tipo francés',
              message:
                  'En el sistema francés las cuotas son fijas durante todo el plazo. '
                  'Cada cuota incluye una parte de interés (que disminuye con el tiempo) '
                  'y una parte de capital (que aumenta mes a mes).',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 🧮 Fórmula de cálculo
        Row(
          children: [
            Text(
              'Fórmula utilizada',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            InfoIcon(
              title: 'Fórmula del sistema francés',
              message:
                  'La cuota (C) se calcula con la fórmula:\n\n'
                  'C = P × [i × (1 + i)^n] / [(1 + i)^n − 1]\n\n'
                  'Donde:\n'
                  '• C = cuota mensual\n'
                  '• P = capital solicitado\n'
                  '• i = tasa mensual\n'
                  '• n = cantidad de cuotas\n\n'
                  'Esta fórmula permite mantener cuotas iguales, '
                  'aunque la proporción entre interés y capital varía cada mes.',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 📘 Composición de las cuotas
        Row(
          children: [
            Text(
              'Cómo se componen las cuotas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primary,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            InfoIcon(
              title: 'Composición de las cuotas',
              message:
                  'Cada cuota se divide en dos partes:\n\n'
                  '• Una porción de interés, calculada sobre el saldo pendiente.\n'
                  '• Una porción de capital, que reduce la deuda.\n\n'
                  'Con el tiempo, los intereses bajan y el capital amortizado sube, '
                  'manteniendo el valor total de la cuota fijo.',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 🔽 Detalle de cuotas
        if (r['detalle_cuotas'] != null && r['detalle_cuotas'] is List) ...[
          const SizedBox(height: 15),
          ExpansionTile(
            title: Text(
              "Ver evolución mes a mes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
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
                      .map<DataRow>((c) => DataRow(
                            cells: [
                              DataCell(Text('${c['n']}')),
                              DataCell(Text(formatter.format(c['capital']))),
                              DataCell(Text(formatter.format(c['interes']))),
                              DataCell(Text(formatter.format(c['cuota']))),
                              DataCell(Text(formatter.format(c['saldo']))),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );

  }

  String _mensajeFinal(Map<String, dynamic> r) {
    final tipo = r['tipo']?.toString();
    if (tipo == 'plazo_fijo') {
      return 'Tu dinero creció con la tasa actual del BCRA.';
    }
    return widget.resultado['mensaje'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;



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
              Text(
                'Resultado de la simulación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
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
                        value: _animation.value,
                        strokeWidth: 10,
                        backgroundColor: primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_animation.value * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Interés',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              _buildDetails(widget.resultado, textColor, primary),

              const Divider(height: 25),
              Text(
                _mensajeFinal(widget.resultado),
                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                'Fuente: ${widget.resultado['fuente'] ?? 'BCRA'}',
                style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
              ),
              if (widget.ultimaActualizacion != null)
                Text(
                  'Actualizado: ${_formatDate(widget.ultimaActualizacion)}',
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                ),
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
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }


}
