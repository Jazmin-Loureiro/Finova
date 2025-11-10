<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('users_challenges', function (Blueprint $table) {
            $table->foreignId('goal_id')->nullable()->constrained('goals')->nullOnDelete()->after('payload');
        });
    }

    public function down(): void
    {
        Schema::table('users_challenges', function (Blueprint $table) {
            $table->dropConstrainedForeignId('goal_id');
        });
    }

};
