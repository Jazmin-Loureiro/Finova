<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('badges', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();   // p.ej. first_challenge
            $table->unsignedTinyInteger('tier')->default(0); // 0 ún., 1 bronce, 2 plata, 3 oro
            $table->string('icon')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('badge_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('badge_id')->constrained('badges')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['badge_id','user_id']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('badge_user');
        Schema::dropIfExists('badges');
    }
};
