<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use App\Services\CurrencyService; // 👈 importante

class UserController extends Controller
{
    // Actualizar usuario autenticado
    public function update(Request $request)
    {
        Log::info('Update user request', $request->all());

        $user = $request->user();

        $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'password' => 'nullable|string|min:6|confirmed',
            'icon' => 'nullable', // 👈 quitamos "image"
            'currencyBase' => 'sometimes|string',
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

        // Solo actualizamos currencyBase, balance se deja como está
        if ($request->filled('currencyBase')) {
            $user->currencyBase = $request->currencyBase;
        }

        $user->fill($request->except(['password', 'icon', 'currencyBase', 'balance']));
        $user->save();
        // 👇 Agregamos balance convertido y símbolo (igual que moneyMakers)
        $symbol = optional(\App\Models\Currency::where('code',$user->currencyBase)->first())->symbol ?? '';
        $balanceConverted = CurrencyService::convert(
            (float)$user->balance,
            'ARS', // ✅ origen fijo
            $user->currencyBase
        );

return response()->json([
    'message' => 'Usuario actualizado',
    'user' => array_merge(
        $user->toArray(),
        [
            'balance_converted' => round($balanceConverted, 2),
            'currency_symbol'   => $symbol,
            'full_icon_url'     => $user->icon ? asset('storage/' . $user->icon) : null,
        ]
    )
]); 
    }

    // Eliminar usuario autenticado
    public function destroy(Request $request)
    {
        $user = $request->user();
        $user->delete();

        return response()->json(['message' => 'Usuario eliminado']);
    }
}
