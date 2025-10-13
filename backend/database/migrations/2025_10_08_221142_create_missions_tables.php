<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('missions', function (Blueprint $table) {
            $table->id();
            $table->enum('period', ['daily','weekly']);
            $table->string('name');
            $table->string('description')->nullable();
            $table->enum('type', ['ADD_TRANSACTIONS','NO_SPEND_CATEGORY']);
            $table->json('payload')->nullable();          // {count:2}, {category_id: X}
            $table->unsignedInteger('reward_points')->default(20);
            $table->boolean('active')->default(true);
            $table->timestamps();
        });

        Schema::create('user_missions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->enum('status', ['in_progress','completed','failed'])->default('in_progress');
            $table->unsignedInteger('progress')->default(0);
            $table->unsignedInteger('target')->default(1);
            $table->dateTime('start_at');
            $table->dateTime('end_at');
            $table->timestamps();
            $table->unique(['mission_id','user_id','start_at']);
        });
    }
    public function down(): void {
        Schema::dropIfExists('user_missions');
        Schema::dropIfExists('missions');
    }
};
