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
            $table->foreignId('user_id')->constrained('users');
            $table->string('name');
            $table->foreignId('money_maker_type_id')->constrained('money_maker_types')->onDelete('restrict');
            $table->decimal('balance', 20, 2)->default(0);
            ////Campo que guardaria el balance reservado de las metas unicamente
            $table->decimal('balance_reserved', 20, 2)->default(0);
            //$table->string('typeMoney');
            $table->foreignId('currency_id')->constrained('currencies'); // clave foránea a la tabla currencies   
            $table->string('color')->nullable(); // Nueva columna para el color
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
        Schema::dropIfExists('money_makers');
    }
};
