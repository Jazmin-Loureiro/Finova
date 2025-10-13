import 'dart:convert'; // 👈 agregado para jsonDecode
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/loading_widget.dart';
import '../widgets/success_dialog_widget.dart';
import '../widgets/confirm_dialog_widget.dart';


class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});
  
  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  late TabController _tabController;

  late Future<Map<String, dynamic>> _availableFuture;
  late Future<Map<String, dynamic>> _profileFuture;


  DateTime? _cooldownUntil;
  static const _cooldownHours = 12;
  bool _hideLocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    _availableFuture = api.getAvailableChallenges();
    _profileFuture = api.getGamificationProfile();
    _primeCooldownFromUser();
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
      final lastDt = DateTime.tryParse(last);
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
      final nextDt = DateTime.tryParse(next);
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
          title: "Esperá un poco ⏳",
          message: "Podés regenerar desafíos nuevamente a las $formatted hs.",
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
          title: "Esperá un poco ⏳",
          message: "Podés regenerar desafíos nuevamente a las $formatted hs.",
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
          final dt = DateTime.tryParse(e.nextRefreshAt!);
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
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 12);
              }
              final profile = snap.data ?? {};
              final user = profile['user'] ?? {};
              final level = user['level'] ?? 0;
              final points = user['points'] ?? 0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _pill(context,
                        icon: Icons.stars, label: 'Nivel', value: '$level'),
                    const SizedBox(width: 8),
                    _pill(context,
                        icon: Icons.military_tech,
                        label: 'Puntos',
                        value: '$points'),
                  ],
                ),
              );
            },
          ),
          Container(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
            child: TabBar(
              controller: _tabController,
              labelColor: cs.primary,
              unselectedLabelColor: Colors.white70,
              indicatorColor: cs.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              tabs: const [
                Tab(text: 'Disponibles'),
                Tab(text: 'Mis desafíos'),
              ],
            ),
          ),
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

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

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

  Map<String, dynamic> _decodePayload(dynamic raw) {
    if (raw == null) return const {};
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }

  String _buildChallengeHint(Map<String, dynamic> ch) {
  final type = (ch['type'] ?? '') as String;
  final payload = _decodePayload(ch['payload']);
  final target = ch['target_amount'];

  String fmtNum(num n) => n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(0);

  switch (type) {
    case 'SAVE_AMOUNT':
      final num? amount = (target is num) ? target : (payload['amount'] as num?);
      return amount != null
          ? 'Ahorrá ${fmtNum(amount)}'
          : 'Ahorrá un monto personalizado';

    case 'REDUCE_SPENDING_PERCENT':
      final p = payload;
      final int windowDays = (p['window_days'] as num?)?.toInt() ?? 30;
      final num? maxAllowed = p['max_allowed'] is num
          ? p['max_allowed']
          : (p['max_allowed'] is String
              ? num.tryParse(p['max_allowed'])
              : null);

      if (maxAllowed != null) {
        return 
            'No superes ${maxAllowed.toStringAsFixed(0)} en gastos.\n'
            'Se evaluará durante $windowDays días desde que aceptes.';
      }

      return 
          'Se evaluará durante $windowDays días desde que aceptes.';

    case 'ADD_TRANSACTIONS':
      final int? count = (payload['count'] as num?)?.toInt() ??
          (target is num ? target.toInt() : null);
      return count != null
          ? 'Registrá $count movimientos'
          : 'Registrá tus movimientos esta semana';

    default:
      return (ch['description'] as String?) ?? '';
  }
}


  /// ✅ ACTUALIZADO para evitar overflow
  Widget _metaChips(BuildContext context, Map<String, dynamic> ch) {
  final cs = Theme.of(context).colorScheme;
  final payload = _decodePayload(ch['payload']);
  final duration =
      (payload['duration_days'] as num?)?.toInt() ??
      (ch['duration_days'] as num?)?.toInt() ??
      0;
  final points = ch['reward_points'] ?? 0;

    Widget chip(IconData icon, String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.25),
            border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        chip(Icons.schedule, 'Duración: $duration días'),
        chip(Icons.stars, 'Recompensa: $points pts'),
      ],
    );
  }

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
        final List<dynamic> challenges = _hideLocked
            ? rawList.where((c) => !(c['locked'] == true)).toList()
            : rawList;

        final List<Map<String, dynamic>> sorted =
            challenges.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        sorted.sort(_compareChallenges);

        final next = data['next_refresh_at'];
        Widget list = RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          onRefresh: _refreshChallengesManually,
          child: sorted.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildEmptyState(
                      context,
                      title: "¡No hay desafíos disponibles!",
                      message: "Parece que completaste todos los desafíos por ahora.\nPodés intentar regenerarlos 🎯",
                      icon: Icons.emoji_events_outlined,
                      onRefresh: _refreshChallengesManually,
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final ch = sorted[index];
                    final bool locked = ch['locked'] == true;
                    final String lockedReason = (ch['locked_reason'] as String?) ??
                        'Ya tenés un desafío de este tipo en progreso. Completalo para aceptar uno nuevo.';
                    final hint = _buildChallengeHint(ch);

                    // 🟢 Mostrar mensajes informativos del backend (type: INFO)
                    if ((ch['type'] ?? '') == 'INFO') {
                      return Card(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
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
                                    color: cs.onSurface.withValues(alpha: 0.9),
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

                    final TextStyle descStyle = locked
                        ? const TextStyle(color: Colors.white70)
                        : const TextStyle();
                    final TextStyle hintStyle = TextStyle(
                      fontWeight: FontWeight.w700,
                      color: locked ? Colors.white70 : null,
                    );

                    final card = Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: locked
                            ? BorderSide(color: cs.primary.withOpacity(0.25), width: 1)
                            : BorderSide(color: cs.primary.withOpacity(0.15), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(ch['name'] ?? '')),
                              if (locked)
                                Tooltip(
                                  message: lockedReason,
                                  child: const Icon(Icons.lock, size: 18),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((ch['description'] as String?)?.isNotEmpty == true)
                                Text(ch['description'], style: descStyle),
                              const SizedBox(height: 6),
                              Text(hint, style: hintStyle),
                              const SizedBox(height: 8),

                              // ✅ Wrap para evitar overflow
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [_metaChips(context, ch)],
                              ),

                              if (locked) ...[
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        lockedReason,
                                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Tooltip(
                            message: locked ? lockedReason : 'Aceptar',
                            child: ElevatedButton(
                              onPressed: locked ? null : () => _acceptChallenge(ch['id'], ch['name']),
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return cs.surfaceContainerHighest.withOpacity(0.35);
                                  }
                                  return cs.primary;
                                }),
                                foregroundColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.white70;
                                  }
                                  return cs.onPrimary;
                                }),
                              ),
                              child: Text(locked ? "Bloqueado" : "Aceptar"),
                            ),
                          ),
                        ),
                      ),
                    );

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: locked ? 0.55 : 1.0,
                      child: card,
                    );
                  },
                ),
        );

        if (next is String && next.isNotEmpty) {
  final dt = DateTime.tryParse(next);
  if (dt != null) {
    final formatted = TimeOfDay.fromDateTime(dt).format(context);

    list = Column(
      children: [
        // 🟣 Cartel de regenerar desafíos
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
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

        // 🟢 Switch para ocultar bloqueados (siempre visible, debajo del cartel)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _hideLockedToggle(),
        ),

        // 🟢 Lista de desafíos (el filtro _hideLocked ya se aplica arriba)
        Expanded(child: list),
      ],
    );
  }
} else {
  // 🔹 Cuando no hay cartel aún (primera carga), mostrar solo lista + switch arriba
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


        list = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            ),
            Expanded(child: list),
          ],
        );

        return list;
      },
    );
  }

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
          return _buildEmptyState(
            context,
            title: "Aún no aceptaste ningún desafío",
            message:
                "Podés aceptar uno desde la pestaña 'Disponibles' para empezar a ganar puntos y recompensas 🏅",
            icon: Icons.assignment_turned_in_outlined,
            onRefresh: () => _refreshTab(1),
          );
        }

        return RefreshIndicator(
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
                    .map((ch) => _challengeCard(context, ch))
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
                    .map((ch) => _challengeCard(context, ch, completed: true))
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
                ...failed.map((ch) => _challengeCard(context, ch)).toList(),
              ],
            ],
          ),
        );
      },
    );
  }


  Widget _challengeCard(BuildContext context, Map<String, dynamic> ch,
      {bool completed = false}) {
    final rawProgress = ch['pivot']?['progress'] ?? 0;
    final progress = rawProgress is String
        ? double.tryParse(rawProgress) ?? 0.0
        : (rawProgress as num).toDouble();
    final state =
        ch['pivot']?['state'] ?? (completed ? 'completed' : 'in_progress');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(ch['name'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((ch['description'] as String?)?.isNotEmpty == true)
              Text(ch['description'] ?? ''),
            Builder(builder: (_) {
              final merged = {
                'type': ch['type'],
                'description': ch['description'],
                'payload': ch['pivot']?['payload'] ?? ch['payload'],
                'target_amount': ch['pivot']?['target_amount'] ?? ch['target_amount'],
                'duration_days': ch['duration_days'],
                'reward_points': ch['reward_points'],
                'start_date': ch['pivot']?['start_date'],
              };
              final hint = _buildChallengeHint(merged);
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(hint, style: const TextStyle(fontWeight: FontWeight.w700)),
              );
            }),
            _metaChips(context, ch),
            const SizedBox(height: 8),
            // 🟣 Mostrar barra violeta solo si NO es el desafío de reducir gastos
            if (ch['type'] != 'REDUCE_SPENDING_PERCENT') ...[
              LinearProgressIndicator(
                value: (progress / 100).clamp(0.0, 1.0),
                color: state == 'completed'
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 6),
            ],

            // 🟢 Mostrar detalle adicional para desafíos de ahorro
            if (ch['type'] == 'SAVE_AMOUNT') ...[
              Builder(builder: (_) {
                final p = _decodePayload(ch['pivot']?['payload'] ?? ch['payload']);
                final num? goal = p['amount'] is num
                    ? p['amount']
                    : (ch['pivot']?['target_amount'] ?? ch['target_amount']);

                if (goal != null) {
                  final saved = (progress / 100) * goal;
                  final remaining = (goal - saved).clamp(0, goal);
                  return Text(
                    remaining > 0
                        ? 'Llevás ahorrado \$${saved.toStringAsFixed(0)} de \$${goal.toStringAsFixed(0)}'
                        : '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 4),
            ],

            // 🟢 Para REDUCE_SPENDING_PERCENT, mostrar solo la barra de gasto real
            if (ch['type'] == 'REDUCE_SPENDING_PERCENT') ...[
              Builder(builder: (_) {
                // ✅ Leer payload desde pivot (no desde ch['payload'])
                final p = _decodePayload(ch['pivot']?['payload'] ?? ch['payload']);

                final num? maxAllowed = p['max_allowed'] is num
                    ? p['max_allowed']
                    : (p['max_allowed'] is String
                        ? num.tryParse(p['max_allowed'])
                        : null);

                final num? currentSpent = p['current_spent'] is num
                    ? p['current_spent']
                    : (p['current_spent'] is String
                        ? num.tryParse(p['current_spent'])
                        : null);

                if (maxAllowed != null && currentSpent != null) {
                  final double percent = (currentSpent / maxAllowed).clamp(0.0, 1.0);
                  Color color;
                  if (percent < 0.5) {
                    color = Colors.green;
                  } else if (percent < 0.8) {
                    color = Colors.orange;
                  } else {
                    color = Colors.red;
                  }

                  final remaining = (maxAllowed - currentSpent).clamp(0, maxAllowed);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: percent,
                        color: color,
                        backgroundColor: Colors.grey[300],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remaining > 0
                            ? 'Te queda \$${remaining.toStringAsFixed(0)} de \$${maxAllowed.toStringAsFixed(0)}'
                            : 'Te pasaste del límite 😔',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],



            const SizedBox(height: 4),
            // 🔹 Mostrar texto diferente si el desafío es de reducción de gastos
            Builder(builder: (_) {
              if (ch['type'] == 'REDUCE_SPENDING_PERCENT') {
                final p = _decodePayload(ch['pivot']?['payload'] ?? ch['payload']);
                final num? maxAllowed = p['max_allowed'] is num
                    ? p['max_allowed']
                    : (p['max_allowed'] is String
                        ? num.tryParse(p['max_allowed'])
                        : null);
                final num? currentSpent = p['current_spent'] is num
                    ? p['current_spent']
                    : (p['current_spent'] is String
                        ? num.tryParse(p['current_spent'])
                        : null);

                if (maxAllowed != null && currentSpent != null) {
                  final double percent = (currentSpent / maxAllowed) * 100;
                  final remaining = (maxAllowed - currentSpent);

                  if (remaining > 0) {
                    return Text(
                      'Llevás gastado ${percent.toStringAsFixed(0)}% del límite',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    );
                  } else {
                    return const Text(
                      'Te pasaste del gasto permitido',
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    );
                  }
                }
              }

              // 🔸 Default para los demás tipos
              // 🔸 Mostrar estado según tipo y progreso
              if (state == 'completed') {
                return const Text(
                  'Completado 🎉',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                );
              } else if (state == 'failed') {
                return const Text(
                  'Fallido ❌',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w700),
                );
              } else {
                return Text(
                  'Progreso: ${progress.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                );
              }

            }),

          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required VoidCallback onRefresh,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 90, color: cs.primary.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text("Actualizar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
