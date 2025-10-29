<?php

namespace App\Http\Controllers\ServicesSoap;
use App\Http\Controllers\Controller;

use SoapServer; 
use App\Services\Soap\InvestmentSoapService;

/*ServicesSoapController actúa como un traductor e intermediario automático.
 Convierte solicitudes XML (SOAP) en llamadas a funciones normales de PHP 
 (InvestmentSoapService) y luego convierte las respuestas de vuelta a XML.
*/

class ServicesSoapController extends Controller
{
    public function handle() {
        $wsdl = base_path('public/wsdl/investment.wsdl'); //Definir la ruta al archivo WSDL
        $server = new SoapServer($wsdl); // Crear una instancia de un servidor de objetosSoapServer
        $server->setClass(InvestmentSoapService::class); // Asignar la clase que maneja las solicitudes SOAP
        $server->handle();
    }
}
