<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('users_challenges', function (Blueprint $table) {
            if (!Schema::hasColumn('users_challenges', 'payload')) {
                $table->json('payload')->nullable()->after('state');
            }
            if (!Schema::hasColumn('users_challenges', 'target_amount')) {
                $table->decimal('target_amount', 12, 2)->nullable()->after('payload');
            }
        });
    }

    public function down(): void {
        Schema::table('users_challenges', function (Blueprint $table) {
            if (Schema::hasColumn('users_challenges', 'target_amount')) {
                $table->dropColumn('target_amount');
            }
            if (Schema::hasColumn('users_challenges', 'payload')) {
                $table->dropColumn('payload');
            }
        });
    }
};
