<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Challenge;
use App\Models\UserChallenge;
use Carbon\Carbon;
use Illuminate\Support\Str;

class ChallengeProgressDemoSeeder extends Seeder
{
    public function run()
    {
        // 1) Obtener o crear usuario de prueba (primer usuario)
        $user = User::first();
        if (!$user) {
            $user = User::factory()->create([
                'name' => 'Tester',
                'email' => 'tester@example.com',
                'password' => bcrypt('secret'),
                'points' => 0,
                'level' => 1,
            ]);
            $this->command->info("Usuario de prueba creado: {$user->email} / password: secret");
        } else {
            $this->command->info("Usando usuario existente: {$user->email}");
        }

        // 2) Asegurarnos que existan los desafíos base (by type)
        $types = [
            'SAVE_AMOUNT' => ['name' => 'Ahorra monto', 'description' => 'Ahorra un monto determinado.'],
            'ADD_TRANSACTIONS' => ['name' => 'Agregar movimientos', 'description' => 'Registra movimientos.'],
            'REDUCE_SPENDING_PERCENT' => ['name' => 'Reducir gastos', 'description' => 'Reduce tus gastos.'],
        ];

        foreach ($types as $type => $meta) {
            $c = Challenge::where('type', $type)->first();
            if (!$c) {
                $c = Challenge::create([
                    'type' => $type,
                    'name' => $meta['name'],
                    'description' => $meta['description'],
                    'duration_days' => 30,
                    'reward_points' => ($type === 'SAVE_AMOUNT') ? 100 : (($type === 'ADD_TRANSACTIONS') ? 60 : 80),
                    'active' => true,
                ]);
                $this->command->info("Challenge base creado: {$type} (id {$c->id})");
            } else {
                $this->command->info("Challenge base existente: {$type} (id {$c->id})");
            }
        }

        // Helper fecha ahora
        $now = Carbon::now();

        // 3) Crear varios UserChallenge para probar estados/fallas/completos
        // --- SAVE_AMOUNT (id dinámico)
        $saveBase = Challenge::where('type', 'SAVE_AMOUNT')->first();

        // a) SAVE_AMOUNT: vencido (end_date pasado), progress < 100 -> debe considerarse FAIL
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $saveBase->id,
            'state'         => 'in_progress',
            'progress'      => 40.0,
            'balance'       => $user->balance ?? 0,
            'start_date'    => $now->copy()->subDays(10),
            'end_date'      => $now->copy()->subDays(3), // expirado
            'target_amount' => 1000,
            'payload'       => json_encode(['amount' => 1000, 'duration_days' => 7]),
        ]);

        // b) SAVE_AMOUNT: en progreso vigente (no venció)
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $saveBase->id,
            'state'         => 'in_progress',
            'progress'      => 20.0,
            'balance'       => $user->balance ?? 0,
            'start_date'    => $now->copy()->subDays(1),
            'end_date'      => $now->copy()->addDays(6),
            'target_amount' => 500,
            'payload'       => json_encode(['amount' => 500, 'duration_days' => 7]),
        ]);

        // c) SAVE_AMOUNT: completed (ya completado, para ver la recompensa)
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $saveBase->id,
            'state'         => 'completed',
            'progress'      => 100.0,
            'balance'       => $user->balance ?? 0,
            'start_date'    => $now->copy()->subDays(12),
            'end_date'      => $now->copy()->subDays(5),
            'target_amount' => 200,
            'payload'       => json_encode(['amount' => 200, 'duration_days' => 7]),
        ]);

        // --- ADD_TRANSACTIONS
        $addBase = Challenge::where('type', 'ADD_TRANSACTIONS')->first();

        // d) ADD_TRANSACTIONS: vencido sin completar -> FAIL esperado
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $addBase->id,
            'state'         => 'in_progress',
            'progress'      => 60.0,
            'start_date'    => $now->copy()->subDays(10),
            'end_date'      => $now->copy()->subDays(2),
            'target_amount' => 10,
            'payload'       => json_encode(['count' => 10, 'duration_days' => 7]),
        ]);

        // e) ADD_TRANSACTIONS: completado por progreso 100
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $addBase->id,
            'state'         => 'in_progress',
            'progress'      => 100.0,
            'start_date'    => $now->copy()->subDays(4),
            'end_date'      => $now->copy()->addDays(3),
            'target_amount' => 5,
            'payload'       => json_encode(['count' => 5, 'duration_days' => 7]),
        ]);

        // --- REDUCE_SPENDING_PERCENT
        $redBase = Challenge::where('type', 'REDUCE_SPENDING_PERCENT')->first();

        // f) REDUCE: vencido y superó límite (current_spent > baseline) -> FAIL
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $redBase->id,
            'state'         => 'in_progress',
            'progress'      => 99.0,
            'start_date'    => $now->copy()->subDays(8),
            'end_date'      => $now->copy()->subDays(1),
            'target_amount' => 3000,
            'payload'       => json_encode([
                'mode' => 'weekly',
                'window_days' => 7,
                'baseline_expenses' => 1000,
                'max_allowed' => 1000,
                'current_spent' => 1200,
                'period_start' => $now->copy()->subDays(8)->toIso8601String(),
                'duration_days' => 7,
            ]),
        ]);

        // g) REDUCE: en progreso y por debajo del límite (vigente)
        UserChallenge::create([
            'user_id'       => $user->id,
            'challenge_id'  => $redBase->id,
            'state'         => 'in_progress',
            'progress'      => 20.0,
            'start_date'    => $now->copy()->subDays(1),
            'end_date'      => $now->copy()->addDays(6),
            'target_amount' => 1500,
            'payload'       => json_encode([
                'mode' => 'weekly',
                'window_days' => 7,
                'baseline_expenses' => 1500,
                'max_allowed' => 1500,
                'current_spent' => 200,
                'period_start' => $now->copy()->subDays(1)->toIso8601String(),
                'duration_days' => 7,
            ]),
        ]);

        // --- Suggested examples (no empiezan)
        UserChallenge::create([
            'user_id' => $user->id,
            'challenge_id' => $saveBase->id,
            'state' => 'suggested',
            'progress' => 0,
            'payload' => json_encode(['amount' => 478, 'duration_days' => 14]),
            'target_amount' => 478,
        ]);

        UserChallenge::create([
            'user_id' => $user->id,
            'challenge_id' => $addBase->id,
            'state' => 'suggested',
            'progress' => 0,
            'payload' => json_encode(['count' => 7]),
            'target_amount' => 7,
        ]);

        UserChallenge::create([
            'user_id' => $user->id,
            'challenge_id' => $redBase->id,
            'state' => 'suggested',
            'progress' => 0,
            'payload' => json_encode(['mode' => 'weekly', 'max_allowed' => 182, 'window_days' => 7, 'current_spent' => 0]),
            'target_amount' => 182,
        ]);

        $this->command->info("Seeder ChallengeTestSeeder terminado. Recomendado: correr el comando para marcar failures y luego recompute.");
    }
}
