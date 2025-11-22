<?php

namespace App\Services;

use App\Models\MoneyMaker;
use App\Models\Currency;
use Illuminate\Support\Facades\DB;

class MoneyMakerService
{
    /**
     * Devuelve todas las fuentes de dinero del usuario con balances convertidos.
     */
    public function listForUser($user)
    {
        $toCurrency = $user->currency->code;
        $moneyMakers = $user->moneyMakers()->with('currency', 'type')->orderByDesc('active')->get();

        $totalInBase = 0;

        $result = $moneyMakers->map(function ($m) use ($toCurrency, &$totalInBase) {
            $fromCurrency = $m->currency->code;
            $rate = ($fromCurrency === $toCurrency)
                ? 1.0
                : CurrencyService::getRate($fromCurrency, $toCurrency);

            $balanceConverted = round(($m->balance + $m->balance_reserved) * $rate, 2);
          // Solo sumar si está activa
            if ($m->active) $totalInBase += $balanceConverted;

            return [
                'id'                => $m->id,
                'name'              => $m->name,
                'type'              => $m->type,
                'balance'           => $m->balance,
                'balanceConverted'  => $balanceConverted,
                'balance_reserved'  => $m->balance_reserved,
                'color'             => $m->color,
                'currency'          => $m->currency,
                'active'          => $m->active,
            ];
        });

        $user->update(['balance' => round($totalInBase, 2)]);

        return [
            'moneyMakers'  => $result,
            'totalInBase'  => round($totalInBase, 2),
            'currencyBase' => $toCurrency,
            'symbol'       => $user->currency->symbol ?? '',
        ];
    }

    /**
     * Crea un MoneyMaker y registra el ingreso inicial.
     */
    public function createForUser($user, array $data)
    {
        return DB::transaction(function () use ($user, $data) {
            $fromCurrency = Currency::findOrFail($data['currency_id']);
            $toCurrency   = $user->currency;

            $rate = ($fromCurrency->code === $toCurrency->code)
                ? 1.0
                : CurrencyService::getRate($fromCurrency->code, $toCurrency->code);

            $convertedBalance = round($data['balance'] * $rate, 2);

            $moneyMaker = $user->moneyMakers()->create([
                'name'        => $data['name'],
                'money_maker_type_id' => $data['type'],
                'balance'     => $data['balance'],
                'currency_id' => $fromCurrency->id,
                'color'       => $data['color'],
            ]);

            $category = $user->categories()->where('name', 'General')->first();
if ($data['balance'] > 0) {
            $user->registers()->create([
                'type'          => 'income',
                'balance'       => $data['balance'],
                'money_maker_id' => $moneyMaker->id,
                'currency_id'   => $fromCurrency->id,
                'name'          => 'Saldo inicial',
                'category_id'   => $category?->id,
            ]);
}

            $user->increment('balance', $convertedBalance);

            return [
                'moneyMaker'       => $moneyMaker->load('currency'),
                'convertedBalance' => $convertedBalance,
                'userBalance'      => round($user->balance, 2),
            ];
        });
    }
}
