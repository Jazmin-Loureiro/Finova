<?php

namespace App\Http\Controllers;

use App\Models\UserChallenge;
use App\Models\Goal;
use App\Models\Challenge;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\QueryException;
use Carbon\Carbon;

class UserChallengeController extends Controller
{
    /**
     * 📋 Listar desafíos del usuario (activos o completados)
     */
    // ⚠️ Obsoleto: ahora se usa GamificationController@profile
    public function index(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        $state = $request->query('state'); // 'in_progress' | 'completed'

        $query = $user->challenges()->with('badge');

        if ($state) {
            $query->wherePivot('state', $state);
        }

        // 🔹 Recalcular progreso y gasto antes de devolver
        app(\App\Services\Challenges\ChallengeProgressService::class)->recomputeForUserWithRewards($user);

        $challenges = $query->get();

        return response()->json([
            'user_challenges' => $challenges
        ]);
    }

    /**
     * ✅ Aceptar un desafío (el usuario lo elige manualmente)
     */
    public function accept(Request $request, $challengeId)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        // Verificá que exista y esté activo
        $challenge = Challenge::where('active', true)->findOrFail($challengeId);

        return DB::transaction(function () use ($user, $challenge) {

            // 🔒 Bloqueo por tipo
            $hasTypeInProgress = DB::table('users_challenges')
                ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
                ->where('users_challenges.user_id', $user->id)
                ->where('users_challenges.state', 'in_progress')
                ->where('challenges.type', $challenge->type)
                ->lockForUpdate()
                ->exists();

            if ($hasTypeInProgress) {
                return response()->json([
                    'blocked'       => true,
                    'message'       => 'No podés aceptar este desafío porque ya tenés uno del mismo tipo en progreso.',
                    'locked_reason' => 'Ya tenés un desafío de este tipo en progreso. Completalo para aceptar uno nuevo.',
                ], 409);
            }

            // Buscar si existe uno "suggested"
            $suggested = UserChallenge::where('user_id', $user->id)
                ->where('challenge_id', $challenge->id)
                ->where('state', 'suggested')
                ->lockForUpdate()
                ->first();

            // 🔹 Leer payload sugerido (si existe)
            $payloadArr = [];
            if ($suggested && $suggested->payload) {
                $payloadArr = is_array($suggested->payload)
                    ? $suggested->payload
                    : (is_string($suggested->payload) ? (json_decode($suggested->payload, true) ?: []) : []);
            }

            // 🔹 Calcular duración correctamente (prioridad: payload → challenge → 30)
            $durationDays = (int) ($payloadArr['duration_days'] ?? $challenge->duration_days ?? 30);
            $start = now();
            $end   = now()->addDays($durationDays);

            // Datos base
            $update = [
                'state'      => 'in_progress',
                'start_date' => $start,
                'end_date'   => $end,
            ];

            // ⚙️ NUEVO: creación automática de meta espejo si es desafío de ahorro
            $goalId = null;
            if ($challenge->type === 'SAVE_AMOUNT') {
                $target = (float)($suggested->target_amount ?? $payloadArr['amount'] ?? 0);
                if ($target <= 0) $target = 100;

                $goal = Goal::create([
                    'user_id'           => $user->id,
                    'name'              => 'Desafío: ' . ($challenge->name ?? 'Ahorro'),
                    'target_amount'     => $target,
                    'currency_id'       => $user->currency_id,
                    'date_limit'        => $end,
                    'balance'           => 0,
                    'state'             => 'in_progress',
                    'active'            => true,
                    'is_challenge_goal' => true,
                ]);

                $goalId = $goal->id;
                $update['balance'] = $user->balance ?? 0;
                $update['goal_id'] = $goalId;
            }

            // 🧩 Si es de reducción de gastos, mantiene tu lógica actual
            if ($challenge->type === 'REDUCE_SPENDING_PERCENT') {
                $windowDays = (int)($payloadArr['window_days'] ?? 30);
                $prevStart  = now()->copy()->subDays($windowDays);
                $toCode     = optional($user->currency)->code ?? 'ARS';

                $regs = $user->registers()
                    ->with('currency')
                    ->where('type', 'expense')
                    ->whereBetween('created_at', [$prevStart, now()])
                    ->get();

                $baselinePrev = 0.0;
                foreach ($regs as $r) {
                    $fromCode = optional($r->currency)->code ?? $toCode;
                    $rate = ($fromCode === $toCode) ? 1.0 : \App\Services\CurrencyService::getRate($fromCode, $toCode);
                    $baselinePrev += (float)$r->balance * $rate;
                }

                if (!isset($payloadArr['reduction'])) {
                    $payloadArr['reduction'] = rand(10, 25);
                }

                $payloadArr['baseline_expenses'] = $baselinePrev;
                $payloadArr['window_days']       = $windowDays;
                $payloadArr['mode']              = $payloadArr['mode'] ?? ($windowDays <= 7 ? 'weekly' : 'monthly');
                $payloadArr['max_allowed']       = round($baselinePrev, 2);
                $payloadArr['current_spent']     = 0.0;
                $payloadArr['period_start']      = now()->toIso8601String();

                $update['payload'] = $payloadArr;
            }

            // 🔹 Si existía uno suggested, lo promovemos
            if ($suggested) {
                $suggested->fill($update)->save();
                return response()->json([
                    'message' => 'Desafío aceptado correctamente.',
                    'goal_id' => $goalId,
                    'start'   => $start->toIso8601String(),
                    'end'     => $end->toIso8601String(),
                ], 200);
            }

            // 🔹 Si no existía, lo creamos desde cero (tu caso original)
            $create = array_merge([
    'user_id'      => $user->id,
    'challenge_id' => $challenge->id,
    'progress'     => 0,
], $update);

// 🔹 Aseguramos guardar el goal_id siempre que se haya creado
if (!empty($goalId)) {
    $create['goal_id'] = $goalId;
}

try {
    $uc = UserChallenge::create($create);

    // 🔹 Extra: si el registro se creó, aseguramos persistir el vínculo
    if ($uc && !empty($goalId)) {
        $uc->goal_id = $goalId;
        $uc->save();
    }
} catch (QueryException $e) {
                if ((int)($e->errorInfo[1] ?? 0) === 1062) {
                    return response()->json(['message' => 'Ya tenés este desafío en progreso.'], 200);
                }
                throw $e;
            }

            return response()->json([
                'message' => 'Desafío aceptado correctamente.',
                'goal_id' => $goalId,
                'start'   => $start->toIso8601String(),
                'end'     => $end->toIso8601String(),
            ], 200);
        });
    }



    /**
     * 🏁 Marcar un desafío como completado (manual o automático)
     */
    //public function complete(Request $request, $challengeId)
    //{
    //    /** @var \App\Models\User $user */
    //    $user = \Auth::user();

    //    $pivot = \App\Models\UserChallenge::where('user_id', $user->id)
    //        ->where('challenge_id', $challengeId)
    //        ->where('state', 'in_progress')
    //        ->orderByDesc('id')
    //        ->first();

   //     if (!$pivot) {
    //        return response()->json(['message' => 'No tenés este desafío en progreso.'], 404);
    //    }

    //    if ($pivot->state === 'completed') {
    //        return response()->json(['message' => 'Este desafío ya fue completado.']);
    //    }

    //    $pivot->update([
    //        'state'    => 'completed',
    //        'end_date' => now(),
    //        'progress' => 100,
    //    ]);

    //    $challenge = \App\Models\Challenge::find($challengeId);

        // ⚠️ PASAR EL PIVOT a rewardUser (ver punto 3)
    //    app('App\Services\GamificationService')->rewardUser($user, $challenge, $pivot);

    //    return response()->json([
    //        'message'        => 'Desafío completado, puntos e insignias asignados.',
    //        'reward_points'  => $challenge->reward_points,
    //        'challenge'      => $challenge
    //    ]);
    //}


    
}
