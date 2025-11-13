<?php

namespace App\Http\Controllers;

use App\Models\Challenge;
use App\Models\User;
use App\Services\Challenges\ChallengeGeneratorService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class ChallengeController extends Controller
{
    private ChallengeGeneratorService $generator;
    private int $cooldownHours = 12;

    public function __construct(ChallengeGeneratorService $generator)
    {
        $this->middleware('auth:sanctum');
        $this->generator = $generator;
    }

    /**
     * 🔎 Desafíos disponibles (genéricos/activos)
     */
    public function available(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $serverNow = now();

        $nextRefreshAt = $user->last_challenge_refresh
            ? Carbon::parse($user->last_challenge_refresh)->addHours($this->cooldownHours)
            : null;

        // ⚙️ 1) Verificamos si ya hay desafíos sugeridos
        $hasSuggested = $user->challenges()
            ->wherePivot('state', 'suggested')
            ->exists();

        $generatorOutput = [];

        // ⚙️ 2) Si no hay sugeridos, generamos nuevos
        if (!$hasSuggested) {
            $generatorOutput = DB::transaction(function () use ($user) {
                return $this->generator->generateForUser($user);
            });
        }

        // ⚙️ 3) Evitar duplicar REDUCE si ya hay uno en progreso
        $hasReduceInProgress = $user->challenges()
            ->wherePivot('state', 'in_progress')
            ->where('challenges.type', 'REDUCE_SPENDING_PERCENT')
            ->exists();

        // ⚙️ 4) Si hay sugeridos pero falta REDUCE, generarlo si califica
        if ($hasSuggested && !$hasReduceInProgress) {
            $toCode = optional($user->currency)->code ?? 'ARS';
            $windowDays = 30;
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

            $hasReduceSuggested = $user->challenges()
                ->wherePivot('state', 'suggested')
                ->where('challenges.type', 'REDUCE_SPENDING_PERCENT')
                ->exists();

            if (
                !$hasReduceSuggested &&
                $regsPrev->count() >= $minTxsRequired &&
                $baseline >= $minBaselineAmt
            ) {
                $moreOutput = DB::transaction(function () use ($user) {
                    return $this->generator->generateForUser($user);
                });
                if (is_array($moreOutput)) {
                    $generatorOutput = array_merge($generatorOutput, $moreOutput);
                }
            }
        }

        // ⚙️ 5) Tipos con in_progress
        $inProgressTypes = DB::table('users_challenges')
            ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
            ->where('users_challenges.user_id', $user->id)
            ->where('users_challenges.state', 'in_progress')
            ->pluck('challenges.type')
            ->all();

        // ⚙️ 6) Desafíos sugeridos existentes en BD
        $items = $user->challenges()
            ->wherePivot('state', 'suggested')
            ->get([
                'challenges.id',
                'challenges.name',
                'challenges.description',
                'challenges.type',
                'challenges.duration_days',
                'challenges.reward_points',
            ])
            ->map(function ($ch) use ($inProgressTypes, $user) {
                $pivotPayload = $ch->pivot->payload;

                if (is_string($pivotPayload)) {
                    $decoded = json_decode($pivotPayload, true) ?: [];
                } elseif (is_array($pivotPayload)) {
                    $decoded = $pivotPayload;
                } elseif ($pivotPayload instanceof \Illuminate\Contracts\Support\Arrayable) {
                    $decoded = $pivotPayload->toArray();
                } else {
                    $decoded = [];
                }

                $locked = in_array($ch->type, $inProgressTypes, true);

                // Moneda base del usuario (informativa para front)
                $code   = optional($user->currency)->code ?? 'ARS';
                $symbol = optional($user->currency)->symbol ?? '$';

                // Sobrescribimos por si el payload viene de antes
                $decoded['currency_code']   = $code;
                $decoded['currency_symbol'] = $symbol;

                return [
                    'id'             => $ch->id,
                    'name'           => $ch->name,
                    'description'    => $ch->description,
                    'type'           => $ch->type,
                    'payload'        => $decoded,
                    'target_amount'  => $ch->pivot->target_amount,
                    'duration_days'  => (int) $ch->duration_days,
                    'reward_points'  => (int) $ch->reward_points,
                    'locked'         => $locked,
                    'locked_reason'  => $locked
                        ? 'Ya tenés un desafío de este tipo en progreso. Completalo para aceptar uno nuevo.'
                        : null,
                    // Atajo para UI (además de payload)
                    'currency_code'   => $code,
                    'currency_symbol' => $symbol,
                ];
            })
            ->values();

        // ⚙️ 7) Mezclamos desafíos reales + mensajes informativos (si hay)
        $available = collect($items);
        if (!empty($generatorOutput)) {
            foreach ($generatorOutput as $info) {
                if (isset($info['type']) && $info['type'] === 'INFO') {
                    $available->push($info);
                }
            }
        }

        return response()->json([
            'available_challenges'   => $available->values(),
            'server_now'             => $serverNow->toIso8601String(),
            'last_challenge_refresh' => optional($user->last_challenge_refresh)->toIso8601String(),
            'next_refresh_at'        => optional($nextRefreshAt)->toIso8601String(),
        ]);
    }


    /**
     * 🔁 Refresh con cooldown de 12h
     */
    public function refresh(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $now = now();
        $nextRefreshAt = $user->last_challenge_refresh
            ? Carbon::parse($user->last_challenge_refresh)->addHours($this->cooldownHours)
            : null;

        if ($nextRefreshAt && $now->lt($nextRefreshAt)) {
            return response()->json([
                'message'                => 'Tenés que esperar un poco antes de regenerar desafíos.',
                'server_now'             => $now->toIso8601String(),
                'last_challenge_refresh' => $user->last_challenge_refresh->toIso8601String(),
                'next_refresh_at'        => $nextRefreshAt->toIso8601String(),
            ], 429);
        }

        // 🟢 Ejecutamos el generador igual que en available()
        $generated = DB::transaction(function () use ($user, $now) {
            $challenges = $this->generator->generateForUser($user);

            $user->last_challenge_refresh = $now;
            $user->save();

            return $challenges; // 👈 devuelve $out del generator
        });

        $next = $now->copy()->addHours($this->cooldownHours);

        // Tipos con in_progress
        $inProgressTypes = DB::table('users_challenges')
            ->join('challenges', 'challenges.id', '=', 'users_challenges.challenge_id')
            ->where('users_challenges.user_id', $user->id)
            ->where('users_challenges.state', 'in_progress')
            ->pluck('challenges.type')
            ->all();

        // Leemos TODOS los suggested
        $items = $user->challenges()
            ->wherePivot('state', 'suggested')
            ->get([
                'challenges.id',
                'challenges.name',
                'challenges.description',
                'challenges.type',
                'challenges.duration_days',
                'challenges.reward_points',
            ])
            ->map(function ($ch) use ($inProgressTypes, $user) {
                $pivotPayload = $ch->pivot->payload;

                if (is_string($pivotPayload)) {
                    $decoded = json_decode($pivotPayload, true) ?: [];
                } elseif (is_array($pivotPayload)) {
                    $decoded = $pivotPayload;
                } elseif ($pivotPayload instanceof \Illuminate\Contracts\Support\Arrayable) {
                    $decoded = $pivotPayload->toArray();
                } else {
                    $decoded = [];
                }

                $locked = in_array($ch->type, $inProgressTypes, true);

                // Moneda base del usuario (informativa para front)
                $code   = optional($user->currency)->code ?? 'ARS';
                $symbol = optional($user->currency)->symbol ?? '$';

                // Sobrescribimos por si el payload viene de antes
                $decoded['currency_code']   = $code;
                $decoded['currency_symbol'] = $symbol;

                return [
                    'id'             => $ch->id,
                    'name'           => $ch->name,
                    'description'    => $ch->description,
                    'type'           => $ch->type,
                    'payload'        => $decoded,
                    'target_amount'  => $ch->pivot->target_amount,
                    'duration_days'  => (int) $ch->duration_days,
                    'reward_points'  => (int) $ch->reward_points,
                    'locked'         => $locked,
                    'locked_reason'  => $locked
                        ? 'Ya tenés un desafío de este tipo en progreso. Completalo para aceptar uno nuevo.'
                        : null,
                    // Atajo para UI (además de payload)
                    'currency_code'   => $code,
                    'currency_symbol' => $symbol,
                ];
            })

            ->values();

        // 🟢 Agregamos también los mensajes INFO del generator (si hay)
        $available = collect($items);
        if (!empty($generated)) {
            foreach ($generated as $info) {
                if (isset($info['type']) && $info['type'] === 'INFO') {
                    $available->push($info);
                }
            }
        }

        return response()->json([
            'available_challenges'   => $available->values(),
            'server_now'             => $now->toIso8601String(),
            'last_challenge_refresh' => $now->toIso8601String(),
            'next_refresh_at'        => $next->toIso8601String(),
        ]);
    }


    /**
     * 📋 Mis desafíos
     */
    //public function myChallenges(Request $request): JsonResponse
    //{
       // /** @var User $user */
      //  $user = $request->user();

       // $state = $request->query('state');
        //$query = $user->challenges()->withPivot(['balance','state','progress','start_date','end_date']);

        //if ($state) {
        //    $query->wherePivot('state', $state);
     //   }

       // $items = $query->get([
         //   'challenges.id','challenges.name','challenges.description','challenges.type',
        //    'challenges.target_amount','challenges.duration_days','challenges.reward_points'
        //]);

        //return response()->json([
        //    'user_challenges' => $items,
        //]);
    //}


}
