<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\DataApi;
use App\Services\CurrencyService;

class HouseController extends Controller
{
    public function getHouseStatus()
    {
        $user = Auth::user();
        $house = $user->house;

        // 🔹 Balance del usuario (siempre guardado en su moneda base)
        $balance = (float) $user->balance;

        // 🔹 Datos de la moneda del usuario
        $currency = $user->currency;
        $code = $currency->code ?? 'ARS';
        $symbol = $currency->symbol ?? '$';

        // ============================================================
        // 🔸 1. Determinar referencia económica según la moneda
        // ============================================================

        // Mapeo básico de moneda → país ISO (para buscar el PPA)
        $countryCode = match ($code) {
            'ARS' => 'AR',
            'USD' => 'US',
            'EUR' => 'DE',
            'BRL' => 'BR',
            'MXN' => 'MX',
            'CLP' => 'CL',
            'COP' => 'CO',
            'GBP' => 'GB',
            'JPY' => 'JP',
            'CNY' => 'CN',
            default => null,
        };

        // 🔹 Buscar valor PPA si existe
        $ppa = $countryCode
            ? DataApi::where('name', 'ppa_' . strtolower($countryCode))
                ->where('status', 'ok')
                ->orderByDesc('last_fetched_at')
                ->first()
            : null;

        // 🔹 Si existe un PPA válido, usarlo como referencia base
        if ($ppa && $ppa->balance > 0) {
            $referencia = [
                'tipo'   => 'ppa',
                'valor'  => $ppa->balance,
                'unidad' => 'PPA'
            ];

            // Convertir balance a USD para mantener coherencia global
            try {
                $balanceRef = CurrencyService::convert($balance, $code, 'USD');
            } catch (\Exception $e) {
                $balanceRef = $balance;
            }
        }
        elseif ($code === 'ARS') {
            // 🇦🇷 Argentina → usar UVA como fallback
            $referencia = [
                'tipo' => 'uva',
                'valor' => $this->getUvaValue(),
                'unidad' => 'UVA'
            ];
            $balanceRef = $balance;
        }
        else {
            // 🌍 Otros países sin PPA → fallback a USD fijo
            try {
                $balanceRef = CurrencyService::convert($balance, $code, 'USD');
            } catch (\Exception $e) {
                $balanceRef = $balance;
            }

            $referencia = [
                'tipo' => 'usd',
                'valor' => 1,
                'unidad' => 'USD'
            ];
        }

        $baseValor = $referencia['valor']; // valor de referencia (PPA, UVA o USD)

        // ============================================================
        // 🔸 2. Escalas (definidas en unidades base)
        // ============================================================
        $limites = [
            'segundo_piso' => 3000 * $baseValor, // desbloqueo medio (~3k unidades)
            'garage'       => 6000 * $baseValor, // desbloqueo alto (~6k unidades)
        ];

        // ============================================================
        // 🔸 3. Reglas de desbloqueo progresivo
        // ============================================================
        if ($balanceRef >= $limites['segundo_piso'] && !$house->unlocked_second_floor) {
            $house->update(['unlocked_second_floor' => true]);
        }

        if ($balanceRef >= $limites['garage'] && !$house->unlocked_garage) {
            $house->update(['unlocked_garage' => true]);
        }

        $desbloqueado = [
            'segundo_piso' => $house->unlocked_second_floor,
            'garage'       => $house->unlocked_garage,
        ];

        // ============================================================
        // 🔸 4. Respuesta final JSON
        // ============================================================
        return response()->json([
            'balance' => number_format($balance, 2, '.', ''),
            'balance_referencia' => number_format($balanceRef, 2, '.', ''),
            'currency_symbol' => $symbol,
            'currency_code' => $code,
            'referencia' => $referencia['unidad'],
            'casa' => [
                'base'      => $this->getBase($desbloqueado),
                'modulos'   => $this->getModulos($desbloqueado, $balanceRef, $baseValor),
                'deterioro' => $this->getDeterioro($balanceRef, $desbloqueado, $baseValor),
                'suelo'     => $this->getSuelo($balanceRef, $baseValor),
            ]
        ]);
    }

    // ============================================================
    // 🔹 TEST API PPA
    // ============================================================
    public function testPPP($countryCode = 'AR')
    {
        $url = str_replace('{ISO_CODE}', $countryCode, env('WORLD_BANK_PPP_URL'));

        $response = Http::withOptions(['verify' => false])->get($url);

        if ($response->failed()) {
            return response()->json(['error' => 'Error al consultar la API'], 500);
        }

        $data = $response->json();

        if (isset($data[1][0]['value'])) {
            return response()->json([
                'country' => $data[1][0]['country']['value'],
                'year' => $data[1][0]['date'],
                'ppa_value' => $data[1][0]['value']
            ]);
        }

        return response()->json(['error' => 'No se encontró valor PPA'], 404);
    }

