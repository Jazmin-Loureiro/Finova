<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

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

    public function scopeCode($query, $code)
{
    return $query->where('code', $code);
}
}