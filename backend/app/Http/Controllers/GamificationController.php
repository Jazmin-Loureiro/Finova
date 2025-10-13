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
    app(\App\Services\ChallengeProgressService::class)->recomputeForUserWithRewards($user);

    // 🏅 Insignias
    $badges = $user->badges()->get([
    'badges.id as badge_id',
    'badges.name',
    'badges.slug',
    'badges.icon',
    'badges.tier',
    'badges.description',
]);


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

    return response()->json([
        'user' => [
            'name'   => $user->name,
            'points' => $user->points,
            'level'  => $user->level,
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
