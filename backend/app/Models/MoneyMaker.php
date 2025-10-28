<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperMoneyMaker
 */
class MoneyMaker extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'type',
        'balance',
        'balance_reserved',
        'currency_id',
        'color',
    ];

    /**
     * Relaciones
     */

    public function currency()
    {
        return $this->belongsTo(Currency::class); // Relación con la tabla Currency 
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

   public function registers()
{
    return $this->hasMany(Register::class, 'moneyMaker_id'); // aquí la columna correcta
}
}
