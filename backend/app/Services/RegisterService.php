<?php
namespace App\Services;

use App\Models\Register;
use App\Models\MoneyMaker;
use App\Models\Goal;
use App\Models\Currency;
use Illuminate\Http\Request;
use App\Services\CurrencyService;

class RegisterService {
    /** 
     * Crear un nuevo registro (ingreso o gasto)
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\User  $user
     * @return \App\Models\Register
     */

    public function createRegister(Request $request, $user): Register {
        $filePath = null;
        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $fileName = $file->hashName();
            $file->move(public_path('uploads'), $fileName);
            $filePath = 'uploads/' . $fileName;
        }

        $currency = Currency::findOrFail($request->currency_id);
        $moneyMaker = MoneyMaker::findOrFail($request->money_maker_id);

        $rate = $currency->code === $user->currency->code
            ? 1.0
            : CurrencyService::getRate($currency->code, $user->currency->code);

        $amountInBaseCurrency = $request->balance * $rate;

        $register = $user->registers()->create([
            'type' => $request->type,
            'balance' => $request->balance,
            'file' => $filePath,
            'name' => $request->name ?? null,
            'category_id' => $request->category_id,
            'money_maker_id' => $moneyMaker->id,
            'currency_id' => $currency->id,
            'repetition' => $request->repetition ?? 0,
            'frequency_repetition' => $request->frequency_repetition ?? 0,
            'goal_id' => $request->goal_id,
        ]);

        return $register;
    }
    /** 
     * Actualizar los balances del usuario y la fuente de dinero asociada al registro
     *
     * @param  \App\Models\Register  $register
     * @param  \App\Models\User  $user
     * @return void
     */
    public function updateBalances(Register $register, $user) {
        $moneyMaker = $register->moneyMaker;
        $currency = $register->currency;
        $rate = $currency->code === $user->currency->code
            ? 1.0
            : CurrencyService::getRate($currency->code, $user->currency->code);

        $amountInBaseCurrency = $register->balance * $rate;

        if ($register->goal_id) {
            $goal = $this->forwardGoal($register);
        } else {
            $moneyMaker->balance += $register->type === 'income'
                ? $register->balance
                : -$register->balance;
            $moneyMaker->save();
        }

        $user->balance += $register->type === 'income'
            ? $amountInBaseCurrency
            : -$amountInBaseCurrency;
        $user->save();
        return $goal ?? null;
    }

    /** 
     * Manejar la lógica de avance de una meta cuando se crea un registro asociado
     *
     * @param  \App\Models\Register  $register
     * @return array
     */

    protected function forwardGoal(Register $register) {
            $goal = Goal::findOrFail($register->goal_id);
            $moneyMaker = $register->moneyMaker;
            // Cuánto falta para completar la meta
            $remaining = max(0, $goal->target_amount - $goal->balance);
            // Calcular exceso si el registro es mayor a lo que falta
            $excess = max(0, $register->balance - $remaining);
            // Lo que realmente se reserva para la meta
            $toReserve = $register->balance - $excess;
            // Guardar en el registro cuánto se reservó para esta meta
            $register->reserved_for_goal = $toReserve;
            $register->save();
            // Actualizar el balance reservado y disponible de la fuente
            $moneyMaker->balance_reserved += $toReserve;
            $moneyMaker->balance += $excess;
            $moneyMaker->save();
            // Actualizar progreso de la meta
            $goal->balance += $toReserve;
            if ($goal->balance >= $goal->target_amount) {
                $goal->balance = $goal->target_amount;
                $goal->state = 'completed';
            }
            $goal->save();

            return [
                'goal' => $goal,
                'completed' => $goal->state === 'completed',
            'excess' => $excess,
        ];
    }
}
