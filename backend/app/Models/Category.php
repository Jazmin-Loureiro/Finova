<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'type',
        'color',
    ];

    /**
     * Relaciones
     */
    public function users()
    {
        return $this->belongsTo(User::class);
    }

    public function registers()
    {
        return $this->hasMany(Register::class);
    }
}
