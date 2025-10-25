<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\DataApi\BcraService;
use App\Services\DataApi\CacheService;
use App\Services\DataApi\InvestmentService;
use App\Domain\Simulations\LoanSimulator;

class SimulationController extends Controller
{
    protected BcraService $bcra;
    protected CacheService $cache;
    protected InvestmentService $investment;

    public function __construct(BcraService $bcra, CacheService $cache, InvestmentService $investment)
    {
        $this->bcra = $bcra;
        $this->cache = $cache;
        $this->investment = $investment;
    }

    /**
     * 💳 Simula un préstamo personal usando la TNA del BCRA
     */
    public function simulateLoan(Request $request)
    {
        $request->validate([
            'capital' => 'required|numeric|min:10000|max:10000000',
            'cuotas'  => 'required|integer|min:6|max:60',
        ]);

        // 🔹 Obtenemos o refrescamos la tasa del BCRA (guardada en cache)
        $tnaRecord = $this->cache->rememberOrRefresh(
            'tasa_prestamos_personales',
            'prestamo',
            24,
            fn() => [
                'balance' => $this->bcra->getLoanRate(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/tasa_prestamos_personales'],
            ]
        );

        $tna = (float) $tnaRecord->balance;

        if (!$tna) {
            return response()->json([
                'error' => 'No se pudo obtener la tasa del BCRA. Intente más tarde.'
            ], 503);
        }

        // 🔹 Ejecutar simulación (cálculo financiero)
        $result = LoanSimulator::simulate(
            (float) $request->capital,
            (int) $request->cuotas,
            $tna
        );

        // 🔹 Agregamos metadatos
        $result['fuente'] = $tnaRecord->fuente;
        $result['ultima_actualizacion'] = $tnaRecord->updated_at;
        $result['endpoint'] = $tnaRecord->params['endpoint'] ?? null;

        return response()->json($result);
    }

    /**
     * 💰 Simula un plazo fijo tradicional (en pesos)
     * usando la TNA promedio del BCRA y comparándola con la inflación.
     */
    public function simulatePlazoFijo(Request $request)
    {
        $request->validate([
            'monto' => 'nullable|numeric|min:1000|max:100000000',
            'dias'  => 'nullable|integer|min:30|max:365',
        ]);

        $monto = $request->input('monto', 100000);
        $dias  = $request->input('dias', 30);

        // 🔹 Ejecutar simulación principal
        $data = $this->investment->simulatePlazoFijo($monto, $dias);

        if (!$data) {
            return response()->json([
                'error' => 'No se pudo obtener la tasa de plazo fijo del BCRA.'
            ], 503);
        }

        // 🔹 Comparativa coherente con la TNA usada en la simulación
        $comparativa = $this->investment->comparePlazoFijoVsInflacion($data['tna'] ?? null);
        $data['comparativa'] = $comparativa;

        // 🔹 Obtener timestamp de actualización BCRA
        $tnaRecord = $this->cache->rememberOrRefresh(
            'tasa_plazo_fijo',
            'plazo_fijo',
            24,
            fn() => [
                'balance' => $this->bcra->getPlazoFijoRate(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/tasa_plazo_fijo'],
            ]
        );

        // 🔹 Adjuntar última actualización al resultado
        $data['ultima_actualizacion'] = $tnaRecord->updated_at ?? now();

        return response()->json($data);
    }

    /**
     * 📈 Comparativa Plazo Fijo vs Inflación (uso independiente)
     * Mantiene compatibilidad con endpoints antiguos.
     */
    public function comparePlazoFijoVsInflacion()
    {
        $data = $this->investment->comparePlazoFijoVsInflacion();

        return $data
            ? response()->json($data)
            : response()->json([
                'error' => 'No se pudieron obtener los datos de inflación o tasa de plazo fijo.'
            ], 503);
    }
}
