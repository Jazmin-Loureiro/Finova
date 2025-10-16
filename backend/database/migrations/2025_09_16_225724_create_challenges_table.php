<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('challenges', function (Blueprint $table) {
            $table->id();

            // Información básica
            $table->string('name');
            $table->text('description')->nullable();

            // Estado general
            $table->boolean('active')->default(true);

            // Tipo de desafío (más largo para evitar truncados)
            $table->string('type', 50)->nullable(); 
            // Ej: SAVE_AMOUNT, REDUCE_SPENDING, ADD_TRANSACTIONS

            // Datos dinámicos del desafío
            $table->json('payload')->nullable(); 
            // Ej: { "amount": 5000, "category_id": 2, "percent": 20 }

            // Objetivo numérico (por ejemplo monto a alcanzar)
            $table->decimal('target_amount', 12, 2)->nullable();

            // Duración del desafío
            $table->integer('duration_days')->default(30);

            // Recompensas
            $table->unsignedInteger('reward_points')->default(50);
            $table->foreignId('reward_badge_id')->nullable()
                  ->constrained('badges')->nullOnDelete();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('challenges');
    }
};

