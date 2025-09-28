<?php

namespace App\Services;

use App\Models\Currency;
use Illuminate\Support\Facades\Http;

class CurrencyService
{
    /**
     * Obtiene la tasa de conversión desde $from a $to.
     * Actualiza la tabla currencies si es necesario.
     */
    public static function getRate(string $from, string $to): float {
        if ($from === $to) {
            return 1.0;
        }
        $currency = Currency::where('code', $from)->first();
        if ($currency) {
            // Si la DB está actualizada (<24h), uso la DB
            if ($currency->updated_at && $currency->rate > 0 && $currency->updated_at->diffInHours(now()) < 24) {
                return $currency->rate;
            }
        }
        // Si no hay tasa o está vieja, llamo a la API
        $apiKey = env('EXCHANGE_API_KEY'); // asegurate de poner tu clave en .env
        $url = "https://v6.exchangerate-api.com/v6/{$apiKey}/pair/{$from}/{$to}";
        // Llamada a la API ignorando SSL (solo para desarrollo HAY Q REVISAR)
        $response = Http::withOptions(['verify' => false])->get($url);
        if ($response->failed()) {
            throw new \Exception("No se pudo obtener la tasa de cambio.");
        }
        $json = $response->json();
        if (!isset($json['conversion_rate'])) {
            throw new \Exception("Conversion rate no encontrado.");
        }
        $rate = floatval($json['conversion_rate']); // tasa obtenida de la API 
        Currency::updateOrCreate(
            ['code' => $from],
            ['rate' => $rate,'updated_at' => now(),]
        );
        return $rate;
    }

    /**
     * Convierte un monto de $from a $to
     */
    public static function convert(float $amount, string $from, string $to): float {
        $rate = self::getRate($from, $to);
        $converted = $amount * $rate;
        return $converted;
    }
}

