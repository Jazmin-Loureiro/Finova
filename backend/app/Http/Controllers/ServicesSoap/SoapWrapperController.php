<?php
namespace App\Http\Controllers\ServicesSoap;
use App\Http\Controllers\Controller;

use Illuminate\Http\Request;
use App\Http\Controllers\ServicesSoap\ServicesSoapController;
use App\Services\Soap\InvestmentSoapService;

class SoapWrapperController extends Controller
{
    public function getInvestmentRates()
    {
        try {
            // Llamamos directamente al método de ServicesSoapController
            $rates = (new InvestmentSoapService())->getAllData();
            return response()->json([
                'data' => ['rates' => $rates]
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'Error: ' . $e->getMessage()
            ], 500);
        }
    }
}
