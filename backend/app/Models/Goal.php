<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;


/**
 * @mixin IdeHelperGoal
 */
class Goal extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'target_amount',
        'currency_id',
        'date_limit',
        'balance',
        'state',
        'active'
    ];

    /**
     * Relaciones
     */
    public function users()
    {
        return $this->belongsTo(User::class);
    }

    public function currency()
    {
        return $this->belongsTo(Currency::class); // Relación con la tabla Currency 
    }

    public function registers() {
    return $this->hasMany(Register::class);
    }

    public function disableGoal() {
        $request = new Request(['goal_id' => $this->id]);
        // Liberar dinero reservado
        app(\App\Http\Controllers\GoalController::class)
            ->assignReservedToMoneyMakers($request);
        // Actualizar estado de la meta
        $this->state = 'disabled';
        $this->active = false;
        $this->save();

    }

}
