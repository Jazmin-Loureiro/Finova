<?php

namespace App\Services;

use App\Models\Currency;
use Illuminate\Support\Facades\Http;

class CurrencyService
{
    /**
     * Obtiene la tasa de conversión desde $from a $to.
     * Actualiza la tabla currencies si es necesario.
    public static function getRate(string $from, string $to): float {
        $from = strtoupper(trim($from));
        $to   = strtoupper(trim($to));

        if ($from === $to) return 1.0;

        $currencyFrom = Currency::where('code', $from)->first();
        $currencyTo   = Currency::where('code', $to)->first();

        // Si existen y están actualizadas (<24h) uso DB
        if ($currencyFrom && $currencyTo) {
            $lastUpdated = min($currencyFrom->updated_at, $currencyTo->updated_at);

            if ( $currencyFrom->rate > 0 &&
                $currencyTo->rate > 0 &&
                $lastUpdated &&
                $lastUpdated->diffInHours(now()) < 24) {
                return round($currencyTo->rate / $currencyFrom->rate, 6);
            }
        }

        $apiKey = env('API_KEY');
        $url = "https://openexchangerates.org/api/latest.json?app_id={$apiKey}&base=USD";
        $response = Http::withOptions(['verify' => false])->get($url);

        if ($response->failed()) {
            throw new \Exception("No se pudo obtener la tasa de cambio.");
        }

        $json = $response->json();

        if (!isset($json['rates'])) {
            throw new \Exception("No se encontraron rates en la respuesta.");
        }

        $rates = $json['rates'];

        foreach ($rates as $code => $rate) {
            $currency = Currency::where('code', $code)->first();
            if ($currency) {
                $currency->rate = $rate;
                $currency->updated_at = now();
                $currency->save();
            }
        }

        if (!isset($rates[$from]) || !isset($rates[$to])) {
            throw new \Exception("No se encontró la tasa para $from o $to.");
        }

        $rateFrom = $rates[$from];
        $rateTo   = $rates[$to];

        return round($rateTo / $rateFrom, 6);
    }
    */
    /**
     * Obtiene la tasa de conversión desde $from a $to.
     * Asume que la tabla currencies está actualizada.
     */

    public static function getRate(string $from, string $to): float
{
    $from = strtoupper(trim($from));
    $to   = strtoupper(trim($to));

    if ($from === $to) return 1.0;

    $currencyFrom = Currency::where('code', $from)->first();
    $currencyTo   = Currency::where('code', $to)->first();

    if (!$currencyFrom || !$currencyTo) {
        throw new \Exception("No se encontraron monedas $from o $to en la base.");
    }

    return round($currencyTo->rate / $currencyFrom->rate, 6);
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

