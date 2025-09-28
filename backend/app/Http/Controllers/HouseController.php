<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HouseController extends Controller
{
    public function getHouseStatus()
    {
        $user = Auth::user();

        // --- TEST ---
        $balance = 00; // cambiar para probar diferentes estados

        // --- REAL ---
        /*
        $ingresos = $user->transactions()->where('tipo', 'ingreso')->sum('monto');
        $gastos = $user->transactions()->where('tipo', 'gasto')->sum('monto');
        $balance = $ingresos - $gastos;
        */

        $desbloqueado = [
            'segundo_piso' => true,
            'garage'       => true,
        ];

        return response()->json([
            'balance' => $balance,
            'casa'    => [
                'base'      => $this->getBase($desbloqueado),
                'modulos'   => $this->getModulos($desbloqueado, $balance),
                'deterioro' => $this->getDeterioro($balance, $desbloqueado),
                'suelo'     => $this->getSuelo($balance),
            ]
        ]);
    }

    // ---------------- BASE ----------------
    private function getBase($desbloqueado)
    {
        if (!empty($desbloqueado['garage'])) {
            return 'base/base.svg'; // corrida
        }

        return 'base/base-centrada.svg'; // sin garage
    }

    // ---------------- MODULOS (normales o ruinas) ----------------
    private function getModulos($desbloqueado, $balance)
    {
        $modulos = [];

        // SEGUNDO PISO
        if (!empty($desbloqueado['segundo_piso'])) {
            if (!empty($desbloqueado['garage'])) {
                // Con garage
                if ($balance < 1000) {
                    $modulos[] = 'ruinas/segundo-piso.svg';
                } else {
                    $modulos[] = 'modulos/segundo-piso.svg';
                }
            } else {
                // Sin garage → centrado
                if ($balance < 1000) {
                    $modulos[] = 'ruinas/segundo-piso-centrado.svg';
                } else {
                    $modulos[] = 'modulos/segundo-piso-centrado.svg';
                }
            }
        }

        // GARAGE
        if (!empty($desbloqueado['garage'])) {
            if ($balance < 3000) {
                $modulos[] = 'ruinas/garage.svg';
            } else {
                $modulos[] = 'modulos/garage.svg';
            }
        }

        return $modulos;
    }

    // ---------------- DETERIOROS ----------------
    private function getDeterioro($balance, $desbloqueado)
    {
        $layers = [];
        $esCentrada = empty($desbloqueado['garage']);

        // BASE en ruina total → todas las capas
        if ($balance <= 0) {
            $layers[] = $esCentrada
                ? 'deterioro/grieta-pared-centrada.svg'
                : 'deterioro/grieta-paredes.svg';

            $layers[] = $esCentrada
                ? 'deterioro/grieta-ventana-centrada.svg'
                : 'deterioro/grieta-ventanas.svg';

            $layers[] = $esCentrada
                ? 'deterioro/suciedad-pared-centrada.svg'
                : 'deterioro/suciedad-paredes.svg';

            $layers[] = $esCentrada
                ? 'deterioro/suciedad-ventana-centrada.svg'
                : 'deterioro/suciedad-ventanas.svg';

            return $layers;
        }

        // --- BASE: progresivo ---
        if ($balance < 500) {
            $layers[] = $esCentrada
                ? 'deterioro/grieta-pared-centrada.svg'
                : 'deterioro/grieta-paredes.svg';
        }
        if ($balance < 1000) {
            $layers[] = $esCentrada
                ? 'deterioro/grieta-ventana-centrada.svg'
                : 'deterioro/grieta-ventanas.svg';
        }
        if ($balance < 2000) {
            $layers[] = $esCentrada
                ? 'deterioro/suciedad-pared-centrada.svg'
                : 'deterioro/suciedad-paredes.svg';
        }
        if ($balance < 3000) {
            $layers[] = $esCentrada
                ? 'deterioro/suciedad-ventana-centrada.svg'
                : 'deterioro/suciedad-ventanas.svg';
        }

        // SEGUNDO PISO: deterioro solo si balance entre 1000 y 3000
        if (!empty($desbloqueado['segundo_piso']) && $balance >= 1000 && $balance < 3000) {
            $layers[] = $esCentrada
                ? 'deterioro/segundo-piso-sin-garage.svg'
                : 'deterioro/segundo-piso.svg';
        }

        // GARAGE: deterioro solo si balance entre 3000 y 6000
        if (!empty($desbloqueado['garage']) && $balance >= 3000 && $balance < 6000) {
            $layers[] = 'deterioro/garage.svg';
        }

        return $layers;
    }

    // ---------------- SUELO ----------------
    private function getSuelo($balance)
    {
        return [
            'vereda' => 'suelos/vereda.svg',
            'capas'  => $this->getCapasSuelo($balance),
        ];
    }

    private function getCapasSuelo($balance)
    {
        $capas = [];

        if ($balance <= 0) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas3.svg';
        }
        elseif ($balance < 300) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
        }
        elseif ($balance < 600) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
        }
        elseif ($balance < 1000) {
            $capas[] = 'suelos/pasto-seco/pasto-seco.png';
            $capas[] = 'suelos/pasto-seco/hierbas-secas1.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas2.svg';
            $capas[] = 'suelos/pasto-seco/hierbas-secas3.svg';
        }
        elseif ($balance < 1500) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
        }
        elseif ($balance < 2000) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
        }
        elseif ($balance < 2500) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
        }
        elseif ($balance < 3000) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
        }
        elseif ($balance < 4000) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
            $capas[] = 'suelos/pasto-florecido/flores1.svg';
        }
        elseif ($balance < 5000) {
            $capas[] = 'suelos/pasto-florecido/pasto-florecido.png';
            $capas[] = 'suelos/pasto-florecido/arbusto1.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto2.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto3.svg';
            $capas[] = 'suelos/pasto-florecido/arbusto4.svg';
            $capas[] = 'suelos/pasto-florecido/flores1.svg';
            $capas[] = 'suelos/pasto-florecido/flores2.svg';
        }
        else {
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
