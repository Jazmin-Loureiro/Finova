<?php

namespace App\Services\Challenges;

use App\Models\User;
use App\Models\Challenge;
use Illuminate\Support\Facades\DB;

class ChallengeGeneratorService
{
    public function generateForUser(User $user): array
    {
        $balance        = $user->balance ?? 0;
        $totalIngresos  = (float) $user->registers()->where('type', 'income')->sum('balance');
        $totalGastos    = (float) $user->registers()->where('type', 'expense')->sum('balance');
        $totalRegistros = (int)   $user->registers()->count();

        $now = now();
        $out = [];

        $toCode   = optional($user->currency)->code ?? 'ARS';
        $toSymbol = optional($user->currency)->symbol ?? '$';

        DB::transaction(function () use ($user, $balance, $totalIngresos, $totalGastos, $totalRegistros, $now, &$out, $toCode, $toSymbol) {

            // 1) SAVE_AMOUNT (si hay ingresos o hay balance inicial)
            if ($totalIngresos > 0 || $balance > 0) {
                $base = $this->getBase('SAVE_AMOUNT');
                $baseMonto = max($balance, $totalIngresos);

                // 🎯 Meta de ahorro: entre 5% y 20% del monto base
                $porcentaje = rand(5, 20) / 100;
                $target = round(max(100, min($baseMonto * $porcentaje, $baseMonto * 0.3)));

                // 🎲 Duración aleatoria: puede ser 7, 14, 21 o 30 días
                $durationDays = [7, 14, 21, 30][array_rand([7, 14, 21, 30])];

                $payload = [
                    'amount'        => $target,
                    'duration_days' => $durationDays,
                    'currency_code'   => $toCode,
                    'currency_symbol' => $toSymbol,
                ];

                $this->upsertUserChallenge(
                    user:         $user,
                    base:         $base,
                    state:        'suggested',
                    balance:      $user->balance ?? 0,
                    start:        null,
                    end:          null,
                    targetAmount: $target,
                    payload:      $payload
                );

                $out[] = array_merge(
                    $this->mapForResponse($base, $payload, $target, $user),
                    ['duration_days' => $durationDays]
                );
            }

            // 🧩 Si no tiene ingresos ni balance (usuario nuevo)
            else {
                $base = $this->getBase('SAVE_AMOUNT');

                // 🎯 Desafío simbólico inicial
                $target = 50;
                $durationDays = 7; // corto para motivar

                $payload = [
                    'amount'        => $target,
                    'duration_days' => $durationDays,
                    'intro'         => true, 
                    'currency_code'   => $toCode,
                    'currency_symbol' => $toSymbol,
                ];

                \Log::info("Usuario {$user->id}: desafío inicial simbólico de ahorro creado", [
                    'target' => $target,
                    'duration_days' => $durationDays,
                ]);

                $this->upsertUserChallenge(
                    user:         $user,
                    base:         $base,
                    state:        'suggested',
                    balance:      0,
                    start:        null,
                    end:          null,
                    targetAmount: $target,
                    payload:      $payload
                );

                $out[] = array_merge(
                    $this->mapForResponse($base, $payload, $target, $user),
                    ['duration_days' => $durationDays]
                );
            }


            // 2) REDUCE_SPENDING_PERCENT (solo si hay historial útil y antigüedad mínima)
            if ($totalGastos > 0) {

                // 🚫 Evitar generar si ya tiene uno de este tipo en progreso
                $hasReduceActive = $user->challenges()
                    ->where('challenges.type', 'REDUCE_SPENDING_PERCENT')
                    ->wherePivot('state', 'in_progress')
                    ->exists();

                if ($hasReduceActive) {
                    \Log::info("Usuario {$user->id} omitido para REDUCE: ya tiene un desafío activo.");

                    // Informamos al frontend que no se generó uno nuevo
                    $out[] = [
                        'type' => 'INFO',
                        'message' => 'Ya tenés un desafío de reducción de gastos en curso. Cuando lo completes, te sugeriremos uno nuevo.',
                    ];
                } else {
                    // ⏳ Evitar generar desafíos de reducción si el usuario es muy nuevo
                    $minDaysSinceRegister = 7;
                    $daysSinceRegister = $user->created_at->diffInDays(now());

                    if ($daysSinceRegister < $minDaysSinceRegister) {
                        \Log::info("Usuario {$user->id} omitido para REDUCE: antigüedad {$daysSinceRegister} días (mínimo {$minDaysSinceRegister}).");

                        $out[] = [
                            'type' => 'INFO',
                            'message' => 'Los desafíos de reducción estarán disponibles luego de tu primera semana de uso.',
                        ];
                    } else {
                        $base = $this->getBase('REDUCE_SPENDING_PERCENT');

                        // 🎲 Modo aleatorio: semanal o mensual
                        $mode = rand(0, 1) === 0 ? 'weekly' : 'monthly';
                        $windowDays = $mode === 'weekly' ? 7 : 30;

                        // 🔢 Gastos del periodo anterior (baseline)
                        $toCode = optional($user->currency)->code ?? 'ARS';
                        $since = now()->copy()->subDays($windowDays);
                        $regsPrev = $user->registers()->with('currency')
                            ->where('type', 'expense')
                            ->whereBetween('created_at', [$since, now()])
                            ->get();

                        $minTxsRequired = 3;
                        $minBaselineAmt = 100;
                        $baseline = 0.0;

                        foreach ($regsPrev as $r) {
                            $fromCode = optional($r->currency)->code ?? $toCode;
                            $rate = $fromCode === $toCode ? 1.0 : \App\Services\CurrencyService::getRate($fromCode, $toCode);
                            $baseline += (float)$r->balance * $rate;
                        }

                        if ($regsPrev->count() >= $minTxsRequired && $baseline >= $minBaselineAmt) {
                            // 🔹 Calcular cuánto lleva gastado actualmente (en el período actual)
                            $sinceCurrent = now()->copy()->subDays($windowDays);
                            $regsCurrent = $user->registers()->with('currency')
                                ->where('type', 'expense')
                                ->whereBetween('created_at', [$sinceCurrent, now()])
                                ->get();

                            $currentSpent = 0.0;
                            foreach ($regsCurrent as $r) {
                                $fromCode = optional($r->currency)->code ?? $toCode;
                                $rate = $fromCode === $toCode ? 1.0 : \App\Services\CurrencyService::getRate($fromCode, $toCode);
                                $currentSpent += (float)$r->balance * $rate;
                            }

                            // 🔹 Armar payload con límite y gasto actual
                            $payload = [
                                'mode' => $mode,
                                'window_days' => $windowDays,
                                'max_allowed' => round($baseline, 2),
                                'current_spent' => round($currentSpent, 2),
                                'currency_code'   => $toCode,
                                'currency_symbol' => $toSymbol,
                            ];

                            $this->upsertUserChallenge(
                                user: $user,
                                base: $base,
                                state: 'suggested',
                                balance: $user->balance ?? 0,
                                start: null,
                                end: null,
                                targetAmount: round($baseline, 2),
                                payload: $payload
                            );

                            $out[] = $this->mapForResponse($base, $payload, $baseline, $user);
                        } else {
                            $out[] = [
                                'type' => 'INFO',
                                'message' => 'Aún no hay suficientes gastos registrados para generar un desafío de reducción.',
                            ];
                        }
                    }
                }
            }




            // 3) ADD_TRANSACTIONS (siempre)
            $base = $this->getBase('ADD_TRANSACTIONS');
            $baseCount = min(20, max(5, (int) round($totalRegistros * 0.2)));
            $count = rand($baseCount, $baseCount + 5);

            // 🎲 Duración aleatoria entre 1 y 9 días
            $durationDays = rand(1, 9);

            // Guardamos el payload para mostrar en el frontend
            $payload = [
                'count' => $count,
                'duration_days' => $durationDays,
                'currency_code'   => $toCode,
                'currency_symbol' => $toSymbol,
            ];

            $this->upsertUserChallenge(
                user:         $user,
                base:         $base,
                state:        'suggested',
                balance:      $user->balance ?? 0,
                start:        null,
                end:          null,
                targetAmount: $count,
                payload:      $payload
            );

            // ✅ Devolvemos al frontend con duración personalizada
            $out[] = array_merge(
                $this->mapForResponse($base, $payload, $count, $user),
                ['duration_days' => $durationDays]
            );

        });

        return $out;
    }

