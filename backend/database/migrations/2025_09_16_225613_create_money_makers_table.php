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
        Schema::create('money_makers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('name');
            $table->string('type');
            $table->decimal('balance', 12, 2)->default(0);
            //$table->string('typeMoney');
            $table->foreignId('currency_id')->constrained('currencies'); // clave foránea a la tabla currencies   
            $table->string('color')->nullable(); // Nueva columna para el color

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
        Schema::dropIfExists('money_makers');
    }
};
