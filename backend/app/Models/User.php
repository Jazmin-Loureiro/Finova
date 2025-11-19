<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * @mixin IdeHelperUser
 */
class User extends Authenticatable implements MustVerifyEmail
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'icon',
        'currency_id',
        'balance',
        'active',
        'last_challenge_refresh', // ✅ agregado
    ];

    /**
     * Relaciones
     */
    public function currency()
    {
        return $this->belongsTo(Currency::class);
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
    }

    public function registers()
    {
        return $this->hasMany(Register::class);
    }

    public function moneyMakers()
    {
        return $this->hasMany(MoneyMaker::class);
    }

    public function goals()
    {
        return $this->hasMany(Goal::class);
    }

    public function house()
    {
        return $this->hasOne(House::class);
    }

    /** 🏅 Gamificación */
    public function badges()
    {
        return $this->belongsToMany(Badge::class, 'badge_user');
    }

    public function streak()
    {
        return $this->hasOne(UserStreak::class);
    }

    /** 💪 Desafíos */
    public function challenges()
    {
        return $this->belongsToMany(Challenge::class, 'users_challenges', 'user_id', 'challenge_id')
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

    public function unlockedExtras()
    {
        return $this->belongsToMany(HouseExtra::class, 'house_extra_user')
                    ->withPivot('shown')
                    ->withTimestamps();
    }

    // Scope para usuarios activos
    public function scopeActive($query)
    {
        return $query->where('active', true);
    }

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_challenge_refresh' => 'datetime', // ✅ agregado (para comparaciones y formatos)
    ];
}
