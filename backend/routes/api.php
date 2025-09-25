<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\MoneyMakerController; // Importar el controlador
use App\Http\Controllers\CategoryController; // Importar el controlador
use App\Http\Controllers\RegisterController;
// Rutas públicas
// Registro y login
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Verificación de email
    Route::get('/email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])
        ->name('verification.verify');

// Rutas protegidas (requieren token)
Route::middleware('auth:sanctum')->group(function () {
    
    // Datos del usuario
    Route::get('/user', [AuthController::class, 'user']);
    // Logout
    Route::post('/logout', [AuthController::class, 'logout']);
/////////////////////////////////////////////////////////////////////////////////
    //Registrar Ingreso o Gasto
    Route::post('/transactions', [RegisterController::class, 'store']);
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
///////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
    // Reenviar email de verificación que todavia no se usa
    Route::post('/email/resend', [AuthController::class, 'resendVerification'])
        ->name('verification.send');
});
