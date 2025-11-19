<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HouseExtra extends Model
{
    protected $fillable = [
        'name',
        'icon_path',
        'icon_path_centered',
        'level_required',
        'z_index',
    ];

    public function users()
    {
        return $this->belongsToMany(User::class, 'house_extra_user')
                    ->withPivot('shown');
    }

}

