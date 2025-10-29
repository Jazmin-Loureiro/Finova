<?php
namespace App\Services\Soap;

use Illuminate\Support\Facades\DB;

class InvestmentSoapService {
    public function getAllData() {
        return DB::table('data_apis')->get()->toArray();
    }
}