    // ============================================================
    // 🔹 REFERENCIA UVA (solo Argentina)
    // ============================================================
    private function getUvaValue()
    {
        $registro = DataApi::where('name', 'uva')
            ->where('status', 'ok')
            ->orderByDesc('last_fetched_at')
            ->first();

        return ($registro && $registro->balance > 0)
            ? $registro->balance
            : 350; // fallback aproximado
    }

    // ============================================================
    // 🔹 BASE (estructura principal)
    // ============================================================
    private function getBase($desbloqueado)
    {
        return !empty($desbloqueado['garage'])
            ? 'base/base.svg'
            : 'base/base-centrada.svg';
    }

    // ============================================================
    // 🔹 MÓDULOS (segundo piso, garage)
    // ============================================================
    private function getModulos($desbloqueado, $balance, $valor)
    {
        $modulos = [];

        // Segundo piso
        if (!empty($desbloqueado['segundo_piso'])) {
            $ruina = $balance < 3000 * $valor;
            $modulos[] = !empty($desbloqueado['garage'])
                ? ($ruina ? 'ruinas/segundo-piso.svg' : 'modulos/segundo-piso.svg')
                : ($ruina ? 'ruinas/segundo-piso-centrado.svg' : 'modulos/segundo-piso-centrado.svg');
        }

        // Garage
        if (!empty($desbloqueado['garage'])) {
            $ruina = $balance < 6000 * $valor;
            $modulos[] = $ruina ? 'ruinas/garage.svg' : 'modulos/garage.svg';
        }

        return $modulos;
    }

    // ============================================================
    // 🔹 DETERIOROS (paredes, ventanas, módulos)
    // ============================================================
    private function getDeterioro($balance, $desbloqueado, $valor)
    {
        $layers = [];
        $esCentrada = empty($desbloqueado['garage']);

        // Casa en ruinas totales
        if ($balance <= 0) {
            $layers[] = $esCentrada ? 'deterioro/grieta-pared-centrada.svg' : 'deterioro/grieta-paredes.svg';
            $layers[] = $esCentrada ? 'deterioro/grieta-ventana-centrada.svg' : 'deterioro/grieta-ventanas.svg';
            $layers[] = $esCentrada ? 'deterioro/suciedad-pared-centrada.svg' : 'deterioro/suciedad-paredes.svg';
            $layers[] = $esCentrada ? 'deterioro/suciedad-ventana-centrada.svg' : 'deterioro/suciedad-ventanas.svg';
            return $layers;
        }

        // Deterioro progresivo
        if ($balance < 300 * $valor) {
            $layers[] = $esCentrada ? 'deterioro/grieta-pared-centrada.svg' : 'deterioro/grieta-paredes.svg';
        }
        if ($balance < 700 * $valor) {
            $layers[] = $esCentrada ? 'deterioro/grieta-ventana-centrada.svg' : 'deterioro/grieta-ventanas.svg';
        }
        if ($balance < 1500 * $valor) {
            $layers[] = $esCentrada ? 'deterioro/suciedad-pared-centrada.svg' : 'deterioro/suciedad-paredes.svg';
        }
        if ($balance < 3000 * $valor) {
            $layers[] = $esCentrada ? 'deterioro/suciedad-ventana-centrada.svg' : 'deterioro/suciedad-ventanas.svg';
        }

        // Segundo piso deteriorado si balance bajo
        if (!empty($desbloqueado['segundo_piso']) && $balance >= 3000 * $valor && $balance < 6000 * $valor) {
            $layers[] = $esCentrada ? 'deterioro/segundo-piso-sin-garage.svg' : 'deterioro/segundo-piso.svg';
        }

        // Garage deteriorado
        if (!empty($desbloqueado['garage']) && $balance >= 6000 * $valor && $balance < 10000 * $valor) {
            $layers[] = 'deterioro/garage.svg';
        }

        return $layers;
    }

    // ============================================================
    // 🔹 SUELO (capas y progreso visual)
    // ============================================================
    private function getSuelo($balance, $valor)
    {
        return [
            'vereda' => 'suelos/vereda.svg',
            'capas'  => $this->getCapasSuelo($balance, $valor),
        ];
    }

    private function getCapasSuelo($balance, $valor)
    {
        $capas = [];

        if ($balance <= 0) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas3.svg';
        } elseif ($balance < 300 * $valor) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
        } elseif ($balance < 700 * $valor) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
        } elseif ($balance < 1500 * $valor) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas3.svg';
        } elseif ($balance < 3000 * $valor) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
        } elseif ($balance < 4500 * $valor) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
        } elseif ($balance < 6000 * $valor) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
        } elseif ($balance < 8000 * $valor) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
        } elseif ($balance < 10000 * $valor) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
            $capas[] = 'suelos/pasto-florecido/flores1.svg';
        } else {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto5.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto6.svg';
            $capas[] = 'suelos/pasto-florecido/flores1.svg';
            $capas[] = 'suelos/pasto-florecido/flores2.svg';
            $capas[] = 'suelos/pasto-florecido/flores3.svg';
        }

        return $capas;
    }
}
