<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperRegister
 */
class Register extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'money_maker_id',
        'name',
        'balance',
        'reserved_for_goal',
        'currency_id',
        'type',
        'file',
        'repetition',
        'frequency_repetition',
        'goal_id',
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

    public function category()
    {
        return $this->belongsTo(Category::class); // Una categoría puede tener muchos registros
    }

    public function moneyMaker()
    {
        return $this->belongsTo(MoneyMaker::class, 'money_maker_id');
    }

    public function goal()
    {
        return $this->belongsTo(Goal::class);
    }
    public function getFileAttribute($value)
{
    return $value ? asset( $value) : null;
}


}
