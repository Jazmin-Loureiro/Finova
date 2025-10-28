<?php

namespace App\Http\Controllers;

use App\Models\DataApi;
use App\Models\DataApiSnapshot;

class DataApiReadController extends Controller
{
    // vigente (puntero)
    public function current(string $name)
    {
        $norm = trim(strtolower($name));
        $row = DataApi::where('name', $norm)->first();

        if (!$row) return response()->json(['error' => 'No encontrado'], 404);

        return response()->json($row);
    }

    // histórico (últimos N)
    public function history(string $name)
    {
        $norm = trim(strtolower($name));
        $limit = (int) request('limit', 90);

        $rows = DataApiSnapshot::where('name', $norm)
            ->orderByDesc('version')
            ->limit($limit)
            ->get();

        return response()->json([
            'name' => $norm,
            'count' => $rows->count(),
            'items' => $rows->map(fn($r) => [
                'version'    => $r->version,
                'balance'    => $r->balance,
                'fetched_at' => optional($r->fetched_at)->toIso8601String(),
                'status'     => $r->status,
                'is_current' => (bool) $r->is_current,
            ]),
        ]);
    }

    /**
     * 📂 Obtener todos los registros por tipo (cripto, accion, bono, tasa, indicador, etc.)
     */
    public function byType(string $type)
    {
        $normType = trim(strtolower($type));

        $rows = \App\Models\DataApi::where('type', $normType)
            ->orderBy('updated_at', 'desc')
            ->get();

        if ($rows->isEmpty()) {
            return response()->json([
                'type' => $normType,
                'count' => 0,
                'items' => [],
                'message' => 'No se encontraron registros para este tipo.'
            ]);
        }

        return response()->json([
            'type' => $normType,
            'count' => $rows->count(),
            'items' => $rows->map(function ($r) {
                $params = $r->params ?? [];

                return [
                    'name'          => $r->name,
                    'symbol'        => $params['symbol'] ?? null,
                    'label'         => $params['name'] ?? null,
                    'price_usd'     => $r->balance,
                    'change_percent'=> $params['change_percent'] ?? null,
                    'fuente'        => $r->fuente,
                    'status'        => $r->status,
                    'updated_at'    => optional($r->updated_at)->toIso8601String(),
                    'last_fetched'  => optional($r->last_fetched_at)->toIso8601String(),
                ];
            }),
        ]);
    }


}
