<?php

namespace App\Http\Controllers;

use App\Models\Register;
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
        'file' => 'nullable|file|max:5120', // max 5MB
        'name' => 'nullable|string|max:255',
    ]);

    $filePath = $request->hasFile('file') ? $request->file('file')->store('uploads', 'public') : null;

    $register = $request->user()->registers()->create([
        'type' => $request->type,
        'balance' => $request->balance,
        'file' => $filePath, // ruta final si se subió
        'name' => $request->name,
        'category_id' => $request->category_id,
        'moneyMaker_id' => $request->moneyMaker_id,
        'typeMoney' => $request->typeMoney,
        'repetition' => $request->repetition,
        'frequency_repetition' => $request->frequency_repetition,
        'goal_id' => $request->goal_id,
    ]);

    
     // Actualizar saldo de la fuente de pago
    $moneyMaker = MoneyMaker::find($request->moneyMaker_id);
    $moneyMaker->balance += ($register->type === 'income' ? (float)$register->balance : -(float)$register->balance);
    $moneyMaker->save();

    return response()->json(['message' => 'Registro creado con éxito', 'data' => $register , 'moneyMaker' => $moneyMaker], 201);
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
