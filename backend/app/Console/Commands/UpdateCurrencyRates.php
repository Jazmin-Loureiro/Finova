<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;
use App\Models\Currency;

class UpdateCurrencyRates extends Command {
    /**
     * El nombre y la firma del comando.
     */
    protected $signature = 'currencies:update';

    /**
     * Descripción del comando.
     */
    protected $description = 'Actualiza las tasas de cambio desde Open Exchange Rates y las guarda en la base de datos.';

    /**
     * Ejecuta el comando.
     */
    public function handle() {
        $apiKey = env('API_KEY');
        $url = "https://openexchangerates.org/api/latest.json?app_id={$apiKey}&base=USD";

        $response = Http::withOptions(['verify' => false])->get($url); // Desactivar verificación SSL

        if ($response->failed()) {
            $this->error('❌ No se pudo obtener la tasa de cambio.');
            return 1;
        }

        $json = $response->json();
        if (!isset($json['rates'])) {
            $this->error('❌ No se encontraron rates en la respuesta.');
            return 1;
        }
        $rates = $json['rates']; 
        $now = now();

        foreach ($rates as $code => $rate) {
            $currency = Currency::where('code', $code)->first();
            if ($currency) {
                $currency->rate = $rate;
                $currency->updated_at = $now;
                $currency->save();
            }
        }

        \Log::info('Tasas de cambio actualizadas', ['hora' => now()->toDateTimeString()]);
        $this->info('✅ Tasas de cambio actualizadas correctamente (' . count($rates) . ' monedas).');

        return 0;
    }
}
