<?php

namespace App\Services\DataApi;

use App\Models\DataApi;
use App\Models\Currency;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Carbon;

class WorldBankService
{
    private static $currencyToCountry = [
        'ARS' => 'AR',
        'USD' => 'US',
        'EUR' => 'DE',
        'BRL' => 'BR',
        'MXN' => 'MX',
        'CLP' => 'CL',
        'COP' => 'CO',
        'GBP' => 'GB',
        'JPY' => 'JP',
        'CNY' => 'CN',
    ];

    public static function getCountryCode(string $currencyCode): string
    {
        $currencyCode = strtoupper(trim($currencyCode));
        return self::$currencyToCountry[$currencyCode] ?? 'US';
    }

    /**
     * 🔹 Llamada directa al Banco Mundial (solo usada por CacheService)
     */
    public static function fetchPPP(string $countryCode): ?float
    {
        $url = str_replace('{ISO_CODE}', $countryCode, env('WORLD_BANK_PPP_URL'));
        $response = Http::withOptions(['verify' => false])->timeout(15)->get($url);

        if ($response->failed()) {
            Log::warning("⚠️ Error API World Bank ({$countryCode}): HTTP {$response->status()}");
            return null;
        }

        $data = $response->json();
        return isset($data[1][0]['value']) && is_numeric($data[1][0]['value'])
            ? (float) $data[1][0]['value']
            : null;
    }

    /**
     * 🔹 Obtiene valor PPA optimizado: usa DB → cache → API → fallback
     */
    public static function getPPP(string $currencyCode): ?float
    {
        $countryCode = self::getCountryCode($currencyCode);
        $key = 'ppa_' . strtolower($countryCode);

        $ttlDays = 24; // TTL en días (~24 días)

        // 1️⃣ Buscar en base de datos primero
        $record = DataApi::where('name', $key)
            ->where('type', 'economy')
            ->orderByDesc('last_fetched_at')
            ->first();

        if ($record) {
            // 🕐 Usar last_fetched_at (más semántico que updated_at)
            $lastFetch = $record->last_fetched_at
                ? Carbon::parse($record->last_fetched_at)
                : Carbon::parse($record->updated_at);

            $hoursDiff = $lastFetch->diffInHours(now());

            // Si está dentro del TTL, devolvemos directamente
            if ($hoursDiff < ($ttlDays * 24) && $record->balance > 0) {
                Log::info("ℹ️ PPA {$key} vigente ({$hoursDiff}h < TTL)");
                return $record->balance;
            }
        }

        // 2️⃣ Si no hay registro o está vencido → intentar actualizar usando CacheService
        try {
            $cache = app(CacheService::class);

            $newRecord = $cache->rememberOrRefresh($key, 'economy', $ttlDays * 24, function () use ($countryCode, $currencyCode) {
                $ppaValue = self::fetchPPP($countryCode);

                if (!$ppaValue) {
                    throw new \Exception("No se encontró valor PPA para {$countryCode}");
                }

                return [
                    'balance' => $ppaValue,
                    'fuente'  => 'WorldBank',
                    'params'  => [
                        'country'  => $countryCode,
                        'currency' => $currencyCode,
                    ],
                ];
            });

            return $newRecord->balance ?? null;

        } catch (\Throwable $e) {
            Log::error("❌ Error al actualizar PPA ({$currencyCode}): " . $e->getMessage());

            // 3️⃣ fallback → último valor conocido (aunque esté vencido)
            if (isset($record->balance)) {
                return $record->balance;
            }

            return null;
        }
    }

    /**
     * 🔹 Fuerza la actualización manual del PPA
     */
    public static function savePPP(string $currencyCode)
    {
        $countryCode = self::getCountryCode($currencyCode);
        return self::getPPP($currencyCode);
    }

    /**
     * 🔹 Sincroniza todos los países registrados
     */
    public static function syncPPPForAllCurrencies()
    {
        $currencies = Currency::all();
        $results = [];

        foreach ($currencies as $currency) {
            try {
                $results[$currency->code] = self::getPPP($currency->code);
            } catch (\Throwable $e) {
                $results[$currency->code] = 'Error: ' . $e->getMessage();
            }
        }

        return $results;
    }
}
