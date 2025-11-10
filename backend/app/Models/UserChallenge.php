<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperUserChallenge
 */
class UserChallenge extends Model
{
    use HasFactory;

    protected $table = 'users_challenges';

    protected $fillable = [
        'user_id',
        'challenge_id',
        'goal_id',
        'balance',
        'state',
        'progress',
        'start_date',
        'end_date',
        // 👇 NUEVO: datos personalizados por usuario
        'payload',
        'target_amount',
    ];

    // ✅ convierte automáticamente a float o datetime
    protected $casts = [
        'balance'      => 'float',
        'progress'     => 'float',
        'start_date'   => 'datetime',
        'end_date'     => 'datetime',
        // 👇 NUEVO
        'payload'       => 'array',
        'target_amount' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function challenge()
    {
        return $this->belongsTo(Challenge::class);
    }

    public function goal()
    {
        return $this->belongsTo(Goal::class);
    }
}
