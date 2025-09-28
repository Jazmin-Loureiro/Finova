<?php

namespace Database\Seeders;
use App\Models\Currency;
use Illuminate\Database\Seeder;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;

class CurrencySeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        //{
        $currencies = [
            ['code' => 'USD', 'name' => 'Dólar estadounidense', 'symbol' => '$' , 'rate' => 0],
            ['code' => 'EUR', 'name' => 'Euro', 'symbol' => '€', 'rate' => 0],
            ['code' => 'ARS', 'name' => 'Peso argentino', 'symbol' => '$', 'rate' => 0],
            ['code' => 'BRL', 'name' => 'Real brasileño', 'symbol' => 'R$', 'rate' => 0],
            ['code' => 'MXN', 'name' => 'Peso mexicano', 'symbol' => '$', 'rate' => 0],
            ['code' => 'CLP', 'name' => 'Peso chileno', 'symbol' => '$', 'rate' => 0],
            ['code' => 'COP', 'name' => 'Peso colombiano', 'symbol' => '$', 'rate' => 0],
            ['code' => 'GBP', 'name' => 'Libra esterlina', 'symbol' => '£', 'rate' => 0],
            ['code' => 'JPY', 'name' => 'Yen japonés', 'symbol' => '¥', 'rate' => 0],
            ['code' => 'CNY', 'name' => 'Yuan chino', 'symbol' => '¥', 'rate' => 0],
        ];

        foreach ($currencies as $currency) {
            Currency::updateOrCreate(
                ['code' => $currency['code']],
                ['name' => $currency['name'], 'symbol' => $currency['symbol'], 'rate' => $currency['rate']]
            );
        }
    }
    } // End of run method
