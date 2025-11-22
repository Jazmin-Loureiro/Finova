<?php

namespace App\Services;

use App\Models\User;

class CategoryService
{
    public static function createDefaultForUser(User $user)
    {
        $categories = [
            'expense' => [
                ['name'=>'Supermercado','color'=>'#E53935','icon'=>'shopping_cart'],      // rojo fuerte
                ['name'=>'Ropa','color'=>'#8E24AA','icon'=>'checkroom'],                 // violeta
                ['name'=>'Casa','color'=>'#3949AB','icon'=>'home'],                      // azul oscuro
                ['name'=>'Entretenimiento','color'=>'#5E35B1','icon'=>'theater_comedy'], // púrpura profundo
                ['name'=>'Transporte','color'=>'#039BE5','icon'=>'commute'],             // celeste brillante
                ['name'=>'Viaje','color'=>'#00897B','icon'=>'flight'],                   // verde azulado
                ['name'=>'Educación','color'=>'#43A047','icon'=>'school'],               // verde medio
                ['name'=>'Comida','color'=>'#FDD835','icon'=>'fastfood'],                // amarillo vibrante
                ['name'=>'Electrónica','color'=>'#FB8C00','icon'=>'devices'],            // naranja fuerte
                ['name'=>'Deporte','color'=>'#F4511E','icon'=>'fitness_center'],                 // naranja rojizo
                ['name'=>'Restaurante','color'=>'#6D4C41','icon'=>'restaurant'],         // marrón cálido
                ['name'=>'Salud','color'=>'#009688','icon'=>'health_and_safety'],        // verde agua
                ['name'=>'Comunicaciones','color'=>'#3949AB','icon'=>'phone'],           // azul intenso
                ['name'=>'Otros','color'=>'#757575','icon'=>'more_horiz'],               // gris neutro
            ],
            'income' => [
                ['name'=>'General','color'=>'#43A047','icon'=>'category_outlined','is_default'=>true],        // verde medio
                ['name'=>'Salario','color'=>'#2E7D32','icon'=>'attach_money'],           // verde oscuro
                ['name'=>'Inversión','color'=>'#1E88E5','icon'=>'trending_up'],          // azul brillante
                ['name'=>'Recompensa','color'=>'#7B1FA2','icon'=>'redeem'],              // púrpura intenso
                ['name'=>'Regalo','color'=>'#FBC02D','icon'=>'card_giftcard'],           // amarillo dorado
                ['name'=>'Negocio','color'=>'#EF6C00','icon'=>'business'],               // naranja oscuro
                ['name'=>'Otro','color'=>'#795548','icon'=>'more_horiz'],                // marrón suave
            ],
        ];

        foreach ($categories as $type => $cats) {
            foreach ($cats as $cat) {
                $user->categories()->create([
                    'name' => $cat['name'],
                    'type' => $type,
                    'color' => $cat['color'],
                    'icon' => $cat['icon'],
                    'active' => true,
                    'is_default' => $cat['is_default'] ?? false,
                ]);
            }
        }
    }
}
