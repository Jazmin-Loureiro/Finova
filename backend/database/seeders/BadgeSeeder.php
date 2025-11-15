<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Badge;

class BadgeSeeder extends Seeder
{
    public function run(): void
    {
        // 🏆 Primer desafío
        Badge::firstOrCreate(['slug' => 'first_challenge', 'tier' => 0], [
            'name' => 'Primer desafío',
            'description' => 'Completá tu primer desafío financiero',
            'icon' => 'lucide:trophy',
        ]);

        // 💰 Ahorrista (por puntos)
        Badge::firstOrCreate(['slug' => 'saver_bronze', 'tier' => 1], [
            'name' => 'Ahorrista Bronce',
            'description' => 'Alcanzaste 500 puntos en Finova',
            'icon' => 'lucide:medal',
        ]);

        Badge::firstOrCreate(['slug' => 'saver_silver', 'tier' => 2], [
            'name' => 'Ahorrista Plata',
            'description' => 'Alcanzaste 1200 puntos en Finova',
            'icon' => 'lucide:crown',
        ]);

        Badge::firstOrCreate(['slug' => 'saver_gold', 'tier' => 3], [
            'name' => 'Ahorrista Oro',
            'description' => 'Alcanzaste 2500 puntos en Finova',
            'icon' => 'lucide:award',
        ]);

        // ⚡ Desafiante — 10 desafíos completados
        Badge::firstOrCreate(['slug' => 'ten_challenges', 'tier' => 0], [
            'name' => 'Desafiante',
            'description' => 'Completaste 10 desafíos financieros',
            'icon' => 'lucide:zap',
        ]);

        // 🐷 Ahorrista Experto — 5 desafíos de ahorro
        Badge::firstOrCreate(['slug' => 'saver_master', 'tier' => 2], [
            'name' => 'Ahorrista Experto',
            'description' => 'Completaste 5 desafíos de tipo ahorro',
            'icon' => 'lucide:piggy-bank',
        ]);

        // 📉 Controlador de Gastos — 3 desafíos de gasto sin fallar
        Badge::firstOrCreate(['slug' => 'spender_control', 'tier' => 2], [
            'name' => 'Controlador de Gastos',
            'description' => 'Superaste 3 desafíos de reducción de gastos sin fallar ninguno',
            'icon' => 'lucide:chart-line',
        ]);

        // 🧭 Planificador Financiero — un desafío de cada tipo
        Badge::firstOrCreate(['slug' => 'goal_creator', 'tier' => 1], [
            'name' => 'Planificador Financiero',
            'description' => 'Completaste al menos un desafío de cada tipo',
            'icon' => 'lucide:calendar-check',
        ]);

        // 🔁 Racha de Éxitos — 3 desafíos seguidos sin fallar
        Badge::firstOrCreate(['slug' => 'success_streak', 'tier' => 1], [
            'name' => 'Racha de Éxitos',
            'description' => 'Completaste 3 desafíos seguidos sin fallar ninguno',
            'icon' => 'lucide:repeat',
        ]);

        // 🔥 Constancia Total — 7 días seguidos con desafíos
        Badge::firstOrCreate(['slug' => 'super_streak', 'tier' => 3], [
            'name' => 'Constancia Total',
            'description' => 'Completaste desafíos durante 7 días seguidos',
            'icon' => 'lucide:flame',
        ]);

        // 📅 Racha Semanal — 7 días consecutivos con actividad diaria
        Badge::firstOrCreate(['slug' => 'weekly_streak', 'tier' => 2], [
            'name' => 'Racha Semanal',
            'description' => 'Completaste al menos un desafío por día durante 7 días consecutivos.',
            'icon' => 'lucide:calendar-days',
        ]);

        // 📆 Racha Mensual — 30 días seguidos
        Badge::firstOrCreate(['slug' => 'monthly_streak', 'tier' => 3], [
            'name' => 'Racha Mensual',
            'description' => 'Mantené tu constancia durante 30 días seguidos completando desafíos.',
            'icon' => 'lucide:calendar-range',
        ]);
    }
}
