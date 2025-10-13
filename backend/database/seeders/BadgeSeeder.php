<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Badge;

class BadgeSeeder extends Seeder
{
    public function run(): void
    {
        Badge::firstOrCreate(['slug' => 'first_challenge', 'tier' => 0], [
            'name' => 'Primer desafío',
            'description' => 'Completá tu primer desafío financiero',
        ]);

        Badge::firstOrCreate(['slug' => 'saver_bronze', 'tier' => 1], [
            'name' => 'Ahorrista Bronce',
            'description' => 'Alcanzaste 200 puntos en Finova',
        ]);

        Badge::firstOrCreate(['slug' => 'saver_silver', 'tier' => 2], [
            'name' => 'Ahorrista Plata',
            'description' => 'Alcanzaste 500 puntos en Finova',
        ]);

        Badge::firstOrCreate(['slug' => 'saver_gold', 'tier' => 3], [
            'name' => 'Ahorrista Oro',
            'description' => 'Alcanzaste 1000 puntos en Finova',
        ]);
    }
}
