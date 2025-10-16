<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('challenges', function (Blueprint $table) {
            if (!Schema::hasColumn('challenges','active')) {
                $table->boolean('active')->default(true)->after('description');
            }
            if (!Schema::hasColumn('challenges','type')) {
                $table->enum('type', [
                    'SAVE_AMOUNT',              // ahorrar un monto específico
                    'REDUCE_SPENDING_PERCENT',  // reducir gastos comparado con antes
                    'ADD_TRANSACTIONS'          // registrar cierta cantidad de movimientos
                ])->default('SAVE_AMOUNT')->after('active');
            }
            if (!Schema::hasColumn('challenges','payload')) {
                $table->json('payload')->nullable()->after('type'); // {amount: 50000} o {category_id: X, percent:20}
            }
            if (!Schema::hasColumn('challenges','reward_points')) {
                $table->unsignedInteger('reward_points')->default(50)->after('duration_days');
            }
            if (!Schema::hasColumn('challenges','reward_badge_id')) {
                $table->foreignId('reward_badge_id')->nullable()->constrained('badges')->nullOnDelete()->after('reward_points');
            }
            // El catálogo no necesita 'state'
            if (Schema::hasColumn('challenges','state')) {
                $table->dropColumn('state');
            }
        });
    }
    public function down(): void {
        Schema::table('challenges', function (Blueprint $table) {
            $table->string('state')->nullable();
            $table->dropConstrainedForeignId('reward_badge_id');
            $table->dropColumn(['active','type','payload','reward_points']);
        });
    }
};
