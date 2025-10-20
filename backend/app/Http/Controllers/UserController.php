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

        // 🔹 Manejo de icono
        if ($request->hasFile('icon')) {
            // Caso 1: subió foto
            $path = $request->file('icon')->store('icons', 'public');
            $user->icon = $path;
        } elseif ($request->filled('icon')) {
            // Caso 2: mandó un avatarSeed como texto
            $user->icon = $request->icon;
        }

        // 🔹 Manejo de password
        if ($request->filled('password')) {
            $user->password = Hash::make($request->password);
        }

        // 🔹 Actualizamos otros campos (excepto balance/moneda)
        $user->fill($request->except(['password', 'icon', 'currency_id', 'balance']));

        // 🔹 Manejo de moneda y conversión de balance + desafíos
        if ($request->filled('currency_id')) {
            $newCurrency = \App\Models\Currency::find($request->currency_id);
            if ($newCurrency && $user->currency_id != $newCurrency->id) {
                $oldCurrencyCode = optional($user->currency)->code ?? 'ARS';
                $newCode         = $newCurrency->code;

                // 1️⃣ Convertir el balance del usuario
                $user->balance = \App\Services\CurrencyService::convert(
                    (float)$user->balance,
                    $oldCurrencyCode,
                    $newCode
                );

                // 2️⃣ Convertir los desafíos activos/sugeridos a la nueva moneda
                $this->convertUserChallengesToNewCurrency($user, $oldCurrencyCode, $newCode);

                // 3️⃣ Actualizar la moneda del usuario
                $user->currency_id = $newCurrency->id;
            }
        }

        // 🔹 Si el request trae balance explícitamente, lo sobreescribimos
        if ($request->filled('balance')) {
            $user->balance = $request->balance;
        }

        // 🔹 Guardamos cambios
        $user->save();

        // 🔹 Preparar datos para Flutter
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
                    'points' => $user->points ?? 0,
                    'level' => $user->level ?? 1,
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


    /**
     * Convierte todos los desafíos activos/sugeridos del usuario a la nueva moneda base.
     * Evita convertir desafíos de tipo ADD_TRANSACTIONS (porque target es un "count").
     */
    private function convertUserChallengesToNewCurrency(\App\Models\User $user, string $oldCode, string $newCode): void
    {
        $userChallenges = \App\Models\UserChallenge::with('challenge')
            ->where('user_id', $user->id)
            ->whereIn('state', ['suggested', 'in_progress'])
            ->get();

        foreach ($userChallenges as $uc) {
            $type = $uc->challenge?->type ?? null;

            // No convertir cantidades "count"
            $shouldConvertTarget = $type !== 'ADD_TRANSACTIONS';

            // target_amount
            if ($shouldConvertTarget && is_numeric($uc->target_amount ?? null)) {
                $uc->target_amount = \App\Services\CurrencyService::convert(
                    (float)$uc->target_amount,
                    $oldCode,
                    $newCode
                );
            }

            // payload
            $payload = is_array($uc->payload) ? $uc->payload : (json_decode($uc->payload ?? '[]', true) ?: []);

            // Campos de monto a convertir si existen
            $amountFields = ['amount','goal_amount','baseline_expenses','max_allowed','current_spent','total_ahorro'];

            foreach ($amountFields as $field) {
                if (isset($payload[$field]) && is_numeric($payload[$field])) {
                    $payload[$field] = \App\Services\CurrencyService::convert(
                        (float)$payload[$field],
                        $oldCode,
                        $newCode
                    );
                }
            }

            // Actualizar referencia de moneda informativa para el front
            $payload['currency_code']   = $newCode;
            $payload['currency_symbol'] = optional($user->currency)->symbol ?? '$';

            $uc->payload = $payload;
            $uc->save();
        }
    }

}