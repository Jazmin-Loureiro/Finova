@component('mail::message')
# <span style="color:#673AB7;">¡Bienvenida/o a Finova! 💜</span>

Hola **{{ $user->name }}**,

Gracias por registrarte en **Finova**.  
Solo falta un paso para activar tu cuenta y empezar a gestionar tus finanzas de forma más inteligente.

@component('mail::button', ['url' => $verificationUrl, 'color' => 'primary'])
<span style="color:white; padding:10px 18px; border-radius:6px; text-decoration:none;">Verificar mi cuenta</span>
@endcomponent

Si no creaste esta cuenta, podés ignorar este correo.

Gracias por unirte a nuestra comunidad 🙌  
El equipo de **Finova**
@endcomponent
