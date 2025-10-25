<?php

namespace App\Services\DataApi;

use App\Models\DataApi;
use App\Models\DataApiSnapshot;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class CacheService
{
    public function rememberOrRefresh(string $name, string $type, int $ttlHours, \Closure $fetch): DataApi
    {
        $normName = trim(strtolower($name));

        // 1️⃣ Cache actual válido
        $current = DataApi::where('name', $normName)->first();
        if ($current && Carbon::parse($current->updated_at)->diffInHours(now()) < $ttlHours) {
            return $current;
        }

        // 2️⃣ Obtener nuevo valor
        $payload = $fetch() ?? [];

        // ✅ Manejo de nulls
        $balanceValue = $payload['balance'] ?? null;
        $isNumeric = is_numeric($balanceValue);

        // Si no hay balance numérico, marcamos "no disponible"
        $balance = $isNumeric ? (float) $balanceValue : null;
        $status  = $isNumeric ? 'ok' : 'no_data';

        // Guardar todo el payload serializado en `data`
        $data = json_encode($payload, JSON_UNESCAPED_UNICODE);

        $fuente  = $payload['fuente'] ?? 'BCRA';
        $params  = $payload['params'] ?? null;
        $raw     = $payload['raw'] ?? null;

        // 3️⃣ Transacción para snapshot + cache
        return DB::transaction(function () use ($normName, $type, $balance, $data, $fuente, $params, $raw, $status) {
            $lastVersion = DataApiSnapshot::where('name', $normName)->max('version') ?? 0;
            $version = $lastVersion + 1;

            // Snapshot histórico
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

            DataApiSnapshot::where('name', $normName)
                ->where('id', '!=', $snapshot->id)
                ->update(['is_current' => false]);

            // Registro actual
            $record = DataApi::updateOrCreate(
                ['name' => $normName],
                [
                    'type'            => $snapshot->type,
                    'balance'         => $snapshot->balance,
                    'data'            => $snapshot->data,
                    'fuente'          => $snapshot->fuente,
                    'params'          => $snapshot->params,
                    'status'          => $snapshot->status,
                    'last_fetched_at' => $snapshot->fetched_at,
                    'updated_at'      => now(),
                ]
            );

            return $record;
        });
    }
}
