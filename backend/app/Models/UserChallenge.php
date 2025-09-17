<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserChallenge extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'challenge_id',
        'balance',
        'state',
    ];

    /**
     * Relaciones
     */
    public function users()
    {
        return $this->belongsTo(User::class);
    }

    public function challenges()
    {
        return $this->belongsTo(Challenge::class);
    }
}
