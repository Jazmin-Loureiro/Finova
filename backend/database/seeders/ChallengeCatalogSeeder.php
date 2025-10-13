<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Challenge;

class ChallengeCatalogSeeder extends Seeder
{
    public function run(): void
    {
        // ⚠️ IMPORTANTE:
        // En tu esquema actual "type" es enum con estos valores:
        // SAVE_AMOUNT, REDUCE_SPENDING_PERCENT, ADD_TRANSACTIONS
        // Usamos esos EXACTOS para no romper el enum.

        // 1) Ahorrar dinero (SAVE_AMOUNT)
        Challenge::updateOrCreate(
            ['type' => 'SAVE_AMOUNT'],
            [
                'name'           => 'Ahorrá dinero',
                'description'    => 'Lográ ahorrar una meta personalizada en los próximos días.',
                'active'         => true,
                // Valores base del catálogo (genéricos / por defecto)
                'payload'        => null,         // la personalización vive en users_challenges
                'target_amount'  => null,         // idem
                'duration_days'  => 30,
                'reward_points'  => 100,
                'reward_badge_id'=> null,         // si luego querés, lo seteás
            ]
        );

        // 2) Reducir gastos (REDUCE_SPENDING_PERCENT)
        Challenge::updateOrCreate(
            ['type' => 'REDUCE_SPENDING_PERCENT'],
            [
                'name'           => 'Reducí tus gastos',
                'description'    => 'Gastá menos que el periodo anterior.',
                'active'         => true,
                'payload'        => null,         // p.ej. {"percent":20} vive en el pivot
                'target_amount'  => null,         // la meta concreta se calcula por usuario
                'duration_days'  => 30,
                'reward_points'  => 80,
                'reward_badge_id'=> null,
            ]
        );

        // 3) Registrar movimientos (ADD_TRANSACTIONS)
        Challenge::updateOrCreate(
            ['type' => 'ADD_TRANSACTIONS'],
            [
                'name'           => 'Registrá tus movimientos',
                'description'    => 'Anotá tus ingresos y gastos para mejorar tu control.',
                'active'         => true,
                'payload'        => null,         // p.ej. {"count":12} en el pivot
                'target_amount'  => null,         // el count final se calcula por usuario
                'duration_days'  => 7,
                'reward_points'  => 60,
                'reward_badge_id'=> null,
            ]
        );
    }
}
