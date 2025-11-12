<?php

namespace App\Services\Challenges;

use App\Models\User;
use App\Models\UserStreak;
use Carbon\Carbon;

class StreakService
{
    /**
     * Registra actividad "diaria" del usuario.
     * Cuenta a lo sumo una vez por día.
     */
    public function recordActivity(User $user, ?Carbon $when = null): UserStreak
    {
        $when = $when ?: now();

        // buscamos (o creamos) la fila de streak
        $streak = $user->streak()->first();
        if (!$streak) {
            $streak = new UserStreak([
                'current_streak'    => 0,
                'longest_streak'    => 0,
                'last_activity_date'=> null,
            ]);
            $streak->user()->associate($user);
        }

        // Normalizamos a día (sin hora) para comparar sólo fechas
        $today = $when->copy()->startOfDay();
        $last  = $streak->last_activity_date ? $streak->last_activity_date->copy()->startOfDay() : null;

        // Si ya registramos actividad hoy, no sumamos (pero actualizamos last_activity)
        if ($last && $last->equalTo($today)) {
            $streak->last_activity_date = $when;
            $streak->save();
            return $streak;
        }

        // Si la última actividad fue AYER => +1 a la racha
        if ($last && $last->diffInDays($today) === 1) {
            $streak->current_streak += 1;
        } else {
            // Si no hubo ayer (fue antes o nunca) => se reinicia a 1
            $streak->current_streak = 1;
        }

        // Actualizar récord
        if ($streak->current_streak > ($streak->longest_streak ?? 0)) {
            $streak->longest_streak = $streak->current_streak;
        }

        $streak->last_activity_date = $when;
        $streak->save();

        return $streak;
    }
}
