<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;

use App\Models\Register;
use App\Services\CurrencyService;
use App\Models\MoneyMaker;
use Illuminate\Http\Request;
use App\Models\Currency;
use App\Models\Goal;

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
            'file' => 'nullable|file|mimes:jpg,jpeg,png,pdf,doc,docx',
            'name' => 'nullable|string|max:255',
        ]);

        $user = $request->user();
        $service = app(\App\Services\RegisterService::class);

            try {
                $register = $service->createRegister($request, $user);
                $service->updateBalances($register, $user); // actualizo los balances relacionados a meta y MoneyMaker

                $register->load(['currency', 'category']);

            } catch (\Exception $e) {
                return response()->json([
                    'error' => 'No se pudo crear el registro',
                    'details' => $e->getMessage()
                ], 500);
            }

            $rewards = app(\App\Services\ChallengeProgressService::class)
                ->recomputeForUserWithRewards($user);

        return response()->json([
            'message' => 'Registro creado con éxito',
            'data' => $register,
            'rewards' => $rewards,
            'goal' => $register['goal'] ?? null,
            ], 201);
        }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Register  $register
     * @return \Illuminate\Http\Response
     */
    public function show(Register $register) {
        $user = auth()->user();
        $register = Register::with(['category', 'goal', 'currency', 'moneyMaker'])
            ->where('id', $register->id)
            ->where('user_id', $user->id)
            ->first();
        if (!$register) {
            return response()->json(['message' => 'Registro no encontrado'], 404);
        }
    return response()->json(['register' => $register]);
    }


    public function getByMoneyMaker($moneyMakerId) {
        $user = auth()->user();
        $registers = Register::with('currency', 'category', 'goal' ) // carga relación
            ->where('user_id', $user->id)
            ->where('moneyMaker_id', $moneyMakerId)
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json([
            'registers' => $registers
        ]);
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
