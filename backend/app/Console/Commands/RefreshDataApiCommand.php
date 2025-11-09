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
 * 🔹 Grupo diario: tasas base del BCRA e indicadores comparativos reales.
 * Guarda tasas oficiales e incluye la comparativa real entre inflación y TNA.
 */
protected function refreshDaily()
{
    $this->info("📅 Actualizando datos diarios del BCRA...");

    /* ---------------- TASAS BASE ---------------- */
    $tasas = [
        ['name' => 'tasa_prestamos_personales', 'endpoint' => '/tasa_prestamos_personales'],
        ['name' => 'tasa_plazo_fijo',           'endpoint' => '/tasa_depositos_30_dias'],
        ['name' => 'tasa_uva',                  'endpoint' => '/uva'],
    ];

    foreach ($tasas as $t) {
        $this->updateBcraRate($t['name'], $t['endpoint']);
    }

    /* ---------------- INDICADORES ---------------- */
    $indicadores = [
        ['name' => 'inflacion_mensual',    'endpoint' => '/inflacion_mensual_oficial'],
        ['name' => 'inflacion_interanual', 'endpoint' => '/inflacion_interanual_oficial'],
    ];

    foreach ($indicadores as $ind) {
        $this->updateBcraRate($ind['name'], $ind['endpoint']);
    }

    /* ---------------- COMPARATIVA REAL PF vs INFLACIÓN ---------------- */
    $this->updateInvestment(
        'comparativa_pf_inflacion',
        fn() => $this->investment->comparePlazoFijoVsInflacion(),
        'indicador'
    );

    $this->line("✅ Tasas, inflación y comparativa actualizadas correctamente.");
}


        /**
         * 🔹 Grupo frecuente: cotizaciones de criptos, acciones, bonos y divisas
         * Se actualiza cada pocas horas (3–6 h).
         */
        protected function refreshFrequent()
        {
            $this->info("💱 Actualizando cotizaciones frecuentes (Criptos, Acciones y Bonos)...");

            // 🔸 Instanciamos el servicio unificado
            $market = app(\App\Services\DataApi\MarketService::class);

            // 🔹 Activos a consultar
            $assets = [
                // 🔷 Criptos (CoinGecko)
                ['type' => 'cripto', 'symbol' => 'bitcoin'],
                ['type' => 'cripto', 'symbol' => 'ethereum'],
                ['type' => 'cripto', 'symbol' => 'solana'],
                ['type' => 'cripto', 'symbol' => 'dogecoin'],
                ['type' => 'cripto', 'symbol' => 'cardano'],

                // 🔷 Acciones (TwelveData)
                ['type' => 'accion', 'symbol' => 'AAPL'],
                ['type' => 'accion', 'symbol' => 'MSFT'],
                ['type' => 'accion', 'symbol' => 'TSLA'],
                ['type' => 'accion', 'symbol' => 'GOOGL'],

                // 🔷 Bonos / ETF internacionales (TwelveData)
                ['type' => 'bono', 'symbol' => 'TLT'],
                ['type' => 'bono', 'symbol' => 'BND'],
                ['type' => 'bono', 'symbol' => 'LQD'],
                ['type' => 'bono', 'symbol' => 'IEF'],
            ];

            // 🔹 Obtenemos todas las cotizaciones
            $quotes = $market->getBatch($assets);

            // 🔸 Guardamos cada resultado con su tipo real
            foreach ($quotes as $data) {

                // 🔹 Normalizar nombre del símbolo para las criptos
                $symbol = strtolower($data['symbol'] ?? '');
                $type   = $data['type'] ?? 'mercado';

                if ($type === 'cripto') {
                    $map = [
                        'btc'  => 'bitcoin',
                        'eth'  => 'ethereum',
                        'sol'  => 'solana',
                        'doge' => 'dogecoin',
                        'ada'  => 'cardano',
                    ];
                    $normalized = $map[$symbol] ?? $symbol;
                } else {
                    $normalized = $symbol;
                }

                // 🔹 Generar el nombre coherente para guardar en DataApi
                $key = "market_{$type}_{$normalized}";

                // 🔹 Guardar el registro en cache con nombre limpio
                $this->updateInvestment($key, fn() => [
                    'balance' => $data['price_usd'] ?? null,
                    'fuente'  => $data['fuente'] ?? 'N/D',
                    'params'  => $data,
                ], $type);

                usleep(200000); // 🕐 Delay pequeño entre guardados
            }

            // Llamamos a el comando existente para actualizar las monedas
                $this->call('currencies:update');
                $this->line("✅ Tasas de cambio actualizadas correctamente (grupo: frequent).");


            $this->line("✅ Cotizaciones reales actualizadas correctamente con MarketService unificado.");
        }


    /**
     * 🔹 Grupo semanal: indicadores macroeconómicos (BCRA + World Bank)
     * Actualiza datos que no cambian a diario ni en tiempo real.
     */
    protected function refreshWeekly()
    {
        $this->info("📊 Actualizando indicadores semanales del BCRA...");

        $indicadores = [
            ['name' => 'inflacion_interanual',       'endpoint' => '/inflacion_interanual_oficial'],
            ['name' => 'reservas_internacionales',   'endpoint' => '/reservas'],
            ['name' => 'merval',                     'endpoint' => '/merval'],
        ];

        foreach ($indicadores as $ind) {
            // TTL semanal = 7 días
            $this->cache->rememberOrRefresh($ind['name'], 'indicador', 24 * 7, function () use ($ind) {
                $endpoint = $ind['endpoint'];
                return [
                    'balance' => match ($endpoint) {
                        '/inflacion_interanual_oficial' => $this->bcra->getIndicator('inflacion_interanual_oficial'),
                        '/reservas'                     => $this->bcra->getIndicator('reservas'),
                        '/merval'                       => $this->bcra->getIndicator('merval'),
                        default                         => null,
                    },
                    'fuente'  => 'BCRA',
                    'params'  => ['endpoint' => $ind['endpoint']],
                ];
            });
            sleep(1);
        }

        $this->line("✅ Indicadores semanales del BCRA actualizados correctamente.");

        /* ---------------------------------------------------------
        * 🌍 BLOQUE: Actualizar PPA (Banco Mundial)
        * --------------------------------------------------------- */
        $this->info("🌍 Verificando indicadores de PPA (Banco Mundial)...");

        $worldbank = app(\App\Services\DataApi\WorldBankService::class);

        // Lista de monedas a verificar
        $currencies = ['ARS', 'USD', 'EUR', 'BRL', 'MXN', 'CLP', 'COP', 'GBP', 'JPY', 'CNY'];

        foreach ($currencies as $code) {
            $countryCode = $worldbank::getCountryCode($code);
            $key = 'ppa_' . strtolower($countryCode);

            $this->info("→ Verificando {$key} ({$code}) ...");

            try {
                $ppaValue = $worldbank::getPPP($code);

                if ($ppaValue !== null) {
                    $record = \App\Models\DataApi::where('name', $key)->first();

                    // ✅ Solo actualiza si no existe o el valor cambió
                    if (!$record || round((float) $record->balance, 6) !== round((float) $ppaValue, 6)) {
                        $record = \App\Models\DataApi::updateOrCreate(
                            ['name' => $key],
                            [
                                'type'            => 'economy',
                                'balance'         => $ppaValue,
                                'fuente'          => 'WorldBank',
                                'params'          => ['currency' => $code],
                                'status'          => 'ok',
                                'last_fetched_at' => now(),
                                'updated_at'      => now(),
                            ]
                        );

                        $this->line("   - {$key}: {$ppaValue} actualizado (nuevo valor o sin registro previo).");
                    } else {
                        $this->line("   - {$key}: sin cambios (valor y TTL vigentes).");
                    }
                } else {
                    $this->line("   - {$key}: sin cambios (TTL vigente o sin datos nuevos).");
                }
            } catch (\Throwable $e) {
                $this->warn("   ⚠️ Error actualizando {$key}: " . $e->getMessage());
            }

            sleep(1);
        }

        $this->line("✅ Verificación de PPA completada (World Bank).");
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
    protected function updateInvestment(string $name, \Closure $fetch, string $type = 'inversion')
{
    $this->line("→ Actualizando inversión: {$name}");

    $data = $fetch();

    // 🔹 Si existe precio, lo usamos como balance
    if (is_array($data)) {
        if (isset($data['price_usd'])) {
            $data['balance'] = $data['price_usd'];
        } elseif (isset($data['price'])) {
            $data['balance'] = $data['price'];
        } elseif (isset($data['ultimo_precio'])) {
            $data['balance'] = $data['ultimo_precio'];
        }
    }

    $ttl = config('dataapi.ttl.frequent', 3);
    $record = $this->cache->rememberOrRefresh($name, $type, $ttl, fn() => $data);

    $status = strtoupper($record->status);
    $value  = $record->balance !== null ? round($record->balance, 2) . ' USD' : 'N/D%';
    $this->line("   - {$name}: {$value} ({$record->fuente}) [{$status}] actualizado a las " . now());
}

}
