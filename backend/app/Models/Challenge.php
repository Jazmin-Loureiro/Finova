<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperChallenge
 */
class Challenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'target_amount',
        'duration_days',
        'active',
        'type',
        'payload',
        'reward_points',
        'reward_badge_id',
    ];

    protected $casts = [
        'payload' => 'array',
        'active'  => 'boolean',
        'target_amount' => 'float', // opcional
    ];


    /** 🏅 Relación con insignia recompensa */
    public function badge()
    {
        return $this->belongsTo(Badge::class, 'reward_badge_id');
    }

    /** 👥 Usuarios que tienen este desafío */
    public function users()
{
    return $this->belongsToMany(User::class, 'users_challenges', 'challenge_id', 'user_id')
                ->withPivot([
                    'balance',
                    'state',
                    'progress',
                    'start_date',
                    'end_date',
                    // 👇 NUEVO
                    'payload',
                    'target_amount',
                ])
                ->withTimestamps();
}

}
