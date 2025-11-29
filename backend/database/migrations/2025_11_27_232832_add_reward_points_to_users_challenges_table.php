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
    public function up()
    {
        Schema::table('users_challenges', function (Blueprint $table) {
            $table->integer('reward_points')
                ->default(0)
                ->after('target_amount');
        });
    }

    public function down()
    {
        Schema::table('users_challenges', function (Blueprint $table) {
            $table->dropColumn('reward_points');
        });
    }

};
