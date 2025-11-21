<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\HouseController;
use App\Http\Controllers\MoneyMakerController; // Importar el controlador
use App\Http\Controllers\CategoryController; // Importar el controlador
use App\Http\Controllers\RegisterController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ChallengeController;
use App\Http\Controllers\UserChallengeController;
use App\Http\Controllers\GamificationController;
use App\Http\Controllers\GoalController;
use App\Http\Controllers\SimulationController;
use App\Http\Controllers\DataApiReadController;
use App\Http\Controllers\StatisticsController;
///////////////////////////////////////////////////

////////////////////////////////////////////////////
use App\Http\Controllers\CurrencyController;


// Rutas públicas
// Recuperación de contraseña
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);
// Registro y login
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
// Obtener todas las monedas
Route::get('/currencies', [CurrencyController::class, 'index']);

// 🔹 Nueva ruta pública para pedir reactivación
Route::post('/users/request-reactivation', [UserController::class, 'requestReactivation']);

// Verificación de email
    Route::get('/email/verify/{id}/{hash}', [AuthController::class, 'verifyEmail'])
        ->name('verification.verify');

// Ruta para reenviar el email de verificación
    Route::post('/resend-verification', [AuthController::class, 'resendVerificationByEmail']);


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
    // Obtener un ingreso o gasto específico
    Route::get('/transactions/{register}', [RegisterController::class, 'show']);
    //cancelar reserva
    Route::post('/reservations/{register}', [RegisterController::class, 'cancelReservation']);
////////////////////////////////////////////////////////////////////////////////
    //Registrar Fuente de Dinero
    Route::post('/moneyMakers', [MoneyMakerController::class, 'store']);
    // Obtener todas las fuentes de dinero
    Route::get('/moneyMakers', [MoneyMakerController::class, 'index']);
    //Editar Fuente de Dinero
    Route::put('/moneyMakers/{moneyMaker}', [MoneyMakerController::class, 'update']);
    //Eliminar Fuente de Dinero
    Route::delete('/moneyMakers/{moneyMaker}', [MoneyMakerController::class, 'destroy']);
    //Reactivar Fuente de Dinero
    Route::post('/moneyMakers/{id}/activate', [MoneyMakerController::class, 'activate']);
    // Obtener tipos de fuente de dinero
    Route::get('/moneyMakerTypes', [\App\Http\Controllers\MoneyMakerTypeController::class, 'index']);
////////////////////////////////////////////////////////////////////////////////
    //Registrar Categoria
    Route::post('/categories', [CategoryController::class, 'store']);
    // Obtener todas las categorias
    Route::get('/categories', [CategoryController::class, 'index']);
    // Actualizar categoria
    Route::put('/categories/{id}', [CategoryController::class, 'update']);
    // Eliminar categoria
    Route::delete('/categories/{id}', [CategoryController::class, 'destroy']);

    /////////////////////////////////////////////////////////////////////////////
    Route::get('/statistics', [StatisticsController::class, 'index']);
    
////////////////////////////////////////////////////////////////////////////////
    // Reenviar email de verificación que todavia no se usa
    Route::post('/email/resend', [AuthController::class, 'resendVerification'])
        ->name('verification.send');

    // Obtener estado de la casa
    Route::get('/house-status', [HouseController::class, 'getHouseStatus']);

    // Obtener extras desbloqueados de la casa
    Route::post('/house/extras/mark-shown', [HouseController::class, 'markExtraShown']);

    // 💪 Desafíos
    // 🔹 Desafíos base
    Route::get('/challenges/available', [ChallengeController::class, 'available']);
    Route::post('/challenges/refresh', [ChallengeController::class, 'refresh']);

    // 🔹 Desafíos del usuario
    Route::post('/user-challenges/{id}/accept', [UserChallengeController::class, 'accept']);

    // 🔹 Perfil de gamificación (nuevo endpoint principal)
    Route::get('/gamification/profile', [GamificationController::class, 'profile']);
////////////////////////////////////////////////////////////////
    //Metas
    Route::get('goals/expired', [GoalController::class, 'getExpiredGoals']);

    Route::get('goals', [GoalController::class, 'index']);
    Route::post('goals', [GoalController::class, 'store']);
    Route::post('goals/assign-reserved', [GoalController::class, 'assignReservedToMoneyMakers']);
    Route::put('goals/{goal}', [GoalController::class, 'update']);
    Route::delete('goals/{goal}', [GoalController::class, 'delete']);
    Route::get('goals/{goal}/registers', [GoalController::class, 'fetchRegistersByGoal']);
    Route::get('goals/{goal}', [GoalController::class, 'show']);
    });

    // 📊 Rutas para simulaciones de préstamos e inversiones
    Route::prefix('/simulate')->group(function () {

        // 💳 Préstamos personales
        Route::post('/loan', [SimulationController::class, 'simulateLoan']);

        // 💰 Plazo fijo tradicional (en pesos)
        Route::get('/plazo-fijo', [SimulationController::class, 'simulatePlazoFijo']);

        // 📈 Comparativa Plazo Fijo vs Inflación
        Route::get('/comparativa', [SimulationController::class, 'comparePlazoFijoVsInflacion']);

        // 🔷 CRIPTO / ACCIONES / BONOS
        Route::post('/crypto', [SimulationController::class, 'simulateCrypto']);
        Route::post('/stock',  [SimulationController::class, 'simulateStock']);
        Route::post('/bond',   [SimulationController::class, 'simulateBond']);

    });

    Route::get('/dataapi/current/{name}', [DataApiReadController::class, 'current']);
    Route::get('/dataapi/history/{name}', [DataApiReadController::class, 'history']);
    Route::get('/dataapi/by-type/{type}', [DataApiReadController::class, 'byType']);

    // 🔍 Cotización directa en vivo
    Route::get('/market/{type}/{symbol}', [SimulationController::class, 'marketQuote']);


///////////////////////////////////////////// FRAMEWORK SOAP /////////////////////////////////////////////

/**Ruta para el manejo de solicitudes SOAP */
use App\Http\Controllers\ServicesSoap\ServicesSoapController;
Route::any('/soap', [ServicesSoapController::class, 'handle']);

/**Ruta para API REST */
use App\Http\Controllers\ServicesSoap\SoapWrapperController;
Route::get('/soap/investment-rates', [SoapWrapperController::class, 'getInvestmentRates']);


