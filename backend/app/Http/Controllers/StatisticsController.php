<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Register;
use App\Models\MoneyMaker;
use App\Services\CurrencyService;

class StatisticsController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $userCurrency = $user->currency;

        $range = (int) $request->query('range', 30); // 7, 30, 365
        $fromDate = now()->startOfDay()->subDays($range);

     $registers = Register::with(['category', 'currency'])
        ->whereHas('moneyMaker', fn($q) => $q->where('user_id', $user->id))
        ->whereHas('category', fn($q) => $q->where('is_system', false))
        ->get();

        // Totales
        $incomeTotals = [];
        $expenseTotals = [];

        $incomeColors = [];
        $expenseColors = [];

        $incomeIcons = [];
        $expenseIcons = [];


        foreach ($registers as $r) {
            $categoryName = $r->category->name ?? 'Sin categoría';
            $amount       = (float) $r->balance;
            $fromCode     = $r->currency->code;

            // Convertir sólo si es necesario
            if ($fromCode !== $userCurrency->code) {
                $amount = CurrencyService::convert($amount,$fromCode,$userCurrency->code);
            }

            if ($r->type === 'income') {
                $incomeTotals[$categoryName] = ($incomeTotals[$categoryName] ?? 0) + $amount;
                $incomeColors[$categoryName] = $r->category->color;
                $incomeIcons[$categoryName] = $r->category->icon;

            } else {
                $expenseTotals[$categoryName] = ($expenseTotals[$categoryName] ?? 0) + $amount;
                $expenseColors[$categoryName] = $r->category->color;
                $expenseIcons[$categoryName] = $r->category->icon;
            }
        }

        $moneyMakers = MoneyMaker::with('currency')->where('user_id', $user->id)->get();
        $balancesByMoneyMaker = [];

        foreach ($moneyMakers as $m) {
            $balancesByMoneyMaker[$m->name] = [
                'amount'   => $m->balance + $m->balance_reserved,
                'currency' => $m->currency->only(['id','code','name','symbol','rate']),
            ];
        }

        $balancesByCurrency = [];

        foreach ($moneyMakers as $m) {
            $code     = $m->currency->code;
            $currency = $m->currency->only(['id','code','name','symbol','rate']);
            $amount   = $m->balance + $m->balance_reserved;

            if (!isset($balancesByCurrency[$code])) {
                $balancesByCurrency[$code] = ['amount'   => 0,'currency' => $currency];
            }
            $balancesByCurrency[$code]['amount'] += $amount;
        }

        return response()->json([
            'range' => $range,
            'user_currency' => $userCurrency->only(['id','code','name','symbol','rate']),
            'totals' => ['income'  => $incomeTotals,'expense' => $expenseTotals],
             
        'colors' => [
            'income'  => $incomeColors,
            'expense' => $expenseColors,
        ],
        'icons' => [
            'income'  => $incomeIcons,
            'expense' => $expenseIcons,
        ],
            'balances' => ['by_currency'     => $balancesByCurrency,'by_money_maker'  => $balancesByMoneyMaker],
        ]);
    }
}
