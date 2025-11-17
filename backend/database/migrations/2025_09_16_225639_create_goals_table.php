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
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('currency_id')->constrained('currencies')->onDelete('cascade'); // clave foránea a la tabla currencies
            $table->string('name');
            $table->decimal('target_amount', 20, 2);
            $table->date('date_limit');
            $table->decimal('balance', 20, 2)->default(0);
            $table->string('state')->default('in_progress'); // in_progress, completed,
            $table->boolean('active')->default(true); 
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('goals');
    }
};
