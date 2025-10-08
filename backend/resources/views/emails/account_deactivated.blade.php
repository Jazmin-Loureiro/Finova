@component('mail::message')
# <span style="color:#673AB7;">Tu cuenta fue dada de baja 💤</span>

Hola **{{ $user->name }}**,

Tu cuenta en **Finova** ha sido desactivada correctamente.  
A partir de ahora, no podrás acceder a la app ni gestionar tus finanzas desde tu cuenta.

Si esta acción fue un error, o si en el futuro deseás volver a utilizar **Finova**,  
podés solicitar la **reactivación** directamente desde la app o escribiéndonos a  
**finovaapp.contacto@gmail.com** 💌

Gracias por haber sido parte de nuestra comunidad 💜  
El equipo de **Finova**
@endcomponent
