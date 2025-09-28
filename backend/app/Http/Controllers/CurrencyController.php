<?php

namespace App\Http\Controllers;
use App\Models\Currency;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Request;

class CurrencyController extends Controller{
    // // Obtener todas las monedas
    public function index() {
    $currencies = Currency::all();
    //Devolver lo que está en la base de datos
    return response()->json($currencies);
}


    // Opcional: obtener una moneda específica
    public function show($code) {
        $currency = Currency::find($code);
        if (!$currency) {
            return response()->json(['message' => 'Currency not found'], 404);
        }
        return response()->json($currency);
    }
}
