<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\Http;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\DataApi;
use App\Services\CurrencyService;
use App\Models\HouseExtra;

class HouseController extends Controller
{
    public function getHouseStatus()
{
    $user = Auth::user();

    if (!$user) {
        return response()->json(['error' => 'No hay usuario autenticado'], 404);
    }

    $house = $user->house;

    if (!$house) {
        $house = $user->house()->create([
            'unlocked_second_floor' => false,
            'unlocked_garage'       => false,
        ]);
    }

    // 🔹 Balance del usuario en su moneda base
    $balance = (float) $user->balance;

    // 🔹 Datos de la moneda del usuario
    $currency = $user->currency;
    $code    = $currency->code   ?? 'ARS';
    $symbol  = $currency->symbol ?? '$';

    // ============================================================
    // 🔸 1. Convertir SIEMPRE a USD como referencia común
    //     (CurrencyService adentro se encarga de UVA / PPA)
    // ============================================================
    try {
        $balanceUSD = CurrencyService::convert($balance, $code, 'USD');
    } catch (\Exception $e) {
        $balanceUSD = $balance;
    }

    // ============================================================
    // 🔸 2. Obtener PPA / UVA solo para mostrar la referencia
    //     (NO para tocar el balanceRef acá)
    // ============================================================
    $countryMap = [
        'ARS' => 'AR', 'USD' => 'US', 'EUR' => 'DE', 'BRL' => 'BR',
        'MXN' => 'MX', 'CLP' => 'CL', 'COP' => 'CO', 'GBP' => 'GB',
        'JPY' => 'JP', 'CNY' => 'CN',
    ];

    $countryCode = $countryMap[$code] ?? null;

    // PPA
    $ppaValue = null;
    if ($countryCode) {
        $ppaValue = DataApi::where('name', 'ppa_' . strtolower($countryCode))
            ->where('status', 'ok')
            ->orderByDesc('last_fetched_at')
            ->value('balance');
    }

    // UVA solo para Argentina (para referencia visual / info)
    $uvaValue = null;
    if ($code === 'ARS') {
        $uvaValue = $this->getUvaValue();
    }

    // ============================================================
    // 🔸 3. Definir referencia y balance de comparación
    // ============================================================
    // 💵 Balance de referencia SIEMPRE en USD
    $balanceRef = $balanceUSD;


    // Ajuste suave solo para Argentina (sin tocar la conversión)
    if ($code === 'ARS') {
        $balanceRef = $balanceRef * 3.5; 
    }

    // 📌 Texto de referencia que mostrás al usuario
    if ($code === 'ARS') {
        if ($uvaValue) {
            $unidadRef = 'UVA';
        } elseif ($ppaValue) {
            $unidadRef = 'PPA';
        } else {
            $unidadRef = 'USD';
        }
    } else {
        if ($ppaValue) {
            $unidadRef = 'PPA';
        } else {
            $unidadRef = 'USD';
        }
    }

    $baseValor = 1;

    $limites = [
        'segundo_piso' => 3000 * $baseValor,
        'garage'       => 6000 * $baseValor,
    ];

    if ($balanceRef >= $limites['segundo_piso'] && !$house->unlocked_second_floor) {
        $house->update(['unlocked_second_floor' => true]);
    }

    if ($balanceRef >= $limites['garage'] && !$house->unlocked_garage) {
        $house->update(['unlocked_garage' => true]);
    }

    $desbloqueado = [
        'segundo_piso' => (bool) $house->unlocked_second_floor,
        'garage'       => (bool) $house->unlocked_garage,
    ];

    $extras = HouseExtra::orderBy('level_required')
    ->get()
    ->map(function ($extra) use ($user, $desbloqueado) {

        $unlocked = $user->level >= $extra->level_required;

        $tieneGarage = $desbloqueado['garage'] === true;

        // 👇 Regla general para todos los extras:
        // si NO hay garage y existe icon_path_centered → usarlo
        // de lo contrario → icon normal
        $icon = (!$tieneGarage && $extra->icon_path_centered)
            ? $extra->icon_path_centered   // versión centrada
            : $extra->icon_path;           // versión normal

        $registro = $user->unlockedExtras()
            ->where('house_extra_id', $extra->id)
            ->first();

        $alreadyShown = $registro?->pivot?->shown ?? false;

        return [
            'id' => $extra->id,
            'name' => $extra->name,
            'icon' => $icon,
            'level_required' => $extra->level_required,
            'unlocked' => $unlocked,
            'already_shown' => $alreadyShown,
            'z_index' => $extra->z_index,
        ];
    });

    return response()->json([
        'balance'            => number_format($balance, 2, '.', ''),
        'balance_referencia' => number_format($balanceRef, 2, '.', ''),
        'currency_symbol'    => $symbol,
        'currency_code'      => $code,
        'referencia'         => $unidadRef,
        'casa'               => [
            'base'      => $this->getBase($desbloqueado),
            'modulos'   => $this->getModulos($desbloqueado, $balanceRef, $baseValor),
            'deterioro' => $this->getDeterioro($balanceRef, $desbloqueado, $baseValor),
            'suelo'     => $this->getSuelo($balanceRef, $baseValor),
            'extras' => $extras->values()->toArray(),
        ],
    ])
        ->header('Cache-Control', 'no-cache, no-store, must-revalidate')
        ->header('Pragma', 'no-cache')
        ->header('Expires', '0');
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

        // 👉 Garage deterioro progresivo realista
        if (!empty($desbloqueado['garage'])) {

            // Muy deteriorado (recién desbloqueado)
            if ($balance < 7000 * $valor) {
                $layers[] = 'deterioro/garage.svg'; // tu SVG actual de grieta/mancha
            }

            // Punto medio (opcional si tenés otro SVG)
            // elseif ($balance < 10000 * $valor) {
            //     $layers[] = 'deterioro/garage-medio.svg';
            // }

            // Si tiene más de 10k USD → GARAGE LIMPIO
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

    public function markExtraShown(Request $request)
{
    $request->validate([
        'extra_id' => 'required|exists:house_extras,id',
    ]);

    $user = Auth::user();
    $extraId = $request->extra_id;

    // Registrar o actualizar
    $user->unlockedExtras()->syncWithoutDetaching([
        $extraId => ['shown' => true],
    ]);

    return response()->json(['status' => 'ok']);
}
}
