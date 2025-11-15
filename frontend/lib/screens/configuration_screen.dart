import 'package:flutter/material.dart';
import '../widgets/custom_scaffold.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/confirm_dialog_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../screens/user_form_screen.dart';
import 'login_screen.dart';
import '../models/currency.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final ApiService api = ApiService();
  late Future<Map<String, dynamic>?> userFuture;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    userFuture = api.getUser();
  }

  String _formatSpanishDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    DateTime? dt = DateTime.tryParse(raw) ?? DateTime.tryParse("${raw}T00:00:00");
    if (dt == null) return '—';

    const meses = [
      'enero','febrero','marzo','abril','mayo','junio',
      'julio','agosto','septiembre','octubre','noviembre','diciembre'
    ];

    return '${dt.day} de ${meses[dt.month - 1]} de ${dt.year}';
  }

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    final ok = await api.deleteUser();

    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

      showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: "Cuenta eliminada",
          message: "Tu cuenta fue dada de baja correctamente.",
        ),
      );
    } else {
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al eliminar la cuenta")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isDeleting) {
      return const Scaffold(
        body: LoadingWidget(message: "Eliminando cuenta..."),
      );
    }

    return CustomScaffold(
      title: 'Configuración',
      currentRoute: 'configuration',
      showNavigation: false,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: userFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const LoadingWidget(message: "Cargando...");
          }

          final user = snap.data!;
          final name = user['name'] ?? 'Usuario';
          final email = user['email'] ?? '—';
          final currencyId = user['currency_id'] ?? 0;
          final createdAt = _formatSpanishDate(user['created_at']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // TITULO “MI CUENTA”
                Text(
                  "Mi cuenta",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),

                // CARD PRINCIPAL ESTILO FINOVA (GLASS + BORDER + SHADOW)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        cs.surface.withOpacity(0.35),
                        cs.surface.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.35),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.20),
                        blurRadius: 22,
                        spreadRadius: 1,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow(Icons.person, "Nombre", name),
                      const SizedBox(height: 12),
                      _infoRow(Icons.email, "Correo electrónico", email),
                      const SizedBox(height: 12),

                      FutureBuilder<List<Currency>>(
                        future: ApiService().getCurrencies(),
                        builder: (context, currSnap) {
                          String text = "Cargando...";
                          if (currSnap.hasData) {
                            final currencies = currSnap.data!;
                            final found = currencies.firstWhere(
                              (c) => c.id == currencyId,
                              orElse: () => Currency(
                                id: 0, code: "USD", name: "Desconocida", symbol: "\$",
                              ),
                            );
                            text = "${found.symbol} ${found.code} — ${found.name}";
                          }

                          return _infoRow(Icons.attach_money, "Moneda base", text);
                        },
                      ),

                      const SizedBox(height: 12),
                      _infoRow(Icons.calendar_today, "Miembro desde", createdAt),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // TITULO ACCIONES
                Text(
                  "Acciones",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // BOTÓN EDITAR PERFIL
                _actionTile(
                  icon: Icons.edit,
                  text: "Editar usuario",
                  color: cs.primary,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserFormScreen(user: user),
                      ),
                    );

                    if (result != null) {
                      final ok = await api.updateUser(
                        name: result['name'],
                        email: result['email'],
                        password: result['password'],
                        passwordConfirmation: result['password_confirmation'],
                        currencyBase: result['currencyBase'],
                        balance: result['balance'],
                        icon: result['icon'],
                      );

                      if (ok != null) setState(() => userFuture = api.getUser());
                    }
                  },
                ),

                const SizedBox(height: 14),

                // BOTÓN CERRAR SESIÓN
                _actionTile(
                  icon: Icons.logout,
                  text: "Cerrar sesión",
                  color: Colors.orange,
                  onTap: () {
                    api.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),

                const SizedBox(height: 14),

                // BOTÓN DAR DE BAJA
                _actionTile(
                  icon: Icons.delete_forever,
                  text: "Dar de baja cuenta",
                  color: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmDialogWidget(
                        title: "Dar de baja cuenta",
                        message:
                            "¿Seguro que querés eliminar tu cuenta? Podrás reactivarla más adelante.",
                        confirmText: "Eliminar",
                        cancelText: "Cancelar",
                        confirmColor: Colors.red,
                      ),
                    );

                    if (confirm == true) _deleteAccount();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------- UI COMPONENTES --------------------------

  Widget _infoRow(IconData icon, String title, String value) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: cs.primary, size: 24),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withOpacity(0.9),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.15),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
