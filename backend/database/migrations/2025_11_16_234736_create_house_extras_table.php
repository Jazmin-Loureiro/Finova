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
        Schema::create('house_extras', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('icon_path'); // ruta del svg
            $table->unsignedInteger('level_required');
            $table->integer('z_index')->default(10); // orden visual sobre la casa
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
        Schema::dropIfExists('house_extras');
    }
};
