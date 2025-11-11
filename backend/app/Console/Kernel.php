<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define el schedule (tareas automáticas)
     */
    protected function schedule(Schedule $schedule)
    {
        /**
         * 💸 Actualizaciones diarias
         * (tasas de préstamo, plazos fijos, UVA)
         * -> todos los días a las 08:00
         */
        $schedule->command('dataapi:refresh --group=daily')
            ->dailyAt('08:00')
            ->runInBackground()
            ->withoutOverlapping();

        /**
         * 💱 Actualizaciones frecuentes
         * (divisas, cripto)
         * -> cada 3 horas
         */
        $schedule->command('dataapi:refresh --group=frequent')
            ->everyThreeHours()
            ->runInBackground()
            ->withoutOverlapping();

        /**
         * 📊 Actualizaciones semanales
         * (indicadores macroeconómicos)
         * -> todos los lunes a las 07:30
         */
        $schedule->command('dataapi:refresh --group=weekly')
            ->weeklyOn(1, '07:30')
            ->runInBackground()
            ->withoutOverlapping();
            
        /** 
         * Actualización de tasas de cambio
         * Ejecuta cada 12 horas (a las 00:00 y 12:00) 
        */
        $schedule->command('currencies:update')->everyTwoHours();
        /**
         * Actualización de metas vencidas
         * -> todos los días a las 00:00 AM
         */
        $schedule->command('goals:update-expired')
            ->dailyAt('00:00')
            ->runInBackground()
            ->withoutOverlapping();

        /**
         * 🏆 Actualización automática de desafíos
         * Recalcula progreso y marca vencidos o completados.
         */

        // 🔹 Recalcular progreso general cada hora
        $schedule->command('challenges:tick')
            ->hourly()
            ->runInBackground()
            ->withoutOverlapping();

        // 🔹 Revisión liviana (solo vencidos) una vez al día
        $schedule->command('challenges:tick --expired-only')
            ->dailyAt('00:30')
            ->runInBackground()
            ->withoutOverlapping();

    }

    /**
     * Registra los comandos en app/Console/Commands
     */
    protected function commands()
    {
        $this->load(__DIR__.'/Commands');
        require base_path('routes/console.php');
    }
}
