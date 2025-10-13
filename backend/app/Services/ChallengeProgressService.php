<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserChallenge;
use Carbon\Carbon;

class ChallengeProgressService
{
    /**
     * 🔄 Recalcula todos los desafíos activos del usuario
     * y devuelve las recompensas que se hayan generado.
     */
    public function recomputeForUserWithRewards(User $user): array
    {
        $rewards = [];

        // ✅ Solo desafíos realmente en progreso (no sugeridos ni completados)
        $inProgress = $user->challenges()
            ->wherePivot('state', '=', 'in_progress')
            ->withPivot(['end_date','progress'])
            ->get();


        foreach ($inProgress as $ch) {
            // 🔒 Filtro adicional por seguridad
            if (!in_array($ch->pivot->state, ['in_progress'], true)) {
                continue;
            }

            $r = $this->recomputeSingle($user, $ch->id);
            if ($r !== null) {
                $rewards[] = $r;
            }
        }

        return $rewards;
    }

    /**
     * 🔹 Recalcula un desafío individual. Si se completa,
     * otorga recompensa y devuelve info; si no, devuelve null.
     */
    public function recomputeSingle(User $user, int $challengeId): ?array
    {
        /** @var UserChallenge|null $pivot */
        $pivot = UserChallenge::where('user_id', $user->id)
            ->where('challenge_id', $challengeId)
            ->where('state', 'in_progress')
            ->select(['*', 'end_date', 'progress'])
            ->orderByDesc('id')
            ->first();


        // ✅ Seguridad: solo recalcular si está en progreso
        if (!$pivot || $pivot->state !== 'in_progress') {
            return null;
        }

        $pivot->refresh();

        // 🔹 Verificar vencimiento global (sin importar tipo)
if (!empty($pivot->end_date)) {
    $end = Carbon::parse($pivot->end_date);
    if ($end->isPast() && $pivot->progress < 100) {
        $pivot->update([
            'state' => 'failed',
            'progress' => $pivot->progress,
        ]);
        return null; // no seguir procesando
    }
}


        $type     = $pivot->challenge->type;
        $payload  = is_array($pivot->payload) ? $pivot->payload
                    : (is_string($pivot->payload) ? (json_decode($pivot->payload, true) ?: []) : []);
        $target   = $pivot->target_amount;
        $start    = $pivot->start_date ?? $pivot->created_at ?? now();
        $now      = now();

        $wasCompleted = ($pivot->state === 'completed');
        $progress = 0;

        switch ($type) {
            /**
             * 🧾 Agregar transacciones
             */
            case 'ADD_TRANSACTIONS': {
    $countTarget = (int)($payload['count'] ?? $target ?? 5);
    $count = $user->registers()
        ->where('created_at', '>=', $start)
        ->count();

    // 🔹 Calcular progreso
    $progress = min(100, (int)round(($count / max(1, $countTarget)) * 100));

    // 🔹 Duración (usamos la del desafío base o del payload si viene)
    $durationDays = (int)($payload['duration_days'] ?? 30);
    $endDate = Carbon::parse($start)->addDays($durationDays);

    // 🔹 Si pasó el límite de tiempo y no completó → marcar como fallido
    if (now()->greaterThanOrEqualTo($endDate) && $progress < 100) {
        $pivot->update([
            'state' => 'failed',
            'end_date' => now(),
            'progress' => $progress,
        ]);
        return null;
    }

    break;
}


            /**
             * 💰 Ahorro (SAVE_AMOUNT)
             */
            case 'SAVE_AMOUNT': {
    $baseline = (float)($pivot->balance ?? 0.0);
    $startDate = $pivot->start_date ?? $pivot->created_at ?? now();

    // 🔹 Solo ingresos de tipo “Ahorro”
    $ahorros = $user->registers()
        ->where('type', 'income')
        ->whereHas('moneyMaker', function ($q) {
            $q->whereRaw('LOWER(type) LIKE ?', ['%ahorro%']);
        })
        ->where('created_at', '>=', $startDate)
        ->when(isset($payload['challenge_uid']), function ($q) use ($payload) {
            // si en el payload guardás un ID único del desafío, filtrás solo ese
            $q->where('description', 'like', '%' . $payload['challenge_uid'] . '%');
        })
        ->get();

    $toCode = optional($user->currency)->code ?? 'ARS';
    $totalAhorro = 0.0;

    foreach ($ahorros as $r) {
        $fromCode = optional($r->currency)->code ?? $toCode;
        $rate = $fromCode === $toCode
            ? 1.0
            : \App\Services\CurrencyService::getRate($fromCode, $toCode);
        $totalAhorro += (float)$r->balance * $rate;
    }

    // Meta objetivo
    $goal = (float)($payload['amount'] ?? $target ?? 100.0);
    if ($goal <= 0) $goal = 100.0;

    // 🔹 Duración (random según payload)
    $durationDays = (int)($payload['duration_days'] ?? 30);
    $endDate = Carbon::parse($startDate)->addDays($durationDays);

    // 🔹 Calcular progreso
    $progress = min(100, (int)round(($totalAhorro / $goal) * 100));

    // 🔹 Si ya pasó el tiempo y no completó → marcar como fallido
    if (now()->greaterThanOrEqualTo($endDate) && $progress < 100) {
        $pivot->update([
            'state' => 'failed',
            'end_date' => now(),
            'progress' => $progress,
        ]);
        return null;
    }

    break;
}


            /**
             * 📉 Reducir gastos (REDUCE_SPENDING_PERCENT)
             */
            case 'REDUCE_SPENDING_PERCENT': {
    $windowDays = (int)($payload['window_days'] ?? 30);
    $baseline = (float)($payload['baseline_expenses'] ?? 0);

    if ($baseline <= 0) {
        $prevStart = Carbon::parse($start)->copy()->subDays($windowDays);
        $baseline = $this->sumExpensesInBase($user, $prevStart, $start);
    }

    $periodStart = isset($payload['period_start'])
        ? Carbon::parse($payload['period_start'])
        : Carbon::parse($pivot->start_date ?? $start);

    $plannedEnd = $periodStart->copy()->addDays($windowDays);
    $nowCappedEnd = now()->lessThan($plannedEnd) ? now() : $plannedEnd;

    // 🔹 Gastos actuales
    $currentExpenses = $this->sumExpensesInBase($user, $periodStart, $nowCappedEnd);

    // 🔹 Calcular progreso
    if ($baseline > 0) {
        $ratio = $currentExpenses / $baseline;
        $progress = max(0, min(99, (int)round($ratio * 100)));
    }

    // 🔹 Evaluar si terminó el periodo
    if (now()->greaterThanOrEqualTo($plannedEnd)) {
        $progress = ($currentExpenses <= $baseline) ? 100 : 99;
    }

    // 🔹 Actualizar payload
    $payload['max_allowed']   = round($baseline, 2);
    $payload['current_spent'] = round($currentExpenses, 2);
    $payload['period_start']  = $periodStart->toIso8601String();

    $pivot->update([
        'progress' => $progress,
        'payload'  => $payload,
    ]);

    // 🔹 Si ya terminó el período y no cumplió → marcar como fallido
    if (now()->greaterThanOrEqualTo($plannedEnd) && $currentExpenses > $baseline) {
        $pivot->update([
            'state' => 'failed',
            'end_date' => now(),
            'progress' => $progress,
            'payload'  => $payload,
        ]);
        return null;
    }

    break;
}

        }

        $update = ['progress' => $progress];

        // 🟢 Si se completó y no lo estaba → marcar y recompensar
        if ($progress >= 100 && !$wasCompleted) {
            $update['state']    = 'completed';
            $update['end_date'] = $now;
        }

        $pivot->update($update);

        // 🎁 Entregar recompensa solo si acaba de completarse
        if (isset($update['state']) && $update['state'] === 'completed') {
            $reward = app(\App\Services\GamificationService::class)
                ->rewardUser($user, $pivot->challenge);
            return is_array($reward) ? $reward : null;
        }

        return null;
    }

    /**
     * 💸 Suma de gastos del usuario en rango de fechas (en su moneda base)
     */
    private function sumExpensesInBase(User $user, $from, $to): float
    {
        $toCode = optional($user->currency)->code ?? 'ARS';

        $regs = $user->registers()
            ->with('currency')
            ->where('type', 'expense')
            ->whereBetween('created_at', [$from, $to])
            ->get();

        $sum = 0.0;
        foreach ($regs as $r) {
            $fromCode = optional($r->currency)->code ?? $toCode;
            $rate = $fromCode === $toCode
                ? 1.0
                : \App\Services\CurrencyService::getRate($fromCode, $toCode);
            $sum += (float)$r->balance * $rate;
        }

        return $sum;
    }
}
