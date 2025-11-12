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
     * Incluye insignias de evento y de progreso acumulativo.
     */
    public function rewardUser(User $user, Challenge $challenge)
    {
        // 1️⃣ Sumar puntos al usuario
        $pointsEarned = $challenge->reward_points ?? 0;
        $user->points = ($user->points ?? 0) + $pointsEarned;

        // 2️⃣ Subida de nivel automática con curva progresiva
        $baseThreshold = 150; // puntos base para pasar de nivel 1 a 2
        $growthFactor  = 1.5; // cada nivel requiere 50% más puntos que el anterior

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
        $leveledUp    = $user->level > $initialLevel;
        $user->save();

        // 3️⃣ Marcar SOLO el desafío en progreso como completado en la tabla pivote
        $activePivot = UserChallenge::where('user_id', $user->id)
            ->where('challenge_id', $challenge->id)
            ->where('state', 'in_progress')
            ->orderByDesc('id')
            ->first();

        if ($activePivot) {
            $activePivot->update([
                'state'    => 'completed',
                'end_date' => now(),
                'progress' => 100,
            ]);
        }

        // 4️⃣ Asignar insignia por desafío específico (evento)
        $badgeEarned = null;
        if ($challenge->reward_badge_id) {
            $badge = Badge::find($challenge->reward_badge_id);
            if ($badge && !$user->badges()->where('badge_id', $badge->id)->exists()) {
                $user->badges()->attach($badge->id);
                $badgeEarned = $badge;
            }
        }

        // 6️⃣ Evaluar insignias automáticas (primer desafío + puntos)
        $this->evaluateProgressBadges($user);

        return [
            'points_earned'      => $pointsEarned,
            'new_total_points'   => $user->points,
            'leveled_up'         => $leveledUp,
            'new_level'          => $user->level,
            'badge_earned'       => $badgeEarned ? $badgeEarned->only(['id', 'name', 'icon']) : null,
        ];
    }

    /**
     * Evalúa y asigna insignias por progreso global (acumulativo).
     */
    private function evaluateProgressBadges(User $user): void
    {
        // 🏅 1) Primer desafío completado
        $completedCount = $user->challenges()
            ->wherePivot('state', 'completed')
            ->count();

        if ($completedCount === 1) {
            $this->assignBadgeIfNotExists($user, 'first_challenge');
        }

        // 💰 2) Por puntos totales
        $points = $user->points ?? 0;
        $tiers = [
            'saver_bronze' => 500,
            'saver_silver' => 1200,
            'saver_gold'   => 2500,
        ];

        foreach ($tiers as $slug => $threshold) {
            if ($points >= $threshold) {
                $this->assignBadgeIfNotExists($user, $slug);
            }
        }

        // ⚡ 3) Desafiante — 10 desafíos completados
        if ($completedCount >= 10) {
            $this->assignBadgeIfNotExists($user, 'ten_challenges');
        }

        // 🐷 4) Ahorrista Experto — 5 desafíos de tipo ahorro
        $saverChallenges = $user->challenges()
            ->where('type', 'SAVE_AMOUNT')
            ->wherePivot('state', 'completed')
            ->count();

        if ($saverChallenges >= 5) {
            $this->assignBadgeIfNotExists($user, 'saver_master');
        }

        // 📉 5) Controlador de Gastos — 3 desafíos de gasto sin fallar
        $spendChallenges = $user->challenges()
            ->where('type', 'REDUCE_SPENDING_PERCENT')
            ->get();

        $completedSpenders = $spendChallenges->where('pivot.state', 'completed')->count();
        $failedSpenders = $spendChallenges->where('pivot.state', 'failed')->count();

        if ($completedSpenders >= 3 && $failedSpenders === 0) {
            $this->assignBadgeIfNotExists($user, 'spender_control');
        }

        // 🧭 6) Planificador Financiero — completó al menos un desafío de cada tipo
        $hasSave = $user->challenges()
            ->where('type', 'SAVE_AMOUNT')
            ->wherePivot('state', 'completed')
            ->exists();

        $hasSpend = $user->challenges()
            ->where('type', 'REDUCE_SPENDING_PERCENT')
            ->wherePivot('state', 'completed')
            ->exists();

        if ($hasSave && $hasSpend) {
            $this->assignBadgeIfNotExists($user, 'goal_creator');
        }

        // 🔁 7) Racha de Éxitos — completó 3 desafíos seguidos sin fallar
        $completed = $user->challenges()->wherePivot('state', 'completed')->count();
        $failed = $user->challenges()->wherePivot('state', 'failed')->count();

        if ($completed >= 3 && $failed === 0) {
            $this->assignBadgeIfNotExists($user, 'success_streak');
        }

        // 🔥 8) Constancia Total — completó desafíos 7 días seguidos
        $recentCompletions = $user->challenges()
            ->wherePivot('state', 'completed')
            ->wherePivot('end_date', '>=', now()->subDays(7))
            ->count();

        if ($recentCompletions >= 7) {
            $this->assignBadgeIfNotExists($user, 'super_streak');
        }
    }

    /**
     * Asigna una insignia si el usuario aún no la tiene.
     */
    private function assignBadgeIfNotExists(User $user, string $slug): void
    {
        $badge = \App\Models\Badge::where('slug', $slug)->first();
        if ($badge && !$user->badges()->where('badge_id', $badge->id)->exists()) {
            $user->badges()->attach($badge->id);
        }
    }


}
