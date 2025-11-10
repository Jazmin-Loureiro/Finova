<?php

namespace App\Http\Controllers;

use App\Models\Goal;
use App\Models\Currency;
use App\Models\MoneyMaker;
use Illuminate\Http\Request;

class GoalController extends Controller
{
    /**
     * listar todas las metas del usuario autenticado
     *
     * @return \Illuminate\Http\Response
     */
    public function index() {
        $goals = auth()->user()->goals()
            ->with('currency')
            ->orderByRaw("CASE  WHEN state = 'in_progress' THEN 1 WHEN state = 'completed' THEN 2 WHEN state = 'disabled' THEN 3 ELSE 4 END")
            ->get();

        return response()->json(['goals' => $goals], 200);
    }

    /**
     * crear una meta
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request) {
         $request->validate([
            'name' => 'required|string|max:255',
            'target_amount' => 'required|numeric|min:0.01',
            'currency_id' => 'required|integer|exists:currencies,id',
            'date_limit' => 'required|date',
        ]);
        $goal = $request->user()->goals()->create([
            'name' => $request->name,
            'target_amount' => $request->target_amount,
            'currency_id' => $request->currency_id,
            'date_limit' => $request->date_limit,
            'balance' => 0,
            'state' => 'in_progress',
            'active' => true,
        ]);
        return response()->json(['message' => 'Meta creada con éxito', 'data' => $goal], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Goal  $goal
     * @return \Illuminate\Http\Response
     */
    public function show(Goal $goal)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Goal  $goal
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Goal $goal) {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'target_amount' => 'sometimes|required|numeric|min:0.01',
            'currency_id' => 'sometimes|required|integer|exists:currencies,id',
            'date_limit' => 'sometimes|required|date',
        ]);
        $goal->fill($validated);
        // Si cambia la moneda, se valida su existencia
        if ($request->has('currency_id')) {
            $goal->currency_id = $request->currency_id;
        }
        $goal->save();
        return response()->json([
            'message' => 'Meta actualizada con éxito',
            'data' => $goal
        ], 200);
    }


    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Goal  $goal
     * @return \Illuminate\Http\Response
     */
        public function delete(Goal $goal, Request $request)
        {
            // 🧩 1️⃣ Si es meta creada por un desafío, fallar el desafío vinculado
            if ($goal->is_challenge_goal && $goal->id) {
                $userChallenge = \App\Models\UserChallenge::where('goal_id', $goal->id)
                    ->where('state', 'in_progress')
                    ->first();

                if ($userChallenge) {
                    $payload = $userChallenge->payload ?? [];
                    if (is_string($payload)) {
                        $payload = json_decode($payload, true) ?: [];
                    }

                    $payload['cancel_reason'] = 'goal_deleted';

                    $userChallenge->update([
                        'state' => 'failed',
                        'end_date' => now(),
                        'progress' => 0,
                        'payload' => $payload,
                    ]);
                }
            }

            // 🧩 2️⃣ Liberar dinero reservado (mantiene tu lógica actual)
            $request->merge(['goal_id' => $goal->id]);
            $this->assignReservedToMoneyMakers($request);

            // 🧩 3️⃣ Desvincular registros
            foreach ($goal->registers as $register) {
                $register->reserved_for_goal = 0;
                $register->save();
            }

            // 🧩 4️⃣ Desactivar la meta
            $goal->active = false;
            $goal->state = 'disabled';
            $goal->save();

            return response()->json([
                'message' => 'Meta eliminada con éxito' .
                    ($goal->is_challenge_goal ? ' y desafío marcado como fallido.' : '.'),
                'data' => $goal,
            ], 200);
        }

    /**
     * Asignar el dinero reservado de una meta a las fuentes de dinero correspondientes
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function assignReservedToMoneyMakers(Request $request) {
        $goalId = $request->input('goal_id');
        $goal = Goal::findOrFail($goalId);

        $moneyMakers = MoneyMaker::whereHas('registers', function ($q) use ($goalId) {
            $q->where('goal_id', $goalId);
        })->get();

        foreach ($moneyMakers as $mm) {
            $registers = $mm->registers()->where('goal_id', $goalId)->get();

            foreach ($registers as $reg) {
                $toRelease = $reg->reserved_for_goal ?? 0;
                $mm->balance += $toRelease;
                $mm->balance_reserved -= $toRelease;
            }
            $mm->balance_reserved = max(0, $mm->balance_reserved);
            $mm->save();
        }
        return response()->json([
            'message' => 'Dinero reservado asignado correctamente.',
            'goal' => $goal,
        ]);
    }

    public function fetchRegistersByGoal(Goal $goal) {
        $registers = $goal->registers()->with('moneyMaker', 'category', 'currency','goal')->get();
        return response()->json(['registers' => $registers], 200);
    }
}
