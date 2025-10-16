<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Mission;

class MissionSeeder extends Seeder
{
    public function run(): void
    {
        Mission::firstOrCreate(
            ['period' => 'daily', 'name' => 'Registrar 2 movimientos diarios'],
            [
                'type' => 'ADD_TRANSACTIONS',
                'description' => 'Registrá al menos 2 movimientos hoy.',
                'payload' => ['count' => 2],
                'reward_points' => 10,
                'active' => true,
            ]
        );

        Mission::firstOrCreate(
            ['period' => 'weekly', 'name' => 'Registrar 5 movimientos semanales'],
            [
                'type' => 'ADD_TRANSACTIONS',
                'description' => 'Registrá al menos 5 movimientos esta semana.',
                'payload' => ['count' => 5],
                'reward_points' => 30,
                'active' => true,
            ]
        );
    }
}
