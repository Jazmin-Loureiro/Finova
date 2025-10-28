<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperCurrency
 */
class Currency extends Model
{
    use HasFactory;
   

    // Campos que se pueden llenar de forma masiva
    protected $fillable = [
        'code',
        'name',
        'symbol',
        'rate',
    ];

    // Relaciones

     public function users()
    {
        return $this->hasMany(User::class);
    }

    public function moneyMakers()
    {
        return $this->hasMany(MoneyMaker::class);
    }

    public function registers()
    {
        return $this->hasMany(Register::class);
    }

    public function snapshots() {
            return $this->hasMany(CurrencyRateSnapshot::class);
        }

    public function scopeCode($query, $code)
{
    return $query->where('code', $code);
}
}