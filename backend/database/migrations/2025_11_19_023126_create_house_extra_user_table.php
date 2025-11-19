<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('house_extra_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('house_extra_id')->constrained('house_extras')->onDelete('cascade');
            $table->boolean('shown')->default(false);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('house_extra_user');
    }
};
