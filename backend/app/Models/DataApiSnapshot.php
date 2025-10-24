<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DataApiSnapshot extends Model
{
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
        'data' => 'array',
        'params' => 'array',
        'raw_response' => 'array',
        'fetched_at' => 'datetime',
        'is_current' => 'boolean',
    ];
}
