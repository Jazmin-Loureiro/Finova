<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperMission
 */
class Mission extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'period',
        'type',
        'description',
        'payload',
        'reward_points',
        'active',
    ];

    protected $casts = [
        'payload' => 'array', // para leer el JSON como array
    ];

    public function userMissions()
    {
        return $this->hasMany(UserMission::class);
    }
}
