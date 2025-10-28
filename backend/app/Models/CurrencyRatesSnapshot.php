<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CurrencyRatesSnapshot extends Model {
    use HasFactory;
    protected $fillable = [
        'currency_id',   // Relación con la moneda
        'rate',          // Valor del tipo de cambio
    ];

    /**
     * Relaciones
     */
    public function currency() {
        return $this->belongsTo(Currency::class);
    }
}