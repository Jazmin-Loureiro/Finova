<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MoneyMakerType extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'active',
        'created_at',
        'updated_at',
    ];

public function moneyMakers()
{
    return $this->hasMany(MoneyMaker::class, 'money_maker_type_id');
}



}
