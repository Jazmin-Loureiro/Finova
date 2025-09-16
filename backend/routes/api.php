<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

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
    
    // Reenviar email de verificación que todavia no se usa
    Route::post('/email/resend', [AuthController::class, 'resendVerification'])
        ->name('verification.send');
});
