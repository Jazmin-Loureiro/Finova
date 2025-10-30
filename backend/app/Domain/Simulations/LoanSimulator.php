<?php

namespace App\Domain\Simulations;

use InvalidArgumentException;

class LoanSimulator
{
    /**
     * Simula un préstamo personal estándar (Sistema Francés)
     * 
     * @param float $capital   Monto solicitado
     * @param int   $cuotas    Cantidad de cuotas
     * @param float $tna       Tasa Nominal Anual (BCRA)
     * @return array           Resultados de la simulación
     */
    public static function simulate(float $capital, int $cuotas, float $tna): array
    {
        if ($capital < 10000) {
            throw new InvalidArgumentException('El monto mínimo para simular un préstamo es de $10.000.');
        }
        if ($capital > 10000000) {
            throw new InvalidArgumentException('El monto máximo para simular es de $10.000.000.');
        }
        if ($cuotas < 6 || $cuotas > 60) {
            throw new InvalidArgumentException('El número de cuotas debe estar entre 6 y 60.');
        }
        if ($tna <= 0) {
            throw new InvalidArgumentException('La tasa de interés debe ser mayor que 0.');
        }

        // 🔹 Conversión de tasa nominal anual a mensual
        $i = ($tna / 100) / 12;

        // 🔹 Cuota fija (sistema francés)
        $cuota = $capital * $i * pow(1 + $i, $cuotas) / (pow(1 + $i, $cuotas) - 1);

        $saldo = $capital;
        $detalle = [];

        // 🔹 Generar detalle educativo cuota por cuota
        for ($n = 1; $n <= $cuotas; $n++) {
            $interes = $saldo * $i;
            $amortizacion = $cuota - $interes;
            $saldo -= $amortizacion;

            $detalle[] = [
                'n' => $n,
                'interes' => round($interes, 2),
                'capital' => round($amortizacion, 2),
                'cuota' => round($cuota, 2),
                'saldo' => max(round($saldo, 2), 0),
            ];
        }

        $total = $cuota * $cuotas;
        $intereses = $total - $capital;
        $cft = ($total / $capital - 1) * 100;

        return [
        'capital' => round($capital, 2),
        'cuotas' => $cuotas,
        'tna' => round($tna, 2),
        'tasa_mensual' => round($i * 100, 2),
        'cuota_mensual' => round($cuota, 2),
        'total_a_pagar' => round($total, 2),
        'intereses_totales' => round($intereses, 2),
        'cft_estimado' => round($cft, 2),
        'fuente' => 'BCRA',
        'mensaje' => 'Simulación informativa. No constituye una oferta real de crédito.',
        'detalle_cuotas' => $detalle,

        // 👇 NUEVO BLOQUE COMPATIBLE (sin romper nada)
        'tipo' => 'prestamo',
        'monto_inicial' => round($capital, 2),
        'monto_final_estimado' => round($total, 2),
    ];

    }
}
