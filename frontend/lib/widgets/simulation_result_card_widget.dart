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

  @override
  void initState() {
    super.initState();

    final tipo = widget.resultado['tipo']?.toString();
    double monto = 0;
    double montoFinal = 0;

    if (tipo == 'plazo_fijo') {
      monto = (widget.resultado['monto'] ?? 0).toDouble();
      montoFinal = (widget.resultado['monto_final'] ?? monto).toDouble();
    } else {
      monto = (widget.resultado['capital'] ?? 0).toDouble();
      montoFinal = (widget.resultado['total_a_pagar'] ?? monto).toDouble();
    }

    final interes = (montoFinal - monto).clamp(0, double.infinity).toDouble();
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

      final double monto = (r['monto'] ?? 0).toDouble();
      final double montoFinal = (r['monto_final'] ?? 0).toDouble();
      final double interes = (montoFinal - monto).clamp(0, double.infinity);
      final double porcentaje = monto > 0 ? (interes / monto) * 100 : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoLine('Monto invertido', formatter.format(monto), textColor),
          _infoLine('Interés generado', formatter.format(interes), textColor),
          _infoLine('Monto total a recibir', formatter.format(montoFinal), textColor),
          _infoLine('Porcentaje de intereses', '${porcentaje.toStringAsFixed(2)}%', textColor),
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
            'Los valores son estimativos, calculados con la TNA promedio del BCRA.',
            style: TextStyle(
              color: textColor.withOpacity(0.6),
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              )),
          Text(value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              )),
        ],
      ),
    );
  }
}
