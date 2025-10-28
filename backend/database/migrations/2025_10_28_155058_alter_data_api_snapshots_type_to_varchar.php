<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('data_api_snapshots', function (Blueprint $table) {
            // 🔹 Cambiar el campo 'type' a VARCHAR(32)
            $table->string('type', 32)->nullable(false)->change();

            // 🔹 Asegurar columnas necesarias (si faltan)
            if (!Schema::hasColumn('data_api_snapshots', 'data')) {
                $table->json('data')->nullable()->after('balance');
            }
            if (!Schema::hasColumn('data_api_snapshots', 'params')) {
                $table->json('params')->nullable()->after('data');
            }
            if (!Schema::hasColumn('data_api_snapshots', 'fuente')) {
                $table->string('fuente')->nullable()->after('params');
            }
            if (!Schema::hasColumn('data_api_snapshots', 'status')) {
                $table->string('status')->nullable()->after('fuente');
            }
            if (!Schema::hasColumn('data_api_snapshots', 'fetched_at')) {
                $table->timestamp('fetched_at')->nullable()->after('status');
            }
        });
    }

    public function down(): void
    {
        Schema::table('data_api_snapshots', function (Blueprint $table) {
            // 🔹 Volver a ENUM (no recomendado, pero por rollback)
            $table->enum('type', [
                'prestamo','inversion','tasa','indicador',
                'cripto','accion','bono','divisa','general','mercado'
            ])->change();

            if (Schema::hasColumn('data_api_snapshots', 'fetched_at')) $table->dropColumn('fetched_at');
            if (Schema::hasColumn('data_api_snapshots', 'status')) $table->dropColumn('status');
            if (Schema::hasColumn('data_api_snapshots', 'fuente')) $table->dropColumn('fuente');
            if (Schema::hasColumn('data_api_snapshots', 'params')) $table->dropColumn('params');
            if (Schema::hasColumn('data_api_snapshots', 'data')) $table->dropColumn('data');
        });
    }
};
