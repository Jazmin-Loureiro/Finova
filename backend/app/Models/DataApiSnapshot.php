<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DataApiSnapshot extends Model
{
    protected $table = 'data_api_snapshots';

    protected $fillable = [
        'name',
        'type',
        'balance',
        'data',
        'params',
        'fuente',
        'fetched_at',
        'version',
        'is_current',
        'raw_response',
        'status',
    ];

    protected $casts = [
        'balance'       => 'float',     // 🔹 igual que en DataApi
        'data'          => 'array',     // 🔹 bloque extendido completo (CoinGecko/TwelveData)
        'params'        => 'array',     // 🔹 resumen de campos clave
        'raw_response'  => 'array',     // 🔹 si guardás el JSON literal de la API
        'fetched_at'    => 'datetime',  // 🔹 para orden cronológico y formateo Carbon
        'is_current'    => 'boolean',   // 🔹 fácil filtrado en queries
    ];
}
