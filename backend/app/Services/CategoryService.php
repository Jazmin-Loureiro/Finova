<?php

namespace App\Services;

use App\Models\User;

class CategoryService
{
    public static function createDefaultForUser(User $user)
    {
        $categories = [
            'expense' => [
                ['name'=>'Supermercado','color'=>'#FF5722'],
                ['name'=>'Ropa','color'=>'#E91E63'],
                ['name'=>'Casa','color'=>'#9C27B0'],
                ['name'=>'Entretenimiento','color'=>'#673AB7'],
                ['name'=>'Transporte','color'=>'#3F51B5'],
                ['name'=>'Viaje','color'=>'#2196F3'],
                ['name'=>'Educación','color'=>'#03A9F4'],
                ['name'=>'Comida','color'=>'#00BCD4'],
                ['name'=>'Electrónica','color'=>'#009688'],
                ['name'=>'Deporte','color'=>'#4CAF50'],
                ['name'=>'Restaurante','color'=>'#8BC34A'],
                ['name'=>'Salud','color'=>'#CDDC39'],
                ['name'=>'Comunicaciones','color'=>'#FFC107'],
                ['name'=>'Otros','color'=>'#FF9800'],
            ],
            'income' => [
                ['name'=>'General','color'=>'#66BB6A'],
                ['name'=>'Salario','color'=>'#4CAF50'],
                ['name'=>'Inversión','color'=>'#8BC34A'],
                ['name'=>'Recompensa','color'=>'#CDDC39'],
                ['name'=>'Regalo','color'=>'#FFC107'],
                ['name'=>'Negocio','color'=>'#FF9800'],
                ['name'=>'Otro','color'=>'#FF5722'],
            ],
        ];

        foreach ($categories as $type => $cats) {
            foreach ($cats as $cat) {
                $user->categories()->create([
                    'name' => $cat['name'],
                    'type' => $type,
                    'color' => $cat['color'],
                ]);
            }
        }
    }
}
