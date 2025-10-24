<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('data_apis', function (Blueprint $table) {
            // Ajustamos precisión de balance
            $table->decimal('balance', 16, 6)->nullable()->change();

            // Agregamos los nuevos campos si no existen
            if (!Schema::hasColumn('data_apis', 'params')) {
                $table->json('params')->nullable()->after('balance');
            }

            if (!Schema::hasColumn('data_apis', 'fuente')) {
                $table->string('fuente')->nullable()->after('params');
            }
        });
    }

    public function down(): void
    {
        Schema::table('data_apis', function (Blueprint $table) {
            if (Schema::hasColumn('data_apis', 'fuente')) {
                $table->dropColumn('fuente');
            }
            if (Schema::hasColumn('data_apis', 'params')) {
                $table->dropColumn('params');
            }
            $table->decimal('balance', 12, 2)->nullable()->change();
        });
    }
};
