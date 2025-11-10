<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;

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
        'active',
        'is_challenge_goal', // 👈 NUEVO campo
    ];

    // 👇 Esto hace que Laravel lo trate como boolean (true/false)
    protected $casts = [
        'is_challenge_goal' => 'boolean',
    ];

    /**
     * Relaciones
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }

    public function registers()
    {
        return $this->hasMany(Register::class);
    }

    public function disableGoal()
    {
        $request = new Request(['goal_id' => $this->id]);

        app(\App\Http\Controllers\GoalController::class)
            ->assignReservedToMoneyMakers($request);

        $this->state = 'disabled';
        $this->active = false;
        $this->save();
    }
}