    private function getBase(string $type): Challenge
    {
        $challenge = Challenge::where('type', $type)
            ->where('active', true)
            ->first();

        if (!$challenge) {
            throw new \RuntimeException("No existe desafío base activo para type={$type}. Cargá el catálogo.");
        }
        return $challenge;
    }

    private function upsertUserChallenge(
    User $user,
    Challenge $base,
    string $state,
    float $balance,
    ?\DateTimeInterface $start,
    ?\DateTimeInterface $end,
    float|int|null $targetAmount,
    array $payload
): void {

    // 🟡 1) Permitir siempre mostrar uno por tipo, incluso si hay uno en progreso
    // Solo bloquea la aceptación (el front ya lo hace con "locked": true)
    $hasInProgress = \DB::table('users_challenges')
        ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
        ->where('users_challenges.user_id', $user->id)
        ->where('users_challenges.state', 'in_progress')
        ->where('challenges.type', $base->type)
        ->exists();

    // 🟢 2) Buscar si ya hay un "suggested" del mismo tipo
    $existingSuggested = \DB::table('users_challenges')
        ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
        ->where('users_challenges.user_id', $user->id)
        ->where('users_challenges.state', 'suggested')
        ->where('challenges.type', $base->type)
        ->select('users_challenges.id')
        ->first();

    if ($existingSuggested) {
        // 🔁 Actualizamos el existente con nuevos valores (refrescar payload)
        \App\Models\UserChallenge::where('id', $existingSuggested->id)->update([
            'balance'       => $balance,
            'target_amount' => $targetAmount,
            'payload'       => $payload ?: null,
            'updated_at'    => now(),
        ]);
    } else {
        // ✳️ Creamos uno nuevo (solo si no hay sugerido del mismo tipo)
        \App\Models\UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $base->id,
            'state'         => $state,
            'balance'       => $balance,
            'progress'      => 0,
            'start_date'    => $start,
            'end_date'      => $end,
            'target_amount' => $targetAmount,
            'payload'       => $payload ?: null,
        ]);
    }

    // 🧹 3) Limpieza opcional:
    // Si hay más de un sugerido duplicado por error (muy raro), eliminamos extras
    $duplicates = \DB::table('users_challenges')
    ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
    ->where('users_challenges.user_id', $user->id)
    ->where('users_challenges.state', 'suggested')
    ->where('challenges.type', $base->type)
    ->orderByDesc('users_challenges.updated_at')
    ->skip(1) // deja el más nuevo
    ->take(999999) // 👈 agregado: evita error de sintaxis
    ->pluck('users_challenges.id')
    ->all();


    if (!empty($duplicates)) {
        \DB::table('users_challenges')->whereIn('id', $duplicates)->delete();
    }
}





    private function mapForResponse(Challenge $base, array $payload, float|int|null $target, ?User $user = null): array
    {
        $userLevel = $user?->level ?? 1;

        // 🎯 Escala de recompensa: +15% por nivel
        $levelMultiplier = 1 + (($userLevel - 1) * 0.15);
        $scaledPoints = (int) round($base->reward_points * $levelMultiplier);

        // 🔹 Limitamos un máximo razonable (por ejemplo, no más del triple del valor base)
        $scaledPoints = min($scaledPoints, $base->reward_points * 3);

        return [
            'id'             => $base->id,
            'name'           => $base->name,
            'description'    => $base->description,
            'type'           => $base->type,
            'payload'        => $payload,
            'target_amount'  => $target,
            'duration_days'  => (int) $base->duration_days,
            'reward_points'  => $scaledPoints,
        ];
    }

}
