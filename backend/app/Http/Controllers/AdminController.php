<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\ReactivationRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use App\Mail\AccountReactivatedMail;
use App\Mail\AccountDeactivatedMail; 

class AdminController extends Controller
{
    public function index()
    {
        $users = User::all();
        $requests = ReactivationRequest::with('user')
                    ->where('processed', false)
                    ->orderBy('requested_at', 'desc')
                    ->get();

        return view('admin.users', compact('users', 'requests'));
    }

    public function activate($id)
    {
        $user = User::findOrFail($id);
        $user->active = true;
        $user->save();

        // Marcar solicitudes como procesadas
        ReactivationRequest::where('user_id', $user->id)->update(['processed' => true]);

        // 📩 Enviar correo al usuario
        Mail::to($user->email)->send(new AccountReactivatedMail($user));

        return redirect()->route('admin.users')->with('success', 'Usuario reactivado y notificado por correo.');
    }

    public function deactivate($id)
    {
        $user = User::findOrFail($id);
        $user->active = false;
        $user->save();

        // 📩 Enviar correo al usuario
        Mail::to($user->email)->send(new \App\Mail\AccountDeactivatedMail($user));

        return redirect()->route('admin.users')->with('success', 'Usuario dado de baja correctamente.');
    }
}
