<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MoneyMakerTypeSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('money_maker_types')->insert([
            [
                'name' => 'Efectivo',
                'description' => 'Dinero físico disponible.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Banco',
                'description' => 'Cuentas bancarias tradicionales.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Tarjeta de crédito',
                'description' => 'Fuentes asociadas a tarjetas de crédito.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Tarjeta de débito',
                'description' => 'Cuentas vinculadas a tarjetas de débito.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Ahorros',
                'description' => 'Cuentas destinadas al ahorro personal.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Inversión',
                'description' => 'Fuentes asociadas a fondos o inversiones.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Criptomoneda',
                'description' => 'Carteras digitales o activos cripto.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Cuenta virtual',
                'description' => 'Billeteras digitales o fintechs.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),

            ],
            [
                'name' => 'PayPal',
                'description' => 'Cuentas o fondos en PayPal.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Transferencia',
                'description' => 'Fuentes basadas en transferencias recibidas.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Préstamo',
                'description' => 'Fondos provenientes de créditos o préstamos.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Otro',
                'description' => 'Otro tipo de fuente no especificada.',
                'active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }
}
