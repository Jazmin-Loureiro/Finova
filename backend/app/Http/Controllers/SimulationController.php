<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\DataApi\BcraService;
use App\Services\DataApi\CacheService;
use App\Services\DataApi\InvestmentService;
use App\Services\DataApi\MarketService;
use App\Domain\Simulations\LoanSimulator;

class SimulationController extends Controller
{
    protected BcraService $bcra;
    protected CacheService $cache;
    protected InvestmentService $investment;
    protected MarketService $market;

    public function __construct(BcraService $bcra, CacheService $cache, InvestmentService $investment, MarketService $market)
    {
        $this->bcra = $bcra;
        $this->cache = $cache;
        $this->investment = $investment;
        $this->market = $market;
        
        // 🟣 Middleware de autenticación con Sanctum
        $this->middleware('auth:sanctum');
    }

    /** 💳 Simulación de préstamo (BCRA TNA) */
    public function simulateLoan(Request $request)
    {
        $request->validate([
            'capital' => 'required|numeric|min:10000|max:10000000',
            'cuotas'  => 'required|integer|min:6|max:60',
        ]);

        $tna = \App\Models\DataApi::where('name', 'tasa_prestamos_personales')->first()?->balance;
        $ultimaActualizacion = \App\Models\DataApi::where('name', 'tasa_prestamos_personales')->first()?->updated_at;
        if (!$tna) {
            return response()->json(['error' => 'No se pudo obtener la tasa del BCRA'], 503);
        }

        $result = LoanSimulator::simulate((float) $request->capital, (int) $request->cuotas, $tna);
        $result['tna'] = $tna;
        $result['ultima_actualizacion'] = $ultimaActualizacion;
        $result['fuente'] = 'BCRA';
        return response()->json($result);
    }

    /** 💰 Plazo fijo */
    public function simulatePlazoFijo(Request $request)
    {
        $monto = (float) $request->input('monto', 100000);
        $dias  = (int) $request->input('dias', 30);

        // 👉 Simulación base
        $data = $this->investment->simulatePlazoFijo($monto, $dias);

        if (!$data) {
            return response()->json(['error' => 'No se pudo calcular el plazo fijo'], 503);
        }

        // 🧮 Comparativa con inflación (usa la TNA del cálculo anterior)
        $comparativa = $this->investment->comparePlazoFijoVsInflacion($data['tna'] ?? null);
        $data['comparativa'] = $comparativa;

        // 📅 Incluimos fecha de actualización de BCRA si existe
        $tnaRow = \App\Models\DataApi::where('name', 'tasa_plazo_fijo')->first();
        if ($tnaRow && $tnaRow->updated_at) {
            $data['ultima_actualizacion'] = $tnaRow->updated_at->toIso8601String();
        }

        return response()->json($data);
    }


    /** 📈 Cripto */
    public function simulateCrypto(Request $request)
    {
        $data = $this->investment->simulateCrypto(
            $request->input('monto', 1000),
            $request->input('coin', 'bitcoin'),
            $request->input('dias', 30)
        );
        return $data ? response()->json($data) : response()->json(['error' => 'No se pudo calcular la simulación cripto'], 503);
    }

    /** 📊 Acciones */
    public function simulateStock(Request $request)
    {
        $data = $this->investment->simulateStock(
            $request->input('monto', 1000),
            $request->input('symbol', 'AAPL'),
            $request->input('dias', 30)
        );
        return $data ? response()->json($data) : response()->json(['error' => 'No se pudo calcular la simulación de acción'], 503);
    }

    /** 💵 Bonos */
    public function simulateBond(Request $request)
    {
        $data = $this->investment->simulateBond(
            $request->input('monto', 1000),
            $request->input('bono', 'TLT'),
            $request->input('dias', 30)
        );
        return $data ? response()->json($data) : response()->json(['error' => 'No se pudo calcular la simulación de bono'], 503);
    }

    /** 🔍 Cotización directa en vivo */
    public function marketQuote(string $type, string $symbol)
    {
        $data = $this->market->getQuote($type, $symbol);
        return $data ? response()->json($data) : response()->json(['error' => 'No se encontró el activo'], 404);
    }
}
