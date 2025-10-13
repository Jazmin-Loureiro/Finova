<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::table('users_challenges', function (Blueprint $table) {
            if (!Schema::hasColumn('users_challenges','progress')) {
                $table->decimal('progress',5,2)->default(0);
            }
            if (!Schema::hasColumn('users_challenges','start_date')) {
                $table->dateTime('start_date')->nullable();
            }
            if (!Schema::hasColumn('users_challenges','end_date')) {
                $table->dateTime('end_date')->nullable();
            }
            // evitar duplicados activos (por estado)
            //$table->unique(['user_id','challenge_id','state']);
        });
    }
    public function down(): void {
        Schema::table('users_challenges', function (Blueprint $table) {
            $table->dropUnique(['user_id','challenge_id','state']);
            $table->dropColumn(['progress','start_date','end_date']);
        });
    }
};
