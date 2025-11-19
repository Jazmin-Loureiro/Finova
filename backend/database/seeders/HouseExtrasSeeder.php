<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\HouseExtra;

class HouseExtrasSeeder extends Seeder
{
    public function run()
    {
        // HouseExtra::truncate(); // opcional

        HouseExtra::insert([
            [
                'name' => 'Maceta',
                'level_required' => 2,
                'icon_path' => 'extras/maceta.svg',
                'icon_path_centered' => null,
                'z_index' => 12,
            ],
            [
                'name' => 'Luz exterior',
                'level_required' => 3,
                'icon_path' => 'extras/luz.svg',              // con garage
                'icon_path_centered' => 'extras/luz-centrada.svg', // sin garage
                'z_index' => 20,
            ],
            [
                'name' => 'Banquito',
                'level_required' => 4,
                'icon_path' => 'extras/banquito.svg',
                'icon_path_centered' => null, // ❗ No tiene versión centrada hoy
                'z_index' => 25,
            ],
            [
                'name' => 'Árbol lateral',
                'level_required' => 5,
                'icon_path' => 'extras/arbol.svg',
                'icon_path_centered' => null, // ❗ Tampoco cambia según garage
                'z_index' => 5,
            ],
        ]);
    }
}
