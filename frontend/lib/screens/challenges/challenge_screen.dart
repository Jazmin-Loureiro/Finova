import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_scaffold.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/dialogs/success_dialog_widget.dart';
import '../../widgets/dialogs/confirm_dialog_widget.dart';
import '../../../main.dart'; // 👈 para usar routeObserver
import '../../widgets/custom_refresh_wrapper.dart';
import '../../helpers/format_utils.dart';



// 🔹 Nuevos imports modularizados
import '../../widgets/empty_state_widget.dart';
import '../../widgets/challenge_card_widget.dart';
import '../../widgets/meta_chips_widget.dart';
import '../../helpers/challenge_utils.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
    final ApiService api = ApiService();
    late TabController _tabController;

    late Future<Map<String, dynamic>> _availableFuture;
    late Future<Map<String, dynamic>> _profileFuture;

    DateTime? _cooldownUntil;
    static const _cooldownHours = 12;
    bool _hideLocked = false;

    // ✅ Este initState se había perdido
    @override
    void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _loadData();
    }

    // ✅ Este método también se había perdido
    void _loadData() {
      _availableFuture = api.getAvailableChallenges();
      _profileFuture = api.getGamificationProfile();
      _primeCooldownFromUser();
    }

    // ✅ Esto es lo que agregamos para el refresco automático al volver
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    }

    @override
    void didPopNext() {
      super.didPopNext();
      // 👇 cuando volvés desde el perfil, refresca los datos
      _loadData();
    }

    @override
    void dispose() {
      routeObserver.unsubscribe(this);
      super.dispose();
    }

  Future<void> _primeCooldownFromUser() async {
    try {
      final user = await api.getUser();
      _setCooldownFromUser(user);
    } catch (_) {}
  }

  void _setCooldownFromUser(Map<String, dynamic>? user) {
    if (user == null) return;
    final last = user['last_challenge_refresh'];
    if (last is String && last.isNotEmpty) {
      final lastDt = DateTime.tryParse(last)?.toLocal();
      if (lastDt != null) {
        setState(() {
          _cooldownUntil = lastDt.add(const Duration(hours: _cooldownHours));
        });
      }
    }
  }

  void _setCooldownFromServerMeta(Map<String, dynamic> meta) {
    final next = meta['next_refresh_at'];
    if (next is String && next.isNotEmpty) {
      final nextDt = DateTime.tryParse(next)?.toLocal();
      if (nextDt != null) {
        setState(() {
          _cooldownUntil = nextDt;
        });
      }
    }
  }

  Future<void> _refreshTab(int index) async {
    setState(() {
      if (index == 0) {
        _availableFuture = api.getAvailableChallenges();
      } else {
        _profileFuture = api.getGamificationProfile();
      }
    });
    await _primeCooldownFromUser();
  }

  Future<void> _acceptChallenge(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialogWidget(
        title: "Aceptar desafío",
        message: "¿Querés aceptar el desafío '$name'?",
        confirmColor: Theme.of(context).colorScheme.primary,
      ),
    );

    if (confirmed != true) return;

    final ok = await api.acceptChallenge(id);
    if (!mounted) return;

    if (ok) {
      showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: "Desafío aceptado",
          message: "¡El desafío fue agregado a tu progreso!",
        ),
      );
      setState(() {
        _profileFuture = api.getGamificationProfile();
        _availableFuture = api.getAvailableChallenges();
      });
      await _primeCooldownFromUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al aceptar el desafío')),
      );
    }
  }

  Future<void> _refreshChallengesManually() async {
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      final formatted = TimeOfDay.fromDateTime(_cooldownUntil!).format(context);
      await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: "Esperá un poco",
          message: "Podés regenerar desafíos nuevamente a las $formatted hs.",
          isFailure: true,
        ),
      );
      return;
    }

    await _primeCooldownFromUser();
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      final formatted = TimeOfDay.fromDateTime(_cooldownUntil!).format(context);
      await showDialog(
        context: context,
        builder: (_) => SuccessDialogWidget(
          title: "Esperá un poco",
          message: "Podés regenerar desafíos nuevamente a las $formatted hs.",
          isFailure: true,
        ),
      );
      return;
    }

    try {
      final res = await api.refreshChallenges();
      if (!mounted) return;

      _setCooldownFromServerMeta(res);
      _cooldownUntil ??= DateTime.now().add(const Duration(hours: _cooldownHours));

      setState(() {
        _availableFuture = Future.value(res);
        _profileFuture = api.getGamificationProfile();
      });

      showDialog(
        context: context,
        builder: (_) => const SuccessDialogWidget(
          title: "Actualizados",
          message: "¡Nuevos desafíos disponibles!",
        ),
      );
    } catch (e) {
      if (e is CooldownException && e.status == 429) {
        if (e.nextRefreshAt != null) {
          final dt = DateTime.tryParse(e.nextRefreshAt!)?.toLocal();
          if (dt != null) _cooldownUntil = dt;
        }

        final until = _cooldownUntil ?? DateTime.now().add(const Duration(hours: _cooldownHours));
        final formatted = TimeOfDay.fromDateTime(until).format(context);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => SuccessDialogWidget(
            title: "Esperá un poco ⏳",
            message: "Podés regenerar desafíos nuevamente a las $formatted hs.",
            isFailure: true,
          ),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al regenerar desafíos.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CustomScaffold(
      title: 'Desafíos',
      currentRoute: 'challenge',
      showNavigation: false,
    
      body: Column(
        children: [
         // 🔹 Tabs (respetando theme)
          Container(
            color: cs.surfaceContainerHighest.withOpacity(0.2),
            child: TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurface.withOpacity(0.7),
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: 'Disponibles'),
                Tab(text: 'Mis desafíos'),
              ],
            ),
          ),

          // 🔹 Contenido
          Expanded(
            child: TabBarView(
              key: const PageStorageKey('challengeTabs'),
              controller: _tabController,
              children: [
                _buildAvailableTab(),
                _buildUserChallengesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔸 Toggle de ocultar bloqueados (igual)
  Widget _hideLockedToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Text("Ocultar bloqueados", style: TextStyle(fontSize: 13)),
        ),
        Switch(
          value: _hideLocked,
          onChanged: (v) => setState(() => _hideLocked = v),
        ),
      ],
    );
  }

  int _compareChallenges(Map<String, dynamic> a, Map<String, dynamic> b) {
    final bool aLocked = a['locked'] == true;
    final bool bLocked = b['locked'] == true;
    if (aLocked != bLocked) return aLocked ? 1 : -1;
    final int aPts = (a['reward_points'] as num?)?.toInt() ?? 0;
    final int bPts = (b['reward_points'] as num?)?.toInt() ?? 0;
    if (aPts != bPts) return bPts.compareTo(aPts);
    final int aDur = (a['duration_days'] as num?)?.toInt() ?? 9999;
    final int bDur = (b['duration_days'] as num?)?.toInt() ?? 9999;
    if (aDur != bDur) return aDur.compareTo(bDur);
    final String aName = (a['name'] as String?) ?? '';
    final String bName = (b['name'] as String?) ?? '';
    return aName.toLowerCase().compareTo(bName.toLowerCase());
  }

  // 🔎 Texto explicativo numérico (como tenías antes)
  String _buildChallengeHint(Map<String, dynamic> ch) {
  final type = (ch['type'] ?? '') as String;
  final payload = ChallengeUtils.decodePayload(ch['payload']);
  final target = ch['target_amount'];

  // Moneda
  final code = payload['currency_code'] ?? ch['currency_code'] ?? 'ARS';
  final symbol = payload['currency_symbol'] ?? ch['currency_symbol'] ?? '\$';

  // -------- CASE 1: SAVE_AMOUNT ----------
  if (type == 'SAVE_AMOUNT') {
    final num? amount =
        (target is num) ? target : (payload['amount'] as num?);

    if (amount == null) return 'Ahorrá un monto personalizado';

    final formatted = formatCurrency(
      amount.toDouble(),
      code,
      symbolOverride: symbol,
    );

    return 'Ahorrá $formatted';
  }

  // -------- CASE 2: REDUCE_SPENDING_PERCENT ----------
  if (type == 'REDUCE_SPENDING_PERCENT') {
    final int windowDays =
        (payload['window_days'] as num?)?.toInt() ?? 30;

    num? maxAllowed;
    if (payload['max_allowed'] is num) {
      maxAllowed = payload['max_allowed'];
    } else if (payload['max_allowed'] is String) {
      maxAllowed = num.tryParse(payload['max_allowed']);
    }

    if (maxAllowed != null) {
      final formatted = formatCurrency(
        maxAllowed.toDouble(),
        code,
        symbolOverride: symbol,
      );

      return 'No superes $formatted en gastos.\nSe evaluará durante $windowDays días.';
    }

    return 'Se evaluará durante $windowDays días.';
  }

  // -------- CASE 3: ADD_TRANSACTIONS ----------
  if (type == 'ADD_TRANSACTIONS') {
    final int? count = (payload['count'] as num?)?.toInt() ??
        (target is num ? target.toInt() : null);

    if (count != null) {
      return 'Registrá $count movimientos';
    }

    return 'Registrá tus movimientos esta semana';
  }

  // -------- DEFAULT ----------
  return (ch['description'] as String?) ?? '';
}

  // 🔹 TAB 1: Disponibles — Card táctil + hint numérico + cartel + switch (todo restaurado)
  Widget _buildAvailableTab() {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: _availableFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Cargando desafíos...");
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        final data = snapshot.data ?? {};
        WidgetsBinding.instance.addPostFrameCallback((_) => _setCooldownFromServerMeta(data));

        final List<dynamic> rawList = (data['available_challenges'] as List?) ?? const [];
        final List<dynamic> filtered = _hideLocked
            ? rawList.where((c) => !(c['locked'] == true)).toList()
            : rawList;

        // sort (igual)
        final List<Map<String, dynamic>> sorted =
            filtered.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        sorted.sort(_compareChallenges);

        // Lista principal (con INFO + cards táctiles)
        Widget list = CustomRefreshWrapper(
          onRefresh: _refreshChallengesManually,
          child: sorted.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    EmptyStateWidget(
                      title: "¡No hay desafíos disponibles!",
                      message:
                          "Parece que completaste todos los desafíos por ahora.\nPodés intentar regenerarlos",
                      icon: Icons.emoji_events_outlined,
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final ch = sorted[index];

                    // 🟣 Mensajes informativos del backend (type: INFO) — se mantiene
                    if ((ch['type'] ?? '') == 'INFO') {
                      return Card(
                        color: cs.surfaceContainerHighest.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: cs.primary, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  ch['message'] ?? 'Mensaje informativo',
                                  style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.9),
                                    fontSize: 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final bool locked = ch['locked'] == true;
                    final String lockedReason = (ch['locked_reason'] as String?) ??
                        'Ya tenés un desafío de este tipo en progreso. Completalo para aceptar uno nuevo.';

                    final String hint = _buildChallengeHint(ch);

                    final card = Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: cs.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: cs.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 Título + candado
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ch['name'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                if (locked)
                                  Tooltip(
                                    message: lockedReason,
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // 🔹 Descripción (si existe)
                            if ((ch['description'] as String?)?.isNotEmpty == true)
                              Text(
                                ch['description'],
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),

                            // 🔹 Hint numérico (restaurado)
                            if (hint.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                hint,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // 🔹 Chips de meta/duración/puntos (tu widget)
                            MetaChipsWidget(challenge: ch),

                            // 🔹 Mensaje de bloqueado (si aplica)
                            if (locked) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lockedReason,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withOpacity(0.85),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );

                    // 🔹 Card táctil (abre confirm) + opacidad si está bloqueado
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: locked ? 0.55 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: locked ? null : () => _acceptChallenge(ch['id'], ch['name']),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 Título + candado
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ch['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (locked)
                                      Tooltip(
                                        message: lockedReason,
                                        child: Icon(
                                          Icons.lock_outline,
                                          size: 20,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // 🔹 Descripción (si existe)
                                if ((ch['description'] as String?)?.isNotEmpty == true)
                                  Text(
                                    ch['description'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),

                                // 🔹 Hint numérico
                                if (hint.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    hint,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // 🔹 Chips
                                MetaChipsWidget(challenge: ch),

                                // 🔹 Mensaje bloqueado (si aplica)
                                if (locked) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 16, color: cs.onSurfaceVariant),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          lockedReason,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: cs.onSurface.withOpacity(0.80),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );

                  },
                ),
        );

        // 🔹 Cartel de "podés regenerar a las ..." + switch de ocultar (restaurado)
        final next = data['next_refresh_at'];
        if (next is String && next.isNotEmpty) {
          final dt = DateTime.tryParse(next)?.toLocal();
          if (dt != null) {
            final formatted = TimeOfDay.fromDateTime(dt).format(context);

            list = Column(
              children: [
                // 🟣 Cartel de regenerar desafíos
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: cs.surfaceContainerHighest.withOpacity(0.2),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Podés regenerar desafíos a las $formatted hs.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                // 🟢 Switch ocultar bloqueados
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: _hideLockedToggle(),
                ),
                // 🟢 Lista
                Expanded(child: list),
              ],
            );
          }
        } else {
          // Cuando no hay cartel, mostrar solo switch + lista (como tenías)
          list = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: _hideLockedToggle(),
              ),
              Expanded(child: list),
            ],
          );
        }

        return list;
      },
    );
  }

  // 🔹 TAB 2: Mis desafíos (no se toca la lógica)
  Widget _buildUserChallengesTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Cargando tus desafíos...");
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red)),
          );
        }

        final data = snapshot.data ?? {};
        final challenges = data['challenges'] ?? {};
        final inProgress = (challenges['in_progress'] as List?) ?? [];
        final completed = (challenges['completed'] as List?) ?? [];
        final failed = (challenges['failed'] as List?) ?? [];

        final allEmpty =
            inProgress.isEmpty && completed.isEmpty && failed.isEmpty;

        if (allEmpty) {
          return EmptyStateWidget(
            title: "Aún no aceptaste ningún desafío",
            message:
                "Podés aceptar uno desde la pestaña 'Disponibles' para empezar a ganar puntos y recompensas 🏅",
            icon: Icons.assignment_turned_in_outlined,
   
          );
        }

        return CustomRefreshWrapper(
          onRefresh: () async => _refreshTab(_tabController.index),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (inProgress.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("En progreso",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...inProgress
                    .map((ch) => ChallengeCardWidget(challenge: ch))
                    .toList(),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("Completados",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...completed
                    .map((ch) =>
                        ChallengeCardWidget(challenge: ch, completed: true))
                    .toList(),
                const SizedBox(height: 16),
              ],
              if (failed.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("Fallidos",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white)),
                ),
                ...failed
                    .map((ch) => ChallengeCardWidget(challenge: ch))
                    .toList(),
              ],
            ],
          ),
        );
      },
    );
  }
}
