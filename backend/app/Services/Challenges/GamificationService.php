<?php

namespace App\Services\Challenges;

use App\Models\User;
use App\Models\Badge;
use App\Models\Challenge;
use App\Models\UserChallenge;

class GamificationService
{
    /**
     * Asigna puntos e insignias cuando el usuario completa un desafío.
     * Ahora también devuelve insignias automáticas desbloqueadas.
     */
    public function rewardUser(User $user, Challenge $challenge)
    {
        // 1️⃣ Sumar puntos al usuario
        $pointsEarned = $challenge->reward_points ?? 0;
        $user->points = ($user->points ?? 0) + $pointsEarned;

        // 2️⃣ Subida de nivel con curva progresiva
        $baseThreshold = 150;
        $growthFactor  = 1.5;

        $initialLevel  = $user->level ?? 1;
        $currentLevel  = $initialLevel;
        $totalPoints   = $user->points ?? 0;

        while (true) {
            $required = (int) round($baseThreshold * pow($growthFactor, $currentLevel - 1));
            if ($totalPoints >= $required) {
                $totalPoints -= $required;
                $currentLevel++;
            } else {
                break;
            }
        }

        $user->points = $totalPoints;
        $user->level  = $currentLevel;
        $leveledUp    = $currentLevel > $initialLevel;
        $user->save();

        // 3️⃣ Marcar pivot como completado
        $activePivot = UserChallenge::where('user_id', $user->id)
            ->where('challenge_id', $challenge->id)
            ->where('state', 'in_progress')
            ->orderByDesc('id')
            ->first();

        if ($activePivot) {
            $activePivot->update([
                'state'    => 'completed',
                'progress' => 100,
                'end_date' => now(),
            ]);
        }

        // ============================================================
        // 4️⃣ INSIGNIAS POR EVENTO (las que vienen en el desafío)
        // ============================================================

        $eventBadge = null;

        if ($challenge->reward_badge_id) {
            $badge = Badge::find($challenge->reward_badge_id);

            if ($badge && !$user->badges()->where('badge_id', $badge->id)->exists()) {
                $user->badges()->attach($badge->id);
                $eventBadge = $badge;
            }
        }

        // ============================================================
        // 5️⃣ INSIGNIAS AUTOMÁTICAS (acumulativas)
        // ============================================================

        $autoBadge = $this->evaluateProgressBadges($user);

        // ============================================================
        // 6️⃣ Devolver recompensa con la insignia que corresponda
        // ============================================================

        $badgeToReturn = null;

        if ($autoBadge) {
            $badgeToReturn = $autoBadge->only(['id', 'name', 'icon']);
        } elseif ($eventBadge) {
            $badgeToReturn = $eventBadge->only(['id', 'name', 'icon']);
        }

        return [
            'points_earned'    => $pointsEarned,
            'new_total_points' => $totalPoints,
            'leveled_up'       => $leveledUp,
            'new_level'        => $currentLevel,
            'badge_earned'     => $badgeToReturn, // ESTA ES LA CLAVE PARA EL FRONT
        ];
    }

    /**
     * Evalúa y asigna insignias por progreso global (acumulativo).
     * 🔥 AHORA devuelve la insignia recién desbloqueada si corresponde.
     */
    private function evaluateProgressBadges(User $user)
    {
        // 👉 Solo devolver UNA por vez (la primera que desbloquee en el orden)
        // para evitar devolver varias en una sola pantalla.
        
        // 1️⃣ Primer desafío completado
        $completedCount = $user->challenges()
            ->wherePivot('state', 'completed')
            ->count();

        $badge = $this->assignBadgeIfNotExists($user, 'first_challenge');
        if ($completedCount === 1 && $badge) {
            return $badge;
        }

        // 2️⃣ Por puntos acumulados
        $points = $user->points ?? 0;
        $tiers = [
            'saver_bronze' => 500,
            'saver_silver' => 1200,
            'saver_gold'   => 2500,
        ];

        foreach ($tiers as $slug => $threshold) {
            if ($points >= $threshold) {
                $badge = $this->assignBadgeIfNotExists($user, $slug);
                if ($badge) return $badge;
            }
        }

        // 3️⃣ Completó 10 desafíos
        if ($completedCount >= 10) {
            $badge = $this->assignBadgeIfNotExists($user, 'ten_challenges');
            if ($badge) return $badge;
        }

        // 4️⃣ 5 desafíos de ahorro
        $saverChallenges = $user->challenges()
            ->where('type', 'SAVE_AMOUNT')
            ->wherePivot('state', 'completed')
            ->count();

        if ($saverChallenges >= 5) {
            $badge = $this->assignBadgeIfNotExists($user, 'saver_master');
            if ($badge) return $badge;
        }

        // 5️⃣ 3 desafíos de gasto sin fallar
        $spendChallenges = $user->challenges()
            ->where('type', 'REDUCE_SPENDING_PERCENT')
            ->get();

        $completedSpenders = $spendChallenges->where('pivot.state', 'completed')->count();
        $failedSpenders    = $spendChallenges->where('pivot.state', 'failed')->count();

        if ($completedSpenders >= 3 && $failedSpenders === 0) {
            $badge = $this->assignBadgeIfNotExists($user, 'spender_control');
            if ($badge) return $badge;
        }

        // 6️⃣ Completó al menos un desafío de cada tipo (SAVE + SPEND)
        $hasSave = $user->challenges()
            ->where('type', 'SAVE_AMOUNT')
            ->wherePivot('state', 'completed')
            ->exists();

        $hasSpend = $user->challenges()
            ->where('type', 'REDUCE_SPENDING_PERCENT')
            ->wherePivot('state', 'completed')
            ->exists();

        if ($hasSave && $hasSpend) {
            $badge = $this->assignBadgeIfNotExists($user, 'goal_creator');
            if ($badge) return $badge;
        }

        // 7️⃣ 3 desafíos seguidos completados
        if ($completedCount >= 3 && $failedSpenders === 0) {
            $badge = $this->assignBadgeIfNotExists($user, 'success_streak');
            if ($badge) return $badge;
        }

        // 8️⃣ Racha semanal y mensual usando streak
        $days = optional($user->streak)->current_streak ?? 0;

        if ($days >= 7) {
            $badge = $this->assignBadgeIfNotExists($user, 'weekly_streak');
            if ($badge) return $badge;
        }

        if ($days >= 30) {
            $badge = $this->assignBadgeIfNotExists($user, 'monthly_streak');
            if ($badge) return $badge;
        }

        return null;
    }

    /**
     * Asigna una insignia si no existía.
     * 🔥 AHORA devuelve la insignia recién asignada.
     */
    private function assignBadgeIfNotExists(User $user, string $slug)
    {
        $badge = Badge::where('slug', $slug)->first();

        if ($badge && !$user->badges()->where('badge_id', $badge->id)->exists()) {
            $user->badges()->attach($badge->id);
            return $badge;  // 👉 DEVUELVE LA INSIGNIA GANADA
        }

        return null;
    }
}
