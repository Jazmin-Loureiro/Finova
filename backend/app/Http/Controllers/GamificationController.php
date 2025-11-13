<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class GamificationController extends Controller
{
    /**
     * 📊 Perfil de gamificación completo del usuario autenticado
     * - Recalcula progreso/estado (incluye fail por vencimiento)
     * - Devuelve badges y desafíos agrupados por estado
     */
    public function profile(Request $request)
    {
        /** @var \App\Models\User $user */
        $user = Auth::user();

        // 🔄 Recalcular progreso y cerrar automáticamente (failed/completed + recompensas)
        app(\App\Services\Challenges\ChallengeProgressService::class)->recomputeForUserWithRewards($user);

        // 🏅 Insignias: todas, pero marcando las desbloqueadas del usuario
        $allBadges = \App\Models\Badge::all([
            'id as badge_id',
            'name',
            'slug',
            'icon',
            'tier',
            'description',
        ]);

        $unlockedIds = $user->badges()->pluck('badges.id')->toArray();

        $badges = $allBadges->map(function ($badge) use ($unlockedIds) {
            return [
                'badge_id' => $badge->badge_id,
                'name' => $badge->name,
                'slug' => $badge->slug,
                'icon' => $badge->icon,
                'tier' => $badge->tier,
                'description' => $badge->description,
                'unlocked' => in_array($badge->badge_id, $unlockedIds),
            ];
        });


        // Helper general
        $map = function ($q) {
    return $q->withPivot([
            'state','progress','start_date','end_date','target_amount','balance','payload'
        ])
        ->get([
            'challenges.id as challenge_id',
            'challenges.name',
            'challenges.description',
            'challenges.type',
            'challenges.duration_days',
            'challenges.reward_points',
        ])
        ->map(function ($ch) {
            $payload = [];
            if (is_string($ch->pivot->payload)) {
                $payload = json_decode($ch->pivot->payload, true) ?: [];
            } elseif (is_array($ch->pivot->payload)) {
                $payload = $ch->pivot->payload;
            }

            // 🪙 FORZAR actualización del símbolo y código de moneda del usuario
            $user = Auth::user();
            if ($user && $user->currency) {
                $payload['currency_symbol'] = $user->currency->symbol;
                $payload['currency_code'] = $user->currency->code;
            }

            return [
                'id'             => $ch->challenge_id,
                'name'           => $ch->name,
                'description'    => $ch->description,
                'type'           => $ch->type,
                'duration_days'  => (int) $ch->duration_days,
                'reward_points'  => (int) $ch->reward_points,
                'pivot' => [
                    'state'         => $ch->pivot->state,
                    'progress'      => $ch->pivot->progress,
                    'start_date'    => $ch->pivot->start_date,
                    'end_date'      => $ch->pivot->end_date,
                    'target_amount' => $ch->pivot->target_amount,
                    'balance'       => $ch->pivot->balance,
                    'payload'       => $payload,
                ],
            ];
        })
        ->values();
};


        // 🔎 Agrupar por estado (incluye failed)
        $inProgress = $map($user->challenges()->wherePivot('state', 'in_progress'));
        $completed  = $map($user->challenges()->wherePivot('state', 'completed'));
        $failed     = $map($user->challenges()->wherePivot('state', 'failed'));

        // 🪙 Añadir símbolo y código de moneda del usuario a cada desafío
        $currency = $user->currency;
        $symbol = $currency ? $currency->symbol : '$';
        $code   = $currency ? $currency->code : 'USD';

        foreach (['inProgress', 'completed', 'failed'] as $state) {
            foreach (${$state} as &$ch) {
                $ch['currency_symbol'] = $symbol;
                $ch['currency_code'] = $code;
            }
        }

        return response()->json([
            'user' => [
                'name'   => $user->name,
                'points' => $user->points,
                'level'  => $user->level,

                // 🔹 Avatar del usuario
                'avatar_seed' => $user->icon,
                'full_icon_url' => $user->icon && str_contains($user->icon, '/')
                    ? asset('storage/' . $user->icon)
                    : null,
            ],

            // 🔥 NUEVO: Datos de racha del usuario
            'streak' => [
                'current' => optional($user->streak)->current_streak ?? 0,
                'longest' => optional($user->streak)->longest_streak ?? 0,
                'last_activity' => optional($user->streak)->last_activity_date?->toIso8601String(),
            ],

            'badges' => $badges,

            'challenges' => [
                'in_progress' => $inProgress,
                'completed'   => $completed,
                'failed'      => $failed,
            ],
        ]);
    }
}
