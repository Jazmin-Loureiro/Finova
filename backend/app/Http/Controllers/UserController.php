<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Currency;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use App\Services\CurrencyService;
use Illuminate\Support\Facades\Mail;
use App\Models\ReactivationRequest;


class UserController extends Controller
{
    // Actualizar usuario autenticado
    public function update(Request $request)
{
    $user = $request->user();

    $request->validate([
        'name' => 'sometimes|string|max:255',
        'email' => 'sometimes|email|unique:users,email,' . $user->id,
        'password' => 'nullable|string|min:6|confirmed',
        'icon' => 'nullable', // 👈 quitamos "image"
        'currency_id' => 'sometimes|exists:currencies,id',
        'balance' => 'sometimes|numeric|min:0',
    ]);

        // Manejo de icono
        if ($request->hasFile('icon')) {
            // Caso 1: subió foto
            $path = $request->file('icon')->store('icons', 'public');
            $user->icon = $path;
        } elseif ($request->filled('icon')) {
            // Caso 2: mandó un avatarSeed como texto
            $user->icon = $request->icon;
        }

    // Manejo de password
    if ($request->filled('password')) {
        $user->password = Hash::make($request->password);
    }

    // Actualizamos otros campos
    $user->fill($request->except(['password', 'icon', 'currency_id', 'balance']));

    // Manejo de moneda y conversión de balance si cambia
    if ($request->filled('currency_id')) {
        $newCurrency = \App\Models\Currency::find($request->currency_id);
        if ($newCurrency) {
            // Convertimos el balance si cambia la moneda
            if ($user->currency_id != $newCurrency->id) {
                $oldCurrencyCode = optional($user->currency)->code ?? 'ARS';
                $user->balance = CurrencyService::convert(
                    (float)$user->balance,
                    $oldCurrencyCode,
                    $newCurrency->code
                );
            }
            $user->currency_id = $newCurrency->id;
        }
    }

    // Guardamos balance si se envió explícitamente
    if ($request->filled('balance')) {
        $user->balance = $request->balance;
    }

    $user->save();

    // Preparar datos para Flutter
    $currency = \App\Models\Currency::find($user->currency_id);
    $symbol = $currency->symbol ?? '';
    $balanceConverted = CurrencyService::convert(
        (float)$user->balance,
        'ARS', // moneda base de referencia
        $currency->code ?? 'ARS'
    );

    return response()->json([
        'message' => 'Usuario actualizado',
        'user' => array_merge(
            $user->toArray(),
            [
                'balance_converted' => round($balanceConverted, 2),
                'currency_symbol' => $symbol,
                'full_icon_url' => $user->icon ? asset('storage/' . $user->icon) : null,
            ]
        ),
    ]);
}


    // Eliminar usuario autenticado
    public function destroy(Request $request)
    {
        $user = $request->user();
        $user->active = false;
        $user->save();

        // Opcional: cerrar sesión actual
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Cuenta dada de baja correctamente.']);
    }

    public function requestReactivation(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'No existe un usuario con ese email.'], 404);
        }

        if ($user->active) {
            return response()->json(['message' => 'La cuenta ya está activa.'], 400);
        }

        // Guardar en base de datos
        ReactivationRequest::create([
            'user_id' => $user->id,
        ]);

        // Enviar mail al admin
        Mail::raw("El usuario {$user->email} solicitó reactivar su cuenta.", function ($message) {
            $message->to('finovaapp.contacto@gmail.com')
                    ->subject('Solicitud de reactivación de cuenta');
        });

        return response()->json(['message' => 'Solicitud de reactivación enviada. Nos contactaremos pronto.']);
    }


    // Reactivar cuenta (solo admin)
    public function activate($id)
    {
        $user = User::findOrFail($id);

        if ($user->active) {
            return response()->json(['message' => 'El usuario ya está activo.'], 400);
        }

        $user->active = true;
        $user->save();

        return response()->json(['message' => 'Cuenta reactivada correctamente.']);
    }
}