<?php

namespace App\Http\Controllers;
use App\Models\MoneyMaker;

use Illuminate\Http\Request;
use App\Services\MoneyMakerService;

class MoneyMakerController extends Controller {
    
    public function index(Request $request) {
        $data = (new MoneyMakerService())->listForUser($request->user());
        return response()->json([
            'total_in_base'   => $data['totalInBase'],
            'currency_base'   => $data['currencyBase'],
            'currency_symbol' => $data['symbol'],
            'moneyMakers'     => $data['moneyMakers'],
        ]);
    }

    public function store(Request $request) {
        $validated = $request->validate([
            'name'        => 'required|string|max:255',
            'type'        => 'required',
            'balance'     => 'required|numeric|min:0',
            'currency_id' => 'required|exists:currencies,id',
            'color'       => 'required|string',
        ]);

        if (is_array($validated['type'])) {
            $validated['type'] = $validated['type']['id'] ?? null;
        }
        $data = (new MoneyMakerService())->createForUser($request->user(), $validated);

        return response()->json([
            'message'        => 'Fuente de pago creada con éxito',
            'moneyMaker'     => $data['moneyMaker']->load('currency', 'type'),
            'balance_converted' => $data['convertedBalance'],
            'user_balance'   => $data['userBalance'],
        ], 201);
    }


        public function update(Request $request, MoneyMaker $moneyMaker) {
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|integer|exists:money_maker_types,id',
            'color' => 'required|string',
        ]);
        $moneyMaker->update([
            'name' => $request->name,
            'money_maker_type_id' => $request->type,
            'color' => $request->color,
        ]);
        $moneyMaker->load(['type', 'currency']);
        return response()->json($moneyMaker);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy(Request $request, $id) {
        $moneyMaker = MoneyMaker::where('id', $id)->where('user_id', $request->user()->id)->first();
        if (!$moneyMaker) {
            return response()->json(['message' => 'Fuente de dinero no encontrada'], 404);
        }
        // Si tiene saldo reservado, no se puede eliminar
        if ($moneyMaker->balance_reserved > 0) {
            return response()->json([
                'message' => 'No se puede eliminar una fuente de dinero con saldo reservado'
            ], 400);
        }
        $moneyMaker->active = false;
        $moneyMaker->updated_at = now();
        $request->user()->balance -= $moneyMaker->balance;
        $moneyMaker->save();
        return response()->json(['message' => 'Fuente de dinero eliminada con éxito'], 200);
    }

    public function activate(Request $request, $id) {
        $moneyMaker = MoneyMaker::where('id', $id)->where('user_id', $request->user()->id)->first();
        if (!$moneyMaker) {
            return response()->json(['message' => 'Fuente de dinero no encontrada'], 404);
        }
        $moneyMaker->active = true;
        $moneyMaker->updated_at = now();
        $moneyMaker->save();
        return response()->json(['message' => 'Fuente de dinero activada con éxito'], 200);
    }

}

