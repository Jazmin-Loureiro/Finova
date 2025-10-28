<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\DataApi\CacheService;
use App\Services\DataApi\BcraService;
use App\Services\DataApi\InvestmentService;

class RefreshDataApiCommand extends Command
{
    protected $signature = 'dataapi:refresh {--group=all : Grupo de datos a refrescar (daily|frequent|weekly|all)}';
    protected $description = 'Actualiza los datos de APIs externas (BCRA, inversiones, cotizaciones, cripto, indicadores) y genera snapshots históricos.';

    protected CacheService $cache;
    protected BcraService $bcra;
    protected InvestmentService $investment;

    public function __construct(CacheService $cache, BcraService $bcra, InvestmentService $investment)
    {
        parent::__construct();
        $this->cache = $cache;
        $this->bcra = $bcra;
        $this->investment = $investment;
    }

    public function handle()
    {
        $group = $this->option('group');
        $this->info("🚀 Iniciando actualización del grupo: {$group}");

        match ($group) {
            'daily'    => $this->refreshDaily(),
            'frequent' => $this->refreshFrequent(),
            'weekly'   => $this->refreshWeekly(),
            default    => $this->refreshAll(),
        };

        $this->info("✅ Actualización finalizada para el grupo: {$group}");
        return Command::SUCCESS;
    }

    /**
     * 🔹 Grupo diario: tasas, inversiones simples y comparativas
     */
    protected function refreshDaily()
    {
        // Tasas base del BCRA
        $this->updateBcraRate('tasa_prestamos_personales', '/tasa_prestamos_personales');
        $this->updateBcraRate('tasa_plazo_fijo', '/tasa_depositos_30_dias');
        $this->updateBcraRate('tasa_uva', '/uva');

        // Simulaciones de inversión
        $this->updateInvestment('sim_prestamo_personal', fn() => $this->investment->simulatePlazoFijo(), 'prestamo');
        $this->updateInvestment('sim_plazo_fijo', fn() => $this->investment->simulatePlazoFijo(), 'inversion');
        $this->updateInvestment('sim_ahorro_dolar', fn() => $this->investment->simulateAhorroDolar(), 'inversion');
        $this->updateInvestment('comparativa_pf_inflacion', fn() => $this->investment->comparePlazoFijoVsInflacion(), 'inversion');
    }

    /**
     * 🔹 Grupo frecuente: divisas y cripto (por ahora pendiente)
     */
    protected function refreshFrequent()
    {
        $this->warn("💱 Aún no se han definido servicios de divisas/cripto.");

    // Llamamos a el comando existente para actualizar las monedas
    $this->call('currencies:update');
    $this->line("✅ Tasas de cambio actualizadas correctamente (grupo: frequent).");

    }

    /**
     * 🔹 Grupo semanal: indicadores macroeconómicos
     */
    protected function refreshWeekly()
    {
        $this->info("📊 Actualizando indicadores semanales del BCRA...");

        $this->updateBcraRate('inflacion_interanual', '/inflacion_interanual_oficial');
        $this->updateBcraRate('reservas_internacionales', '/reservas');
        $this->updateBcraRate('merval', '/merval');

        $this->line("✅ Indicadores semanales actualizados correctamente.");
    }

    protected function refreshAll()
    {
        $this->refreshDaily();
        $this->refreshFrequent();
        $this->refreshWeekly();
    }

    /**
     * 🔸 Actualiza un valor base del BCRA (tasas, indicadores, etc.)
     */
    protected function updateBcraRate(string $name, string $endpoint)
    {
        $this->info("→ Actualizando {$name} ...");

        // 🔹 Detectamos tipo automáticamente
        $type = match (true) {
            str_contains($name, 'prestamo') => 'prestamo',
            str_contains($name, 'plazo_fijo') || str_contains($name, 'uva') => 'tasa',
            str_contains($name, 'inflacion') || str_contains($name, 'merval') || str_contains($name, 'reservas') => 'indicador',
            default => 'general',
        };

        $record = $this->cache->rememberOrRefresh($name, $type, 24, function () use ($endpoint) {
            $balance = match ($endpoint) {
                '/tasa_prestamos_personales' => $this->bcra->getLoanRate(),
                '/tasa_depositos_30_dias'    => $this->bcra->getPlazoFijoRate(),
                '/uva'                       => $this->bcra->getUvaValue(),
                default                      => $this->bcra->getIndicator(ltrim($endpoint, '/')),
            };

            // 🔹 Manejo de token expirado
            if ($balance === 'token_expired') {
                return [
                    'balance' => null,
                    'fuente'  => 'BCRA',
                    'params'  => ['endpoint' => $endpoint, 'status' => 'token_expired'],
                ];
            }

            return [
                'balance' => $balance,
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => $endpoint],
            ];
        });

        $value  = $record->balance ?? 'N/D';
        $status = $record->status ?? 'no_data';
        $this->line("   - {$record->name}: {$value}% ({$record->fuente}) [{$status}] actualizado a las {$record->updated_at}");
    }

    /**
     * 🔸 Actualiza una simulación o inversión calculada
     */
    protected function updateInvestment(string $name, \Closure $callback, string $type = 'inversion')
    {
        $this->info("→ Actualizando inversión: {$name}");

        $record = $this->cache->rememberOrRefresh($name, $type, 24, function () use ($callback) {
            $data = $callback();

            return [
                'balance' => $data['resultado']
                            ?? $data['monto_final']
                            ?? $data['monto_usd']
                            ?? null,
                'fuente'  => $data['fuente'] ?? 'BCRA',
                'params'  => $data,
            ];
        });

        $value  = $record->balance ?? ($record->data['balance'] ?? 'N/D');
        $status = $record->status ?? 'no_data';
        $this->line("   - {$record->name}: {$value}% ({$record->fuente}) [{$status}] actualizado a las {$record->updated_at}");
    }
}
