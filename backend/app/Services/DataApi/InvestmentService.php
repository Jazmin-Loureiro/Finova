<?php

namespace App\Services\DataApi;

use App\Models\DataApi;
use App\Services\CurrencyService;

class InvestmentService
{
    protected BcraService $bcra;
    protected MarketService $market;
    protected CurrencyService $currency;

    public function __construct(BcraService $bcra, MarketService $market, CurrencyService $currency)
    {
        $this->bcra = $bcra;
        $this->market = $market;
        $this->currency = $currency;
    }

    /* ============================================================
    💰 PLAZO FIJO (con fallback automático a CacheService)
    ============================================================ */
    public function simulatePlazoFijo(float $monto = 100000, int $dias = 30): ?array
    {
        $cache = app(CacheService::class);
        $bcra = app(BcraService::class);

        // 🔹 1️⃣ Obtener o refrescar TNA del plazo fijo
        $cachedTna = $cache->rememberOrRefresh(
            'tasa_plazo_fijo',
            'tasa',
            24, // TTL de 24h
            fn() => [
                'balance' => $bcra->getPlazoFijoRate(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/tasa_depositos_30_dias'],
            ]
        );

        $tna = $cachedTna?->balance ?? null;
        if (!$tna) return null;

        // 🔹 2️⃣ Cálculo de rendimiento
        $interes = $monto * ($tna / 100) * ($dias / 365);
        $montoFinal = $monto + $interes;
        $rendimiento = ($montoFinal - $monto) / $monto;

        // 🔹 3️⃣ Inflación mensual para comparativa
        $inflacionRow = $cache->rememberOrRefresh(
            'inflacion_mensual',
            'indicador',
            24,
            fn() => [
                'balance' => $bcra->getInflacionMensual(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/inflacion_mensual_oficial'],
            ]
        );

        $inflacion = $inflacionRow?->balance;
        $comparativa = null;

        if ($inflacion !== null) {
            $resultado = $tna - $inflacion;
            $estado = $resultado > 0 ? 'positivo' : ($resultado < 0 ? 'negativo' : 'neutral');
            $comparativa = [
                'tna'       => round($tna, 2),
                'inflacion' => round($inflacion, 2),
                'resultado' => round($resultado, 2),
                'estado'    => $estado,
            ];
        }

        return [
            'tipo'                   => 'plazo_fijo',
            'tna'                    => round($tna, 2),
            'dias'                   => $dias,
            'monto_inicial'          => round($monto, 2),
            'monto_final_estimado'   => round($montoFinal, 2),
            'rendimiento_estimado_%' => round($rendimiento * 100, 2),
            'comparativa'            => $comparativa,
            'fuente'                 => 'BCRA (cache interno)',
            'descripcion'            => 'Cálculo basado en la TNA promedio cacheada o recién actualizada del BCRA.',
            'ultima_actualizacion'   => optional($cachedTna?->updated_at)->toIso8601String(),
        ];
    }

    /* ============================================================
        📊 Comparativa Plazo Fijo vs Inflación (desde cache)
       ============================================================ */
    public function comparePlazoFijoVsInflacion(?float $tna = null): ?array
    {
        $cache = app(CacheService::class);

        // 🔹 1️⃣ Obtener o refrescar tasa de plazo fijo
        $tasa = $cache->rememberOrRefresh(
            'tasa_plazo_fijo',
            'tasa',
            24, // horas de TTL
            fn() => [
                'balance' => $this->bcra->getPlazoFijoRate(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/tasa_depositos_30_dias'],
            ]
        );

        // 🔹 2️⃣ Obtener o refrescar inflación mensual
        $inflacion = $cache->rememberOrRefresh(
            'inflacion_mensual',
            'indicador',
            24,
            fn() => [
                'balance' => $this->bcra->getInflacionMensual(),
                'fuente'  => 'BCRA',
                'params'  => ['endpoint' => '/inflacion_mensual_oficial'],
            ]
        );

        if (!$tasa?->balance || !$inflacion?->balance) {
            return null; // Si algo falló, salimos
        }

        // 🔹 3️⃣ Calcular la comparativa
        $tnaReal = $tna ?? $tasa->balance;
        $inflacionVal = $inflacion->balance;
        $resultado = $tnaReal - $inflacionVal;
        $estado = $resultado > 0 ? 'positivo' : ($resultado < 0 ? 'negativo' : 'neutral');

        // 🔹 4️⃣ Guardar y devolver el resultado también cacheado
        $comparativa = $cache->rememberOrRefresh(
            'comparativa_pf_inflacion',
            'indicador',
            24,
            fn() => [
                'balance'     => round($resultado, 2),
                'tna'         => round($tnaReal, 2),
                'inflacion'   => round($inflacionVal, 2),
                'resultado'   => round($resultado, 2),
                'estado'      => $estado,
                'fuente'      => 'Finova Cache',
                'descripcion' => 'Comparativa TNA vs inflación mensual (cacheada).',
                'params'      => [
                    'tna'       => round($tnaReal, 2),
                    'inflacion' => round($inflacionVal, 2),
                    'estado'    => $estado,
                ],
            ]
        );

        return [
            'tipo'        => 'comparativa_pf_inflacion',
            'tna'         => round($tnaReal, 2),
            'inflacion'   => round($inflacionVal, 2),
            'resultado'   => round($resultado, 2),
            'estado'      => $estado,
            'fuente'      => 'Finova Cache',
            'descripcion' => 'Comparativa TNA vs inflación mensual (cacheada).',
            'ultima_actualizacion' => optional($comparativa?->updated_at)->toIso8601String(),
        ];
    }



    /* ============================================================
    ₿ CRIPTO (CoinGecko con interés compuesto y fallback)
    ============================================================ */
    public function simulateCrypto(float $monto = 1000, string $coin = 'bitcoin', int $dias = 30, string $monedaBase = 'USD'): ?array
    {
        $cacheKey = "market_cripto_{$coin}";
        $data = DataApi::where('name', $cacheKey)->first();

        if (!$data || !$data->balance) {
            $cache = app(CacheService::class);
            $market = app(MarketService::class);
            $data = $cache->rememberOrRefresh($cacheKey, 'cripto', 3, fn() => $market->getQuote('cripto', $coin));
        }

        if (!$data || !$data->balance) return null;

        $params = $data->params ?? [];
        $priceUsd = (float) $data->balance;

        // 🔹 Conversión a USD si el usuario ingresó en otra moneda
        $currency = app(CurrencyService::class);
        $montoUsd = strtoupper($monedaBase) !== 'USD'
            ? $currency->convert($monto, $monedaBase, 'USD')
            : $monto;

        // 🔹 Variación preferente (30d > 7d > 24h)
        $var = $params['change_percent_30d']
            ?? $params['change_percent_7d']
            ?? $params['change_percent']
            ?? 0;

        $cantidad = $priceUsd > 0 ? $montoUsd / $priceUsd : 0;
        $rendimiento = $var / 100 * ($dias / 30);
        $valorFinalUsd = $montoUsd * (1 + $rendimiento);
        $valorFinalArs = $currency->convert($valorFinalUsd, 'USD', 'ARS');

        return [
            'tipo'                   => 'cripto',
            'activo'                 => strtoupper($coin),
            'precio_usd'             => $priceUsd,
            'variacion_%'            => round($var, 2),
            'dias'                   => $dias,
            'monto_inicial'          => round($montoUsd, 2),
            'monto_inicial_ars'      => round($currency->convert($montoUsd, 'USD', 'ARS'), 2),
            'cantidad_comprada'      => round($cantidad, 6),
            'monto_final_estimado_usd' => round($valorFinalUsd, 2),
            'monto_final_estimado_ars' => round($valorFinalArs, 2),
            'rendimiento_estimado_%' => round($rendimiento * 100, 2),
            'fuente'                 => $data->fuente ?? 'CoinGecko',
            'descripcion'            => 'Simulación basada en variación 30d/7d/24h real cacheada con cantidad comprada y conversión ARS↔USD.',
            'ultima_actualizacion'   => optional($data?->updated_at)->toIso8601String(),
            'extras'                 => $params, // 🔹 Todos los datos extendidos
        ];
    }


    /* ============================================================
    📈 ACCIONES (TwelveData con interés compuesto y fallback)
    ============================================================ */
    public function simulateStock(
        float $monto = 1000,
        string $symbol = 'AAPL',
        int $dias = 30,
        string $monedaBase = 'USD'
    ): ?array {
        $cacheKey = "market_accion_{$symbol}";
        $data = DataApi::where('name', $cacheKey)->first();

        if (!$data || !$data->balance) {
            $cache = app(CacheService::class);
            $market = app(MarketService::class);
            $data = $cache->rememberOrRefresh(
                $cacheKey,
                'accion',
                3,
                fn() => $market->getQuote('accion', $symbol)
            );
        }

        if (!$data || !$data->balance) return null;

        $params = $data->params ?? [];
        $priceUsd = (float) $data->balance;

        // 🔹 Conversión a USD si el usuario ingresó en otra moneda
        $currency = app(CurrencyService::class);
        $montoUsd = strtoupper($monedaBase) !== 'USD'
            ? $currency->convert($monto, $monedaBase, 'USD')
            : $monto;

        // 🔹 Usar rendimiento preferente: YTD > percent_change
        $var = $params['percent_change_ytd']
            ?? $params['change_percent']
            ?? 0;

        // 🔹 Calcular resultados
        $cantidad = $priceUsd > 0 ? $montoUsd / $priceUsd : 0;
        $rendimiento = ($var / 100) * ($dias / 365);
        $valorFinalUsd = $montoUsd * (1 + $rendimiento);
        $valorFinalArs = $currency->convert($valorFinalUsd, 'USD', 'ARS');

        return [
            'tipo'                     => 'accion',
            'symbol'                   => strtoupper($symbol),
            'precio_usd'               => $priceUsd,
            'variacion_%'              => round($var, 2),
            'dias'                     => $dias,
            'monto_inicial'            => round($montoUsd, 2),
            'monto_inicial_ars'        => round($currency->convert($montoUsd, 'USD', 'ARS'), 2),
            'cantidad_comprada'        => round($cantidad, 3),
            'monto_final_estimado_usd' => round($valorFinalUsd, 2),
            'monto_final_estimado_ars' => round($valorFinalArs, 2),
            'rendimiento_estimado_%'   => round($rendimiento * 100, 2),
            'fuente'                   => $data->fuente ?? 'TwelveData',
            'descripcion'              => 'Simulación de acción basada en variación anual (YTD) o diaria con cantidad comprada y conversión ARS↔USD.',
            'ultima_actualizacion'     => optional($data?->updated_at)->toIso8601String(),
            'extras'                   => $params, // 🔹 todos los datos extendidos
        ];
    }


    /* ============================================================
    💵 BONOS (TwelveData con interés compuesto y fallback)
    ============================================================ */
    public function simulateBond(
        float $monto = 1000,
        string $bono = 'TLT',
        int $dias = 30,
        string $monedaBase = 'USD'
    ): ?array {
        $cacheKey = "market_bono_{$bono}";
        $data = DataApi::where('name', $cacheKey)->first();

        if (!$data || !$data->balance) {
            $cache = app(CacheService::class);
            $market = app(MarketService::class);
            $data = $cache->rememberOrRefresh(
                $cacheKey,
                'bono',
                3,
                fn() => $market->getQuote('bono', $bono)
            );
        }

        if (!$data || !$data->balance) return null;

        $params = $data->params ?? [];
        $priceUsd = (float) $data->balance;

        // 🔹 Conversión a USD si el usuario ingresó en otra moneda
        $currency = app(CurrencyService::class);
        $montoUsd = strtoupper($monedaBase) !== 'USD'
            ? $currency->convert($monto, $monedaBase, 'USD')
            : $monto;

        // 🔹 Usar rendimiento preferente: YTD > percent_change > dividend_yield
        $var = $params['percent_change_ytd']
            ?? $params['change_percent']
            ?? ($params['dividend_yield'] ?? 0);

        // 🔹 Calcular resultados
        $cantidad = $priceUsd > 0 ? $montoUsd / $priceUsd : 0;
        $rendimiento = ($var / 100) * ($dias / 365);
        $valorFinalUsd = $montoUsd * (1 + $rendimiento);
        $valorFinalArs = $currency->convert($valorFinalUsd, 'USD', 'ARS');

        return [
            'tipo'                     => 'bono',
            'symbol'                   => strtoupper($bono),
            'precio_usd'               => $priceUsd,
            'variacion_%'              => round($var, 2),
            'dias'                     => $dias,
            'monto_inicial'            => round($montoUsd, 2),
            'monto_inicial_ars'        => round($currency->convert($montoUsd, 'USD', 'ARS'), 2),
            'cantidad_comprada'        => round($cantidad, 3),
            'monto_final_estimado_usd' => round($valorFinalUsd, 2),
            'monto_final_estimado_ars' => round($valorFinalArs, 2),
            'rendimiento_estimado_%'   => round($rendimiento * 100, 2),
            'fuente'                   => $data->fuente ?? 'TwelveData',
            'descripcion'              => 'Simulación de bono basada en variación YTD o rendimiento diario/dividendo, con cantidad comprada y conversión ARS↔USD.',
            'ultima_actualizacion'     => optional($data?->updated_at)->toIso8601String(),
            'extras'                   => $params, // 🔹 todos los datos extendidos
        ];
    }


}
