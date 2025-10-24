<?php

namespace App\Services\DataApi;

class InvestmentService
{
    protected BcraService $bcra;

    public function __construct(BcraService $bcra)
    {
        $this->bcra = $bcra;
    }

    /**
     * 💰 Simulación de plazo fijo tradicional (en pesos)
     * basada en la TNA promedio publicada por el BCRA.
     * Este método replica el funcionamiento real de los bancos:
     * la tasa nominal anual (TNA) es fija, y el interés varía
     * únicamente según el monto y los días de inversión.
     */
    public function simulatePlazoFijo(float $monto = 100000, int $dias = 30): ?array
    {
        // 🔹 Obtener la TNA promedio del BCRA (valor real diario)
        $tna = $this->bcra->getPlazoFijoRate(); // Ejemplo: ≈70%
        if (!$tna) return null;

        // 🔹 Cálculo del interés simple proporcional a los días invertidos
        // Fórmula: interés = monto × (TNA/100) × (días/365)
        $interes = $monto * ($tna / 100) * ($dias / 365);

        // 🔹 Monto final que recibiría el usuario al finalizar el plazo
        $montoFinal = $monto + $interes;

        // 🔹 Retornar estructura completa compatible con el frontend
        return [
            'tipo'         => 'plazo_fijo',
            'tna'          => round($tna, 2),
            'dias'         => $dias,
            'monto'        => round($monto, 2),
            'interes'      => round($interes, 2),
            'monto_final'  => round($montoFinal, 2),
            'fuente'       => 'BCRA',
            'descripcion'  => 'Simulación educativa de un plazo fijo tradicional. '
                            . 'La tasa es fija y refleja el funcionamiento real de los bancos: '
                            . 'el interés depende únicamente del tiempo que el dinero permanece invertido.',
            'detalles'     => [
                'tna_base_bcra' => round($tna, 2),
                'metodo' => 'interes_simple_proporcional',
            ],
        ];
    }

    /**
     * 📈 Comparativa Plazo Fijo vs Inflación
     * Ahora usa la misma TNA que el simulador para mantener coherencia.
     */
    public function comparePlazoFijoVsInflacion(?float $tna = null): ?array
    {
        // Si no se pasa una TNA desde la simulación, usar la del BCRA
        $tnaReal = $tna ?? $this->bcra->getPlazoFijoRate();
        $inflacion = $this->bcra->getInflacionMensual();

        if (!$tnaReal || !$inflacion) return null;

        // Comparar la tasa nominal anual contra la inflación mensual proyectada
        $resultado = $tnaReal - $inflacion;
        $estado = $resultado > 0 ? 'positivo' : ($resultado < 0 ? 'negativo' : 'neutral');

        return [
            'tipo'        => 'comparativa_pf_inflacion',
            'tna'         => round($tnaReal, 2),
            'inflacion'   => round($inflacion, 2),
            'resultado'   => round($resultado, 2),
            'estado'      => $estado,
            'fuente'      => 'BCRA',
            'descripcion' => 'Comparativa entre la TNA utilizada en la simulación y la inflación mensual publicada por el BCRA. '
                            . 'Permite analizar si el rendimiento del plazo fijo supera o no la inflación actual.',
        ];
    }
}
