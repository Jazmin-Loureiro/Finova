<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;

use App\Models\Register;
use App\Services\CurrencyService;
use App\Models\MoneyMaker;
use Illuminate\Http\Request;
use App\Models\Currency;

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
        'currency_id' => 'required|integer|exists:currencies,id',
        'moneyMaker_id' => 'required|exists:money_makers,id',
        'category_id' => 'nullable|exists:categories,id',
        'goal_id' => 'nullable|exists:goals,id',
        'repetition' => 'nullable|integer|min:0',
        'frequency_repetition' => 'nullable|integer|min:0',
        'file' => 'nullable|file|max:5120',
        'name' => 'nullable|string|max:255',
    ]);

    $filePath = $request->hasFile('file') ? $request->file('file')->store('uploads', 'public') : null;

    $user = $request->user();
    // Buscar moneda por ID
    $currency = Currency::findOrFail($request->currency_id);
    $fromCurrency = $currency->code;      // código de la moneda del registro
    $toCurrency   = $user->currency->code; // código de la moneda base del usuario
    $rate = $fromCurrency === $toCurrency ? 1.0 : CurrencyService::getRate($fromCurrency, $toCurrency);
    $amountInBaseCurrency = $request->balance * $rate;
    // Crear registro
    try {
        $register = $user->registers()->create([
            'type' => $request->type,
            'balance' => $request->balance,
            'file' => $filePath,
            'name' => $request->name,
            'category_id' => $request->category_id,
            'moneyMaker_id' => $request->moneyMaker_id,
            'currency_id' => $currency->id,
            'repetition' => $request->repetition ?? 0,
            'frequency_repetition' => $request->frequency_repetition ?? 0,
            'goal_id' => $request->goal_id,
        ]);
    } catch (\Exception $e) {
        Log::error('Error creando registro', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);

        return response()->json([
            'error' => 'No se pudo crear el registro',
            'details' => $e->getMessage()
        ], 500);
    }

    // Actualizar saldo de MoneyMaker
    $moneyMaker = MoneyMaker::findOrFail($request->moneyMaker_id);
    $moneyMaker->balance += $register->type === 'income' ? $register->balance : -$register->balance;
    $moneyMaker->save();
    // Actualizar saldo del usuario
    $user->balance += $register->type === 'income'
    ? $amountInBaseCurrency : 
    -$amountInBaseCurrency;
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
    

    public function getByMoneyMaker($moneyMakerId) {
        $user = auth()->user();
        $registers = Register::where('user_id', $user->id)
            ->where('moneyMaker_id', $moneyMakerId)
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json([
            'registers' => $registers
        ]);
        print_r($registers);
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
