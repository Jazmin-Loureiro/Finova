<?php

namespace App\Http\Controllers;

use App\Models\Register;
use App\Services\CurrencyService;
use App\Models\MoneyMaker;
use Illuminate\Http\Request;

class RegisterController extends Controller {
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     * Funcion que registra un nuevo ingreso o gasto
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
        public function store(Request $request) {
            $request->validate([
                'type' => 'required|in:income,expense',
                'balance' => 'required|numeric|min:0.01',
                'file' => 'nullable|file|max:5120', 
                'name' => 'nullable|string|max:255',
            ]);
            $filePath = $request->hasFile('file') ? $request->file('file')->store('uploads', 'public') : null;
            $user = $request->user(); // usuario autenticado
            $fromCurrency = $request->typeMoney;      // moneda del registro
            $toCurrency   = $user->currencyBase;     // moneda base del usuario
            // Calcular tasa de conversión
            if ($fromCurrency === $toCurrency) {
                $rate = 1.0; // misma moneda, tasa 1
            } else {
                $rate = CurrencyService::getRate($fromCurrency, $toCurrency); // obtengo la tasa
            }
            // Monto convertido a la moneda base del usuario
            $amountInBaseCurrency = $request->balance * $rate;
            $register = $user->registers()->create([
                'type' => $request->type,
                'balance' => $request->balance,  // monto original
                'file' => $filePath,
                'name' => $request->name,
                'category_id' => $request->category_id,
                'moneyMaker_id' => $request->moneyMaker_id,
                'typeMoney' => $fromCurrency,
                'repetition' => $request->repetition,
                'frequency_repetition' => $request->frequency_repetition,
                'goal_id' => $request->goal_id,
            ]);

            // Actualizar saldo de la fuente de pago (siempre en su propia moneda)
            $moneyMaker = MoneyMaker::findOrFail($request->moneyMaker_id);
            $moneyMaker->balance += ($register->type === 'income' 
                ? (float)$register->balance 
                : -(float)$register->balance);
            $moneyMaker->save();

            // Actualizar saldo del usuario (en su moneda base)
            $user->balance += ($register->type === 'income' 
                ? $amountInBaseCurrency 
                : -$amountInBaseCurrency);
            $user->save();

            return response()->json([
                'message' => 'Registro creado con éxito',
                'data' => $register,
                'moneyMaker' => $moneyMaker
            ], 201);
        }



    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Register  $register
     * @return \Illuminate\Http\Response
     */
    public function show(Register $register)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Register  $register
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Register $register)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Register  $register
     * @return \Illuminate\Http\Response
     */
    public function destroy(Register $register)
    {
        //
    }
}
