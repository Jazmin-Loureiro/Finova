<?php

namespace App\Http\Controllers;

use App\Models\moneyMaker;
use Illuminate\Http\Request;

class MoneyMakerController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request) {
        $moneyMakers = MoneyMaker::where('user_id', $request->user()->id)->get();
        return response()->json([
            'moneyMakers' => $moneyMakers
        ], 200);
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
            'typeMoney' => 'required|string',
            'color' => 'required|string',
        ]);
        //$moneyMaker = new moneyMaker();
        $moneyMaker = $request->user()->moneyMakers()->create([
            'name' => $request->name,
            'type' => $request->type,
            'balance' => $request->balance,
            'typeMoney' => $request->typeMoney,
            'color' => $request->color,
        ]);

        return response()->json([
            'message' => 'Fuente de pago creada con éxito',
            'data' => $moneyMaker], 201);
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
