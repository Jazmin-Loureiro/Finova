<?php

namespace App\Services\DataApi;

use App\Models\DataApi;
use App\Models\DataApiSnapshot;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class CacheService
{
    public function rememberOrRefresh(string $name, string $type, int $ttlHours, \Closure $fetch, bool $force = false): DataApi
{
    $normName = trim(strtolower($name));

    // 🔸 Evita refrescar si el TTL no venció, a menos que forcemos
    $current = DataApi::where('name', $normName)->first();
    if (!$force && $current) {
        $lastCheck = $current->last_fetched_at
            ? \Illuminate\Support\Carbon::parse($current->last_fetched_at)
            : \Illuminate\Support\Carbon::parse($current->updated_at);

        if ($lastCheck->diffInHours(now()) < $ttlHours) {
            return $current;
        }
    }


    $payload = $fetch() ?? [];

        // ✅ Extraer datos principales del payload
        $balanceValue = $payload['balance'] ?? null;
        $isNumeric = is_numeric($balanceValue);

        $balance = $isNumeric ? (float) $balanceValue : null;
        $status  = $isNumeric ? 'ok' : 'no_data';
        $fuente  = $payload['fuente'] ?? 'BCRA';

        // 🔹 params: campos "planos" o resumidos (variaciones, símbolo, ROI)
        $params = $payload['params'] ?? [];

        // 🔹 data: estructura completa del API (cripto/accion/bono)
        // Si el payload ya tiene "data" (como CoinGecko extendido), lo usamos;
        // si no, guardamos todo el payload completo.
        $data = $payload['data'] ?? $payload;

        // 🔹 raw_response (si tu fetch() devuelve el JSON literal)
        $raw = $payload['raw'] ?? null;

        // 3️⃣ Transacción (snapshot + cache actual)
        return DB::transaction(function () use ($normName, $type, $balance, $data, $fuente, $params, $raw, $status) {

            $lastVersion = DataApiSnapshot::where('name', $normName)->max('version') ?? 0;
            $version = $lastVersion + 1;

            // Snapshot histórico (guardamos todo el contenido crudo)
            $snapshot = DataApiSnapshot::create([
                'name'         => $normName,
                'type'         => $type,
                'balance'      => $balance,
                'data'         => $data,
                'params'       => $params,
                'fuente'       => $fuente,
                'fetched_at'   => now(),
                'version'      => $version,
                'is_current'   => true,
                'raw_response' => $raw,
                'status'       => $status,
            ]);

            // Marcamos snapshot anterior como no vigente
            DataApiSnapshot::where('name', $normName)
                ->where('id', '!=', $snapshot->id)
                ->update(['is_current' => false]);

            // Registro actual (cache principal)
            $record = DataApi::updateOrCreate(
                ['name' => $normName],
                [
                    'type'            => $snapshot->type,
                    'balance'         => $snapshot->balance,
                    'data'            => $snapshot->data,   // JSON extendido completo
                    'params'          => $snapshot->params, // Resumen útil para simulaciones
                    'fuente'          => $snapshot->fuente,
                    'status'          => $snapshot->status,
                    'last_fetched_at' => $snapshot->fetched_at,
                    'updated_at'      => now(),
                ]
            );

            return $record;
        });
    }
}
