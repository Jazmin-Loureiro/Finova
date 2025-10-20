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

        // 2️⃣ Subida de nivel automática con curva progresiva
        $baseThreshold = 150; // puntos base para pasar de nivel 1 a 2
        $growthFactor = 1.5;  // cada nivel requiere 50% más puntos que el anterior

        $initialLevel = $user->level ?? 1;
        $currentLevel = $initialLevel;
        $totalPoints = $user->points ?? 0;

        // Bucle que permite subir varios niveles si tiene muchos puntos
        while (true) {
            // Calculamos cuántos puntos requiere el nivel actual → siguiente
            $required = (int) round($baseThreshold * pow($growthFactor, $currentLevel - 1));

            if ($totalPoints >= $required) {
                $totalPoints -= $required; // opcional: se “gasta” para subir de nivel
                $currentLevel++;
            } else {
                break;
            }
        }

        $user->points = $totalPoints;
        $user->level = $currentLevel;
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
