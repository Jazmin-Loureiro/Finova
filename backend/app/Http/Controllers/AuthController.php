<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Auth\Events\Registered;
use App\Services\CategoryService;


class AuthController extends Controller {
    // Registro de usuario
    public function register(Request $request){
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'icon' => 'nullable|image|max:2048', 
            'currencyBase' => ['required', 'string'],
            'balance' => ['nullable', 'numeric', 'min:0'],
        ]);
        $path = null;
        if ($request->hasFile('icon')) {
            $path = $request->file('icon')->store('icons', 'public');
        }
        $user = User::create([
            'name' => $request->name,
            'email'=> $request->email,
            'password' => Hash::make($request->password),
            'icon' => $path,
            'currencyBase' => $request->currencyBase,
            'balance' => $request->balance ?? 0,
        ]);
        event(new Registered($user));
        $user->moneyMakers()->create([
            'name' => 'Efectivo',
            'type' => 'Efectivo',
            'balance' => $request->balance ?? 0,
            'typeMoney' => 'ARS',
            'color' => '#4CAF50',
            ]);
        // Crear categorías por defecto usando el servicio
        CategoryService::createDefaultForUser($user);
        $user->sendEmailVerificationNotification(); 
        return response()->json([
            'message' => 'Usuario registrado, verifique su email.',
            'user' => $user
        ], 201);
    }

    // Login de usuario
    public function login(Request $request) {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);
        $user = User::where('email', $request->email)->first();
        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Usuario o contraseña incorrectos.'],
            ]);
        }
         if (!$user->hasVerifiedEmail()) {
             return response()->json(['message' => 'Revisa tu cuenta de mail para verificar'], 403);
         }
        $token = $user->createToken('api-token')->plainTextToken;
        return response()->json([
            'user' => $user,
            'token' => $token,
        ], 200);
    }

    // Logout
    public function logout(Request $request) {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out'], 200);
    }

    // Obtener datos del usuario autenticado
    public function user(Request $request) {
        return response()->json($request->user());
    }

    // Verificación de email
    public function verifyEmail(Request $request, $id, $hash) {
        $user = User::findOrFail($id); //buscar usuario por id
        if (!hash_equals((string) $hash, sha1($user->getEmailForVerification()))) { 
            return response()->json(['message' => 'Enlace inválido.'], 403);
        }
        if ($user->hasVerifiedEmail()) { //verificar si ya esta verificado 
            return response()->json(['message' => 'Email ya verificado.']);
        }
        $user->markEmailAsVerified(); //marcar email como verificado esto es de laravel
        return response()->json(['message' => 'Email verificado correctamente.']);
    }
     // Reenviar email de verificación se puede ver a futuro
    public function resendVerification(Request $request) {
        if ($request->user()->hasVerifiedEmail()) { //esta funcion es para reenviar el email de verificacion y es de laravel 
            return response()->json(['message' => 'El email ya está verificado.']);
        }
        $request->user()->sendEmailVerificationNotification();
        return response()->json(['message' => 'Email de verificación reenviado.']);
    }
}
