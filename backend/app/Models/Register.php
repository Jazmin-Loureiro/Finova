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
    public function users()
    {
        return $this->belongsTo(User::class);
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
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
