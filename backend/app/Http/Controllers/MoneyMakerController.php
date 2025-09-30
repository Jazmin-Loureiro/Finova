<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;

use App\Models\moneyMaker;
use App\Models\Currency;
use Illuminate\Http\Request;
use App\Services\CurrencyService;

class MoneyMakerController extends Controller
{
    /**
     * Display a listing of the resource.
     * Lista todas las fuentes de dinero del usuario con el balance convertido a su moneda base
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request) {
        $user = $request->user();
        $toCurrency = $user->currency->code; // moneda base del usuario
        $moneyMakers = $user->moneyMakers()->with('currency')->get(); // obtengo todas las fuentes de dinero del usuario
        $totalInBase = 0; // saldo total en moneda base
        $result = $moneyMakers->map(function ($m) use ($toCurrency, &$totalInBase) { // paso $totalInBase por referencia
            $fromCurrency = $m->currency->code; // moneda del MoneyMaker
            $rate = $fromCurrency === $toCurrency
                ? 1.0
                : CurrencyService::getRate($fromCurrency, $toCurrency); // obtengo la tasa

            $balanceConverted = $m->balance * $rate; // convierto el balance a la moneda base
            $totalInBase += $balanceConverted; // acumulo al total en moneda base 

            return [ // retorno los datos del MoneyMaker junto con el balance convertido
                'id' => $m->id,
                'name' => $m->name,
                'type' => $m->type,
                'balance' => $m->balance,
              //  'typeMoney' => $fromCurrency,
                'balanceConverted' => round($balanceConverted, 2),
              //  'currencySymbol' => $m->currency->symbol ?? '',
                'color' => $m->color,
                'currency' => $m->currency,
            ];
        });
        $currency = Currency::find($toCurrency); // obtengo la moneda base del usuario para el símbolo
        return response()->json([ // retorno el listado junto con el total en moneda base
            'total_in_base' => round($totalInBase, 2),
            'currency_base' => $toCurrency,
            'currency_symbol' => $user->currency->symbol ?? '',
            'moneyMakers' => $result,
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    
    public function store(Request $request) {
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
            'balance' => 'required|numeric|min:0',
            'currency_id' => 'required|exists:currencies,id',
            'color' => 'required|string',
        ]);

        $user = $request->user();
        $fromCurrency = $request->currency_id;      // id con el q se esta registrando la moneda del MoneyMaker
        $toCurrency   = $user->currency_id;     // moneda base del usuario
        // convertir IDs a códigos
        $fromCurrencyCode = Currency::find($request->currency_id)->code;
        $toCurrencyCode   = Currency::find($user->currency_id)->code;
        // Calcular tasa
        if ($fromCurrencyCode === $toCurrencyCode) {
            $rate = 1.0;
        } else {
            $rate = CurrencyService::getRate($fromCurrencyCode, $toCurrencyCode);
        }
        $convertedBalance = $request->balance * $rate;
        // Crear MoneyMaker en la DB (siempre en su moneda original)
        $moneyMaker = $user->moneyMakers()->create([
            'name' => $request->name,
            'type' => $request->type,
            'balance' => $request->balance,   // monto original
            'currency_id' => $fromCurrency,     // moneda original
            'color' => $request->color,
        ]);
        $user->balance=(float) $user->balance + (float)$convertedBalance; // actualizar saldo del usuario
        $user->save();

        return response()->json([
            'message' => 'Fuente de pago creada con éxito',
            'moneyMaker' => [
                'id' => $moneyMaker->id,
                'name' => $moneyMaker->name,
                'type' => $moneyMaker->type,
                'balance' => $moneyMaker->balance,
                'currency_id' => $moneyMaker->currency_id,
                'balance_converted' => $convertedBalance, // saldo convertido a moneda base 
                'currencyBase' => $toCurrency, // moneda base del usuario
                'color' => $moneyMaker->color,
            ],
            'user_balance' => $user->balance,
        ], 201);
    }


    /**
     * Display the specified resource.
     *
     * @param  \App\Models\moneyMaker  $moneyMaker
     * @return \Illuminate\Http\Response
     */
    public function show(moneyMaker $moneyMaker)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\moneyMaker  $moneyMaker
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, moneyMaker $moneyMaker)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\moneyMaker  $moneyMaker
     * @return \Illuminate\Http\Response
     */
    public function destroy(moneyMaker $moneyMaker)
    {
        //
    }
}
