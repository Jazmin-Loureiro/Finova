<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('house_extras', function (Blueprint $table) {
            // 👉 Nuevo campo opcional para la versión centrada del icono
            $table->string('icon_path_centered')->nullable()->after('icon_path');
        });
    }

    public function down(): void
    {
        Schema::table('house_extras', function (Blueprint $table) {
            $table->dropColumn('icon_path_centered');
        });
    }
};
