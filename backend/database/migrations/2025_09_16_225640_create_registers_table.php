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
        Schema::create('registers', function (Blueprint $table) {
            $table->id();   
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('category_id')->constrained('categories')->onDelete('cascade');
            $table->foreignId('moneyMaker_id')->constrained('money_makers')->onDelete('cascade');
            $table->string('name'); 
            $table->decimal('balance', 12, 2);
            //$table->string('typeMoney');
            $table->foreignId('currency_id') // clave foránea a la tabla currencies
            ->constrained('currencies');
            $table->string('type');
            $table->string('file')->nullable();
            $table->boolean('repetition')->default(false);
            $table->string('frequency_repetition')->nullable();
            $table->foreignId('goal_id')->nullable()->constrained('goals')->nullOnDelete();
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
        Schema::dropIfExists('registers');
    }
};
