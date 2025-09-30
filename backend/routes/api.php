<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\HouseController;
use App\Http\Controllers\MoneyMakerController; // Importar el controlador
use App\Http\Controllers\CategoryController; // Importar el controlador
use App\Http\Controllers\RegisterController;
use App\Http\Controllers\UserController;


use App\Http\Controllers\CurrencyController;


// Rutas públicas
// Registro y login
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
// Obtener todas las monedas
Route::get('/currencies', [CurrencyController::class, 'index']);


// Verificación de email
    Route::get('/email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])
        ->name('verification.verify');

// Rutas protegidas (requieren token)
Route::middleware('auth:sanctum')->group(function () {
    // Datos del usuario
    Route::get('/user', [AuthController::class, 'user']);

    // Moneda base del usuario
    Route::get('/userCurrency', function () {
    return response()->json([
        'userBaseCurrency' => auth()->user()->currency_id ,
    ]);
});
    // Logout
    Route::post('/logout', [AuthController::class, 'logout']);
    // Actualizar usuario
    Route::put('/user', [UserController::class, 'update']);
    // Eliminar usuario
    Route::delete('/user', [UserController::class, 'destroy']);
/////////////////////////////////////////////////////////////////////////////////
    //Registrar Ingreso o Gasto
    Route::post('/transactions', [RegisterController::class, 'store']);
    // Obtener todos los ingresos y gastos
    Route::get('/transactions', [RegisterController::class, 'index']);
    // Obtener todos los ingresos y gastos de una fuente de dinero
    Route::get('/transactions/moneyMaker/{moneyMakerId}', [RegisterController::class, 'getByMoneyMaker']);
////////////////////////////////////////////////////////////////////////////////
    //Registrar Fuente de Dinero
    Route::post('/moneyMakers', [MoneyMakerController::class, 'store']);
    // Obtener todas las fuentes de dinero
    Route::get('/moneyMakers', [MoneyMakerController::class, 'index']);
////////////////////////////////////////////////////////////////////////////////
    //Registrar Categoria
    Route::post('/categories', [CategoryController::class, 'store']);
    // Obtener todas las categorias
    Route::get('/categories', [CategoryController::class, 'index']);

////////////////////////////////////////////////////////////////////////////////
    // Reenviar email de verificación que todavia no se usa
    Route::post('/email/resend', [AuthController::class, 'resendVerification'])
        ->name('verification.send');

    // Obtener estado de la casa
    Route::get('/house-status', [HouseController::class, 'getHouseStatus']);

});
