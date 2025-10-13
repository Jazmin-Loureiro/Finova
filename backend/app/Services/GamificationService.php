<?php

namespace App\Services;

use App\Models\User;
use App\Models\Badge;
use App\Models\Challenge;

class GamificationService
{
    /**
     * Asigna puntos e insignias cuando el usuario completa un desafío.
     * Además, evalúa si sube de nivel automáticamente.
     */
    public function rewardUser(User $user, Challenge $challenge)
    {
        // 1️⃣ Sumar puntos al usuario
        $pointsEarned = $challenge->reward_points ?? 0;
        $user->points = ($user->points ?? 0) + $pointsEarned;

        // 2️⃣ Subida de nivel automática (cada 100 pts por nivel)
        $levelUpThreshold = 100; // 🔸 Podés ajustar el valor si querés que suba más rápido o más lento
        $initialLevel = $user->level ?? 1;

        // Mientras tenga puntos suficientes para el siguiente nivel, sube
        while ($user->points >= $levelUpThreshold * $user->level) {
            $user->level++;
        }

        $leveledUp = $user->level > $initialLevel;
        $user->save();

        // 3️⃣ Marcar SOLO el desafío en progreso como completado en la tabla pivote
$activePivot = \App\Models\UserChallenge::where('user_id', $user->id)
    ->where('challenge_id', $challenge->id)
    ->where('state', 'in_progress')   // ✅ solo el activo
    ->orderByDesc('id')               // por si hay duplicados
    ->first();

if ($activePivot) {
    $activePivot->update([
        'state'    => 'completed',
        'end_date' => now(),
        'progress' => 100,
    ]);
}


        // 4️⃣ Asignar insignia si el desafío tiene recompensa
        $badgeEarned = null;
        if ($challenge->reward_badge_id) {
            $badge = Badge::find($challenge->reward_badge_id);
            if ($badge && !$user->badges()->where('badge_id', $badge->id)->exists()) {
                $user->badges()->attach($badge->id);
                $badgeEarned = $badge;
            }
        }

        // 5️⃣ Retornar info para frontend (por si en el futuro querés mostrar animaciones o notificaciones)
        return [
            'points_earned' => $pointsEarned,
            'new_total_points' => $user->points,
            'leveled_up' => $leveledUp,
            'new_level' => $user->level,
            'badge_earned' => $badgeEarned ? $badgeEarned->only(['id', 'name', 'icon']) : null,
        ];
    }
}
