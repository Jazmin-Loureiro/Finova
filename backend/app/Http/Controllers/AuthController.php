<?php

namespace App\Http\Controllers;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Auth\Events\Registered;
use App\Services\CategoryService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

// 🔹 Importaciones nuevas para el mail personalizado
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Config;
use App\Mail\VerifyEmailMail;

class AuthController extends Controller
{
    // 🔹 Registro de usuario
    public function register(Request $request)
    {
        $cashType = \App\Models\MoneyMakerType::firstOrCreate( // 
            ['name' => 'Efectivo'],
            ['description' => 'Dinero físico disponible.', 'active' => true]
        );
        
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'icon' => 'nullable',
            'currency_id' => ['required', 'exists:currencies,id'],
            'balance' => ['nullable', 'numeric', 'min:0'],
        ]);

        $path = null;
        if ($request->hasFile('icon')) {
            $path = $request->file('icon')->store('icons', 'public');
        } elseif ($request->filled('icon')) {
            $path = $request->icon;
        } else {
            $path = 'default_seed';
        }

        $user = User::create([
            'name' => $request->name,
            'email'=> $request->email,
            'password' => Hash::make($request->password),
            'icon' => $path,
            'currency_id' => $request->currency_id,
            'balance' => $request->balance ?? 0,
            'points' => 0,   // 🆕 inicializa
            'level' => 1,    // 🆕 inicializa
        ]);

        // Crear casa inicial
        $user->house()->create([
            'unlocked_second_floor' => false,
            'unlocked_garage' => false,
        ]);

        // Crear fuente de pago "Efectivo"
        $moneyMaker = $user->moneyMakers()->create([
            'name' => 'Efectivo',
            'money_maker_type_id' => $cashType->id,
            'balance' => $request->balance ?? 0,
            'currency_id' => $request->currency_id,
            'color' => '#4CAF50',
        ]);

        // Categorías por defecto
        CategoryService::createDefaultForUser($user);

        // Registro de saldo inicial
        if ($request->balance && $request->balance > 0) {
            $defaultCategory = $user->categories()->where('name', 'General')->first();
            $user->registers()->create([
                'type' => 'income',
                'balance' => $request->balance,
                'money_maker_id' => $moneyMaker->id,
                'currency_id' => $request->currency_id,
                'name' => 'Saldo inicial',
                'category_id' => $defaultCategory->id,
            ]);
        }

        // 🔹 Generar URL firmada de verificación
        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify',
            Carbon::now()->addMinutes(Config::get('auth.verification.expire', 60)),
            ['id' => $user->id, 'hash' => sha1($user->getEmailForVerification())]
        );

        // 🔹 Enviar email con plantilla personalizada
        Mail::to($user->email)->send(new VerifyEmailMail($user, $verificationUrl));

        return response()->json([
            'message' => 'Usuario registrado. Verifique su email para activar su cuenta.',
            'user' => $user
        ], 201);
    }

    // 🔹 Login
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);

        // 1) Buscar usuario
        $user = User::where('email', $request->email)->first();

        // 1a) Usuario NO existe
        if (!$user) {
            return response()->json([
                'message' => 'No existe una cuenta registrada con ese correo. Podés crear una nueva cuenta en Finova.'
            ], 404);
        }

        // 2) Password incorrecta (genérico: "correo o contraseña")
        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Correo o contraseña incorrectos. Verificá los datos e intentá nuevamente.'
            ], 401);
        }

        // 3) Cuenta dada de baja
        if (!$user->active) {
            return response()->json([
                'message' => 'Tu cuenta fue dada de baja. Contactá soporte si querés reactivarla.'
            ], 403);
        }

        // 4) Email no verificado
        if (!$user->hasVerifiedEmail()) {
            return response()->json([
                'message' => 'Revisá tu correo para verificar tu cuenta antes de ingresar.'
            ], 403);
        }

        // 5) OK → token
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'icon' => $user->icon,
                'balance' => $user->balance,
                'currency_id' => $user->currency_id,
                'points' => $user->points ?? 0, // 🆕
                'level' => $user->level ?? 1,   // 🆕
                'last_challenge_refresh' => optional($user->last_challenge_refresh)?->toIso8601String(),
            ],
            'token' => $token,
        ], 200);

    }



    // 🔹 Logout
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Sesión cerrada correctamente.'], 200);
    }

    // 🔹 Obtener usuario autenticado
    public function user(Request $request)
    {
        $user = $request->user();
        $currency = $user->currency;
        return response()->json([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'icon' => $user->icon,
            'balance' => $user->balance,
            'currency_id' => $user->currency_id,
            'currency_symbol' => $currency->symbol ?? '',
            'points' => $user->points ?? 0,
            'level' => $user->level ?? 1,
            'full_icon_url' => $user->icon ? asset('storage/' . $user->icon) : null,
            'created_at' => optional($user->created_at)?->toIso8601String(),
            'last_challenge_refresh' => optional($user->last_challenge_refresh)?->toIso8601String(),
        ]);
    }


    // 🔹 Verificación del email
    public function verifyEmail(Request $request, $id, $hash)
    {
        $user = User::findOrFail($id);

        // 🔴 Link inválido
        if (!hash_equals((string) $hash, sha1($user->getEmailForVerification()))) {
            return response()->view('email_invalid');
        }

        // 📬 Ya verificado
        if ($user->hasVerifiedEmail()) {
            return response()->view('email_already_verified');
        }

        // ✅ Verificación correcta
        $user->markEmailAsVerified();

        return response()->view('email_verified');
    }

    // 🔹 Reenviar email de verificación
    public function resendVerification(Request $request)
    {
        if ($request->user()->hasVerifiedEmail()) {
            return response()->json(['message' => 'El email ya está verificado.']);
        }

        // Volver a generar el enlace
        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify',
            Carbon::now()->addMinutes(Config::get('auth.verification.expire', 60)),
            ['id' => $request->user()->id, 'hash' => sha1($request->user()->getEmailForVerification())]
        );

        Mail::to($request->user()->email)->send(new VerifyEmailMail($request->user(), $verificationUrl));

        return response()->json(['message' => 'Te enviamos un nuevo correo de verificación. Revisá tu bandeja de entrada.']);
    }

    // 🔹 Reenviar email de verificación sin login (solo con email)
    public function resendVerificationByEmail(Request $request)
    {
        $request->validate(['email' => 'required|email']);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json(['message' => 'No se encontró un usuario con ese correo.'], 404);
        }

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => 'El correo ya fue verificado.']);
        }

        $verificationUrl = URL::temporarySignedRoute(
            'verification.verify',
            Carbon::now()->addMinutes(Config::get('auth.verification.expire', 60)),
            ['id' => $user->id, 'hash' => sha1($user->getEmailForVerification())]
        );

        Mail::to($user->email)->send(new VerifyEmailMail($user, $verificationUrl));

        return response()->json(['message' => 'Te enviamos un nuevo correo de verificación. Revisá tu bandeja.']);
    }


    public function forgotPassword(Request $request) {
        $request->validate([
            'email' => 'required|email'
        ]);
        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json([
                'status' => 'passwords.user'
            ], 200);
        }
        //  Generar token plano
        $token = Str::random(64);

        //  Guardarlo en la tabla (hasheado)
        DB::table('password_resets')->updateOrInsert(
            ['email' => $request->email],
            ['email' => $request->email,
            'token' => Hash::make($token),
            'created_at' => now()
            ]
        );
        //  Link de recuperación
        $url = "finova://reset-password?token={$token}&email={$request->email}";

        Mail::html("
            <p>Hola {$user->name}!  Has olvidado tu contraseña?</p>
            <p>Para restablecer tu contraseña en <b>Finova</b>, hacé clic en el siguiente botón:</p>
            <p>
                <a href=\"{$url}\"
                style=\"display:inline-block;padding:10px 18px;
                        background-color:#7D2FFF;color:#ffffff;
                        text-decoration:none;border-radius:8px;
                        font-family:sans-serif;font-size:14px;\">
                    Restablecer contraseña
                </a>
            </p>
            <p>
              si no solicitaste este cambio, podés ignorar este correo.
            </p>
        ", function ($m) use ($request) {
            $m->to($request->email)
            ->subject('Recuperación de contraseña - Finova');
        });
        return response()->json([
            'status' => 'passwords.sent'
        ], 200);
    }

    public function resetPassword(Request $request) {
        $request->validate([
            'email' => 'required|email',
            'token' => 'required',
            'password' => 'required|confirmed|min:6'
        ]);

        $record = DB::table('password_resets')->where('email', $request->email)->first();

        if (!$record || !Hash::check($request->token, $record->token)) {
            return response()->json([
                'message' => 'Token inválido o expirado.'
            ], 400);
        }

        // Actualizar contraseña
        $user = User::where('email', $request->email)->first();
        $user->password = Hash::make($request->password);
        $user->updated_at = now();
        $user->save();

        // Borrar token usado
        DB::table('password_resets')->where('email', $request->email)->delete();

        return response()->json([
            'message' => 'Contraseña actualizada correctamente.'
        ], 200);
    }
}
