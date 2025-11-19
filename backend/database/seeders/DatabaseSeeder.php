<?php

namespace Database\Seeders;

// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // \App\Models\User::factory(10)->create();
        $this->call(CurrencySeeder::class); // LLama al seeder de monedas aquí 
        $this->call(MoneyMakerTypeSeeder::class); // Asegura que los tipos de fuentes de dinero estén creados
        $this->call(BadgeSeeder::class); // Asegura que las insignias estén creadas
        //$this->call(MissionSeeder::class);
        $this->call(ChallengeCatalogSeeder::class,);
        $this->call(HouseExtrasSeeder::class);
        // Asegura que los desafíos base estén creados
        //$this->call(ChallengeProgressDemoSeeder::class);
        // \App\Models\User::factory()->create([
        //     'name' => 'Test User',
        //     'email' => 'test@example.com',
        // ]);
    }
}
