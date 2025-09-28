<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class UserController extends Controller
{
    // Actualizar usuario autenticado
    public function update(Request $request)
{
    Log::info('Update user request', $request->all());

    $user = $request->user();

    // 👇 log para ver qué llega desde Flutter
    Log::info('Update user request', $request->all());

    $request->validate([
        'name' => 'sometimes|string|max:255',
        'email' => 'sometimes|email|unique:users,email,' . $user->id,
        'password' => 'nullable|string|min:6|confirmed',
        'icon' => 'nullable|image|max:2048',
        'currencyBase' => 'sometimes|string',
        'balance' => 'sometimes|numeric|min:0',
    ]);

    if ($request->hasFile('icon')) {
        $path = $request->file('icon')->store('icons', 'public');
        $user->icon = $path;
    }

    if ($request->filled('password')) {
        $user->password = Hash::make($request->password);
    }

    $user->fill($request->except(['password', 'icon']));
    $user->save();

    return response()->json([
        'message' => 'Usuario actualizado',
        'user' => array_merge(
            $user->toArray(),
            ['full_icon_url' => $user->icon ? asset('storage/' . $user->icon) : null]
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