<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail; // eliminado

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable implements MustVerifyEmail // añadido MustVerifyEmail
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'icon',
        'currencyBase',
        'balance',
    ];

    /**
     * Relaciones
     */
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

    public function challenges() {
        return $this->belongsToMany(Challenge::class, 'UserChallenge', 'user_id', 'challenge_id')
                    ->withPivot('balance', 'state');
    }

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
    ];
}
