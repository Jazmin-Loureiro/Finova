<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;

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
    public function index(Request $request) {
        $user = auth()->user();
        $query = Register::with(['currency', 'category', 'goal','moneyMaker'])
            ->where('user_id', $user->id);
        // FILTRO opcional: MoneyMaker
        if ($request->filled('moneyMakerId')) {
            $query->where('money_maker_id', $request->moneyMakerId);
        }
        // Tipo
        if ($request->filled('type') && $request->type !== 'all') {
            $query->where('type', $request->type);
        }
        // Categoría
        if ($request->filled('category')) {
            $query->whereHas('category', function ($q) use ($request) {
                $q->where('name', $request->category);
            });
        }

        // Fechas
        $tz = 'America/Argentina/Buenos_Aires';
        if ($request->filled('from') && $request->filled('to')) {
            $from = Carbon::parse($request->from, $tz)->startOfDay();
            $to   = Carbon::parse($request->to, $tz)->endOfDay();
            $query->whereBetween('created_at', [
                $from->toDateTimeString(),
                $to->toDateTimeString()
            ]);
        }
        // Search
        if ($request->filled('search')) {
            $query->where(function ($q) use ($request) {
                $q->where('name', 'LIKE', '%' . $request->search . '%')
                ->orWhereHas('category', function ($c) use ($request) {
                    $c->where('name', 'LIKE', '%' . $request->search . '%');
                });
            });
        }
        // Orden final
        $registers = $query
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'registers' => $registers
        ]);
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
            'money_maker_id' => 'required|exists:money_makers,id',
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

            $rewards = app(\App\Services\Challenges\ChallengeProgressService::class)
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


   // Nueva función para cancelar una reserva
    public function cancelReservation($id) {
        $user = auth()->user();
        try {
            $register = Register::where('id', $id)
                ->where('user_id', $user->id)
                ->with(['goal', 'moneyMaker'])
                ->firstOrFail();

            if (!$register->goal) {
                return response()->json(['message' => 'Este registro no tiene una meta asociada'], 400);
            }

            if ($register->goal->state !== 'in_progress' || $register->reserved_for_goal <= 0) {
                return response()->json(['message' => 'La meta ya está completada o no hay monto reservado para liberar'], 400);
            }

            //  Actualizar balances
            $reserved = (float) $register->reserved_for_goal;
            $goal     = $register->goal;
            $source   = $register->moneyMaker;

            $goal->decrement('balance', $reserved);
            $source->update([
                'balance_reserved' => $source->balance_reserved - $reserved,
                'balance'          => $source->balance + $reserved,
                'updated_at'       => now(),
            ]);

            //  Liberar la reserva
            $register->update([
                'reserved_for_goal' => 0,
                'goal_id'           => null,
                'updated_at'        => now(),
            ]);

            return response()->json([
                'message'  => 'Reserva cancelada con éxito',
                'register' => $register->fresh(['goal', 'moneyMaker']),
            ], 200);

        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['message' => 'Registro no encontrado'], 404);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => 'No se pudo cancelar la reserva',
                'details' => $e->getMessage(),
            ], 500);
        }
    }
}
