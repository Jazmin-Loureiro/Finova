<?php

// Esta es la URL donde tu servidor publicó el WSDL.
// Es la URL de tu controlador + ?wsdl
$wsdl_url = 'http://127.0.0.1:8000/soap?wsdl';

$options = [
    'trace' => 1, // ¡LA CLAVE! Activa el rastreo de la petición
    'exceptions' => 1, // Manejar errores como excepciones
    'cache_wsdl' => WSDL_CACHE_NONE, // No guardar en caché el WSDL (para desarrollo)
    'soap_version' => SOAP_1_1, // Asegúrate que coincida con tu WSDL (SOAP 1.1 o 1.2)
];

echo "Intentando conectar a: $wsdl_url\n\n";

try {
    // 1. Crear el cliente
    $client = new SoapClient($wsdl_url, $options);

    // 2. Llamar a la función del WSDL
    // El cliente leyó el WSDL y ya sabe que existe un método "getAllData"
    echo "Llamando al método getAllData()...\n\n";
    $response = $client->getAllData();

    // 3. Objeto
    // Esta es la respuesta que PHP ya convirtió de XML a Objeto
   // echo "========================================\n";
    //echo "Respuesta PHP (convertida a objeto):\n";
    //echo "========================================\n";
    //print_r($response);

    // 4. 
    
    echo "\n\n========================================\n";
    echo "Petición XML REAL (lo que envió el cliente):\n";
    echo "========================================\n";
    // __getLastRequest() muestra el XML completo que se envió
    echo htmlentities($client->__getLastRequest());


    echo "\n\n========================================\n";
    echo "Respuesta XML REAL (lo que recibió el cliente):\n";
    echo "========================================\n";
    // __getLastResponse() muestra el XML completo que se recibió
    echo htmlentities($client->__getLastResponse());


} catch (SoapFault $e) {
    echo "Error en la llamada SOAP: " . $e->getMessage() . "\n";
    
    // Si hay un error, también puedes intentar ver la última respuesta
    if ($client) {
        echo "\n\nÚltima respuesta (con error):\n";
        echo htmlentities($client->__getLastResponse());
    }
} catch (Exception $e) {
    echo "Error General: " . $e->getMessage() . "\n";
}
?>

