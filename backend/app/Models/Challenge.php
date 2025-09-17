<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Challenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'state',
        'target_amount',
        'duration_days',
    ];

    /**
     * Relaciones
     */
    public function users() {
        return $this->belongsToMany(User::class, 'UserChallenge', 'user_id', 'challenge_id')
                    ->withPivot('balance', 'state');
    }

}
