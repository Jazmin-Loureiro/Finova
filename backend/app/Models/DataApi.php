<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DataApi extends Model
{
    protected $table = 'data_apis';

    protected $fillable = [
        'name',
        'type',
        'balance',
        'data',
        'params',
        'fuente',
        'status',
        'last_fetched_at',
    ];

    protected $casts = [
        'data'            => 'array',     // Guarda/rescata JSON completo del API
        'params'          => 'array',     // Guarda/rescata campos clave (variaciones, ROI, etc.)
        'balance'         => 'float',     // Convierte balance automáticamente a float
        'last_fetched_at' => 'datetime',  // Permite comparaciones con Carbon
    ];
}
