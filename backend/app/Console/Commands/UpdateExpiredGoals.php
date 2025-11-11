<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Goal;

class UpdateExpiredGoals extends Command
{
    protected $signature = 'goals:update-expired';
    protected $description = 'Actualizar el estado de las metas vencidas y enviar notificaciones';

    public function handle() {
        // Actualizar metas vencidas
        $expiredGoals = Goal::where('date_limit', '<', now())
        ->whereColumn('balance', '<', 'target_amount')
        ->whereIn('state', ['in_progress']) //solo metas activas
        ->get();

        foreach ($expiredGoals as $goal) {
            $goal->disableGoal();
        }
        $this->info('Metas vencidas actualizadas correctamente.');
    }
}
