<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\UserChallenge;
use App\Services\Challenges\ChallengeProgressService;

class TickChallenges extends Command
{
    protected $signature = 'challenges:tick {--user_id=} {--expired-only}';
    protected $description = 'Recalcula desafíos en progreso y marca automáticamente los vencidos o completados.';

    public function handle(): int
    {
        $expiredOnly = $this->option('expired-only');
        $userId      = $this->option('user_id');

        $query = UserChallenge::with(['user', 'challenge'])
            ->where('state', 'in_progress');

        if ($userId) {
            $query->where('user_id', $userId);
        }

        // Si es modo "solo vencidos"
        if ($expiredOnly) {
            $query->whereNotNull('end_date')
                  ->where('end_date', '<', now());
        }

        $count = $query->count();
        if ($count === 0) {
            $this->info('✅ No hay desafíos pendientes de revisión.');
            return self::SUCCESS;
        }

        $this->info("🔍 Procesando {$count} desafíos...");
        $bar = $this->output->createProgressBar($count);
        $bar->start();

        /** @var ChallengeProgressService $service */
        $service = app(ChallengeProgressService::class);

        $query->chunkById(200, function ($pivots) use ($service, $bar) {
            foreach ($pivots as $pivot) {
                try {
                    $service->recomputeSingle($pivot->user, $pivot->challenge_id);
                } catch (\Throwable $e) {
                    \Log::warning("⚠️ Error en challenge {$pivot->id}: " . $e->getMessage());
                }
                $bar->advance();
                usleep(20000); // 20 ms entre iteraciones
            }
        });

        $bar->finish();
        $this->newLine(2);
        $this->info("✅ Revisión completada correctamente.");

        return self::SUCCESS;
    }
}
