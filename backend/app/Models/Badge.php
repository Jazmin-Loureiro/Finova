<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * @mixin IdeHelperBadge
 */
class Badge extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'tier',
        'icon',
    ];

    // Muchos usuarios pueden tener muchas insignias
    public function users()
    {
        return $this->belongsToMany(User::class, 'badge_user');
    }
}
