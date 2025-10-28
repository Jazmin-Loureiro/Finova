<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('data_apis', function (Blueprint $table) {
            // Cambiar ENUM('prestamo','inversion') => VARCHAR(32)
            $table->string('type', 32)->nullable(false)->change();

            // Asegurar columnas usadas por tu código (si faltaran)
            if (!Schema::hasColumn('data_apis', 'data')) {
                $table->json('data')->nullable()->after('balance');
            }
            if (!Schema::hasColumn('data_apis', 'params')) {
                $table->json('params')->nullable()->after('data');
            }
            if (!Schema::hasColumn('data_apis', 'fuente')) {
                $table->string('fuente')->nullable()->after('params');
            }
            if (!Schema::hasColumn('data_apis', 'status')) {
                $table->string('status')->nullable()->after('fuente');
            }
            if (!Schema::hasColumn('data_apis', 'last_fetched_at')) {
                $table->timestamp('last_fetched_at')->nullable()->after('updated_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('data_apis', function (Blueprint $table) {
            // Rollback al ENUM original (no recomendado, pero por compatibilidad)
            $table->enum('type', ['prestamo', 'inversion'])->change();

            if (Schema::hasColumn('data_apis', 'last_fetched_at')) $table->dropColumn('last_fetched_at');
            if (Schema::hasColumn('data_apis', 'status')) $table->dropColumn('status');
            if (Schema::hasColumn('data_apis', 'fuente')) $table->dropColumn('fuente');
            if (Schema::hasColumn('data_apis', 'params')) $table->dropColumn('params');
            if (Schema::hasColumn('data_apis', 'data')) $table->dropColumn('data');
        });
    }
};
