<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // data_api
        if (!Schema::hasColumn('data_apis', 'data')) {
            Schema::table('data_apis', function (Blueprint $table) {
                // Usá JSON si tu base lo soporta; si no, usa LONGTEXT
                if (method_exists($table, 'json')) {
                    $table->json('data')->nullable()->after('balance');
                } else {
                    $table->longText('data')->nullable()->after('balance');
                }
            });
        }

        // data_api_snapshots
        if (!Schema::hasColumn('data_api_snapshots', 'data')) {
            Schema::table('data_api_snapshots', function (Blueprint $table) {
                if (method_exists($table, 'json')) {
                    $table->json('data')->nullable()->after('balance');
                } else {
                    $table->longText('data')->nullable()->after('balance');
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('data_apis', 'data')) {
            Schema::table('data_apis', function (Blueprint $table) {
                $table->dropColumn('data');
            });
        }

        if (Schema::hasColumn('data_api_snapshots', 'data')) {
            Schema::table('data_api_snapshots', function (Blueprint $table) {
                $table->dropColumn('data');
            });
        }
    }
};
