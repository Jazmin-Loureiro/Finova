<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Register extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'moneyMaker_id',
        'name',
        'balance',
        'typeMoney',
        'type',
        'file',
        'repetition',
        'frequency_repetition',
        'goal_id',
    ];

    /**
     * Relaciones
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function categories()
    {
        return $this->belongsTo(Category::class); // Una categoría puede tener muchos registros
    }

    public function moneyMakers()
    {
        return $this->belongsTo(MoneyMaker::class);
    }

    public function goals()
    {
        return $this->belongsTo(Goal::class);
    }

}
