<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('data_api_snapshots', function (Blueprint $table) {
            $table->id();
            $table->string('name');                 // ej: tasa_prestamos_personales
            $table->string('type');                 // ej: prestamo | inversion | moneda | cripto | indicador
            $table->decimal('balance', 16, 6)->nullable();
            $table->json('params')->nullable();
            $table->string('fuente')->nullable();   // BCRA, etc.
            $table->timestamp('fetched_at')->nullable(); // cuándo se tomó
            $table->unsignedBigInteger('version')->default(1); // versión incremental por name
            $table->boolean('is_current')->default(false);     // flag del vigente
            $table->json('raw_response')->nullable();          // opcional: raw
            $table->string('status')->nullable();              // ok|failed|stale
            $table->timestamps();

            $table->index(['name', 'version']);
            $table->index(['name', 'is_current']);
        });

        // Ajustes en tabla puntero (data_apis)
        Schema::table('data_apis', function (Blueprint $table) {
            if (!Schema::hasColumn('data_apis', 'params')) {
                $table->json('params')->nullable()->after('balance');
            }
            if (!Schema::hasColumn('data_apis', 'fuente')) {
                $table->string('fuente')->nullable()->after('params');
            }
            if (!Schema::hasColumn('data_apis', 'last_fetched_at')) {
                $table->timestamp('last_fetched_at')->nullable()->after('updated_at');
            }
            if (!Schema::hasColumn('data_apis', 'status')) {
                $table->string('status')->nullable()->after('fuente');
            }
            //$table->unique('name', 'data_apis_name_unique');
            if (!Schema::hasColumn('data_apis', 'name')) {
                $table->string('name')->unique('data_apis_name_unique');
            } else {
                // Evitar duplicar el índice si ya existe
                $sm = Schema::getConnection()->getDoctrineSchemaManager();
                $indexes = $sm->listTableIndexes('data_apis');
                if (!array_key_exists('data_apis_name_unique', $indexes)) {
                    $table->unique('name', 'data_apis_name_unique');
                }
            }

        });
    }

    public function down(): void
    {
        Schema::dropIfExists('data_api_snapshots');

        Schema::table('data_apis', function (Blueprint $table) {
            if (Schema::hasColumn('data_apis', 'status')) $table->dropColumn('status');
            if (Schema::hasColumn('data_apis', 'last_fetched_at')) $table->dropColumn('last_fetched_at');
            if (Schema::hasColumn('data_apis', 'fuente')) $table->dropColumn('fuente');
            if (Schema::hasColumn('data_apis', 'params')) $table->dropColumn('params');
            $table->dropUnique('data_apis_name_unique');
        });
    }
};
