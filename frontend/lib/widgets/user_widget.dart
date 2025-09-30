import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/currency.dart';

class UserWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserWidget({super.key, required this.user});

  String _formatSpanishDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    DateTime? dt;
    try {
      dt = DateTime.tryParse(raw);
      if (dt == null) {
        dt = DateTime.tryParse("${raw}T00:00:00");
      }
    } catch (_) {}
    if (dt == null) return '—';

    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${dt.day} de ${meses[dt.month - 1]} de ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final iconUrl = user['full_icon_url'] as String?;
    final name = user['name'] ?? 'Usuario';
    final email = user['email'] ?? '';
    final currencyId = user['currency_id'] as int? ?? 0; // <-- ahora es int
    final createdAt = _formatSpanishDate(user['created_at']);

    return Column(
      children: [
        // Foto grande arriba
        CircleAvatar(
          radius: 70,
          backgroundImage: (iconUrl != null && iconUrl.isNotEmpty)
              ? NetworkImage(iconUrl)
              : const AssetImage('assets/default_user.png') as ImageProvider,
        ),
        const SizedBox(height: 16),

        // Nombre
        Text(
          name,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Email con botón de copiar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: SelectableText(
                email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: "Copiar correo",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: email));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Correo copiado al portapapeles")),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Info extra en card apilada        
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("Miembro desde"),
                  subtitle: Text(createdAt),
                ),
                const Divider(),
                FutureBuilder<List<Currency>>(
                  future: ApiService().getCurrencies(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const ListTile(
                        leading: Icon(Icons.attach_money),
                        title: Text("Moneda base"),
                        subtitle: Text("Cargando..."),
                      );
                    }

                    final currencies = snapshot.data!;
                    final found = currencies.firstWhere(
                      (c) => c.id == currencyId, // <-- buscamos por id
                      orElse: () => Currency(
                        id: 0,
                        code: 'USD',
                        name: 'Desconocida',
                        symbol: '',
                      ),
                    );

                    return ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text("Moneda base"),
                      subtitle: Text('${found.symbol} ${found.code} - ${found.name}'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
