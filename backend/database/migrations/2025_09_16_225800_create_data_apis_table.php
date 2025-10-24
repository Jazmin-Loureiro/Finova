<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('data_apis', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // ej: prestamo_personal_tna, plazo_fijo_tna, usd_of, btc_ars, AAPL_usd_close
            $table->enum('type', ['prestamo', 'inversion']);
            $table->decimal('balance', 16, 6)->nullable(); // tasa/precio/valor base
            $table->json('params')->nullable(); // {"currency":"ARS","window":"30d"}
            $table->string('fuente')->nullable(); // BCRA | CoinGecko | AlphaVantage
            $table->timestamps();

            $table->unique(['name']);
        });
    }

    public function down(): void {
        Schema::dropIfExists('data_apis');
    }
};
