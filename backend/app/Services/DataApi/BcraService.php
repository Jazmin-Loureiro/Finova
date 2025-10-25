<?php

namespace App\Services\DataApi;

use Illuminate\Support\Facades\Http;

class BcraService
{
    protected string $baseUrl = 'https://api.estadisticasbcra.com';
    protected string $token;

    public function __construct()
    {
        // 🔹 El token se guarda en el .env
        $this->token = env('BCRA_API_TOKEN', '');
    }

    /**
     * 🔸 Método interno para hacer requests al endpoint del BCRA
     */
    protected function request(string $endpoint)
    {
        if (empty($this->token)) {
            logger()->warning("⚠️ No se encontró BCRA_API_TOKEN en el .env");
            return null;
        }

        $response = Http::withHeaders([
            'Authorization' => 'BEARER ' . $this->token,
        ])->get($this->baseUrl . $endpoint);

        // 🚨 Manejo de token expirado o inválido
        if ($response->status() === 401) {
            logger()->error("⚠️ Token BCRA expirado o inválido al consultar {$endpoint}");
            return 'token_expired'; // Valor especial que interpretará CacheService
        }

        // 🚨 Manejo de error de red o respuesta fallida
        if ($response->failed()) {
            logger()->error("❌ Error al consultar {$endpoint}: " . $response->status());
            return null;
        }

        $data = $response->json();

        if (!is_array($data) || empty($data)) {
            logger()->warning("⚠️ Respuesta vacía o inválida del endpoint {$endpoint}");
            return null;
        }

        // 🔹 Tomamos el valor más reciente (último elemento del array)
        $last = end($data);

        // 🔹 Verificamos que tenga el campo 'v'
        if (!isset($last['v'])) {
            logger()->warning("⚠️ No se encontró el campo 'v' en la respuesta de {$endpoint}");
            return null;
        }

        return (float) $last['v'];
    }

    /**
     * 💳 Tasa de préstamos personales (TNA promedio)
     */
    public function getLoanRate()
    {
        return $this->request('/tasa_prestamos_personales');
    }

    /**
     * 💰 Tasa de plazo fijo (TNA)
     */
    public function getPlazoFijoRate()
    {
        return $this->request('/tasa_depositos_30_dias');
    }

    /**
     * 📈 Inflación mensual (IPC oficial)
     */
    public function getInflacionMensual()
    {
        return $this->request('/inflacion_mensual_oficial');
    }

    /**
     * 💵 Cotización oficial del dólar
     */
    public function getUsdOficial()
    {
        return $this->request('/usd_of');
    }

    /**
     * 🔹 Obtener cualquier indicador dinámico del BCRA
     * Ejemplo: getIndicator('inflacion_interanual_oficial'), getIndicator('merval'), etc.
     */
    public function getIndicator(string $slug)
    {
        // Permite recibir “/merval” o “merval” indistintamente
        $slug = '/' . ltrim($slug, '/');
        return $this->request($slug);
    }

    /**
     * 🏦 Valor de la unidad UVA
     */
    public function getUvaValue()
    {
        return $this->request('/uva');
    }
}
