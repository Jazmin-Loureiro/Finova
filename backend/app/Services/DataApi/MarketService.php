<?php

namespace App\Services\DataApi;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class MarketService
{
    protected string $coinGeckoBase;
    protected ?string $coinGeckoKey;
    protected string $twelveBase;
    protected string $twelveKey;

    public function __construct()
    {
        $this->coinGeckoBase = rtrim(env('COINGECKO_BASE', 'https://api.coingecko.com/api/v3'), '/');
        $this->coinGeckoKey  = env('COINGECKO_API_KEY', null);

        $this->twelveBase = rtrim(env('TWELVE_BASE', 'https://api.twelvedata.com'), '/');
        $this->twelveKey  = env('TWELVE_API_KEY', '');
    }

    /* ============================================================
       🔸 COTIZACIÓN GENERAL
    ============================================================ */
    public function getQuote(string $type, string $symbol): ?array
    {
        try {
            return match (strtolower($type)) {
                'cripto' => $this->fetchCrypto($symbol),
                'accion' => $this->firstFromBatch($symbol, 'accion'),
                'bono'   => $this->firstFromBatch($symbol, 'bono'),
                default  => null,
            };
        } catch (\Throwable $e) {
            Log::error("❌ Error MarketService ({$type}, {$symbol}): " . $e->getMessage());
            return null;
        }
    }

    protected function firstFromBatch(string $symbol, string $type): ?array
    {
        $data = $this->fetchBatchTwelve([$symbol], $type);
        return $data[0] ?? null;
    }

    /* ============================================================
       ₿ CRIPTOMONEDAS (CoinGecko extendido)
    ============================================================ */
    protected function fetchCrypto(string $id): ?array
    {
        $url = "{$this->coinGeckoBase}/coins/{$id}";
        $headers = [];

        if (!empty($this->coinGeckoKey)) {
            $headers['x-cg-demo-api-key'] = $this->coinGeckoKey;
        }

        $response = Http::withHeaders($headers)
            ->timeout(15)
            ->get($url, [
                'localization' => 'false',
                'tickers'      => 'false',
                'market_data'  => 'true',
            ]);

        if ($response->status() === 429) {
            Log::warning("⏳ Rate limit CoinGecko en {$id}");
            return null;
        }

        if ($response->failed()) {
            Log::error("❌ Error CoinGecko {$id}: " . $response->status());
            return null;
        }

        $json = $response->json();
        if (!$json || empty($json['market_data'])) return null;

        $m = $json['market_data'];

        return [
            'type'                   => 'cripto',
            'symbol'                 => strtoupper($json['symbol'] ?? $id),
            'name'                   => $json['name'] ?? ucfirst($id),
            'price_usd'              => $m['current_price']['usd'] ?? null,
            'change_percent'         => $m['price_change_percentage_24h'] ?? null,
            'change_percent_7d'      => $m['price_change_percentage_7d'] ?? null,
            'change_percent_30d'     => $m['price_change_percentage_30d'] ?? null,
            'market_cap_rank'        => $m['market_cap_rank'] ?? null,
            'high_24h'               => $m['high_24h']['usd'] ?? null,
            'low_24h'                => $m['low_24h']['usd'] ?? null,
            'ath'                    => $m['ath']['usd'] ?? null,
            'ath_change_percent'     => $m['ath_change_percentage'] ?? null,
            'roi'                    => $m['roi']['percentage'] ?? null,
            'last_updated'           => $m['last_updated'] ?? null,
            'fuente'                 => 'CoinGecko',
        ];
    }

    /* ============================================================
       📈 ACCIONES y BONOS (TwelveData extendido)
    ============================================================ */
    protected function fetchBatchTwelve(array $symbols, string $type): array
    {
        if (empty($this->twelveKey) || empty($symbols)) {
            Log::warning("⚠️ TWELVE_API_KEY no definido o sin símbolos");
            return [];
        }

        $url = "{$this->twelveBase}/quote";
        $response = Http::timeout(20)->get($url, [
            'symbol' => implode(',', $symbols),
            'apikey' => $this->twelveKey,
        ]);

        if ($response->failed()) {
            Log::error("❌ Error batch TwelveData ({$type}): " . $response->status());
            return [];
        }

        $json = $response->json();
        if (!$json || isset($json['code'])) {
            Log::warning("⚠️ Sin datos batch TwelveData ({$type}): " . ($json['message'] ?? ''));
            return [];
        }

        $results = [];
        foreach ($json as $symbol => $data) {
            if (!is_array($data)) continue;

            $price = $data['close'] ?? ($data['price'] ?? null);

            $results[] = [
                'type'                  => $type,
                'symbol'                => strtoupper($symbol),
                'name'                  => $data['name'] ?? "{$symbol} ({$type})",
                'price_usd'             => (float) $price,
                'change_percent'        => $data['percent_change'] ?? null,
                'percent_change_ytd'    => $data['ytd_change_percent'] ?? null,
                'fifty_two_week_high'   => $data['fifty_two_week_high'] ?? null,
                'fifty_two_week_low'    => $data['fifty_two_week_low'] ?? null,
                'dividend_yield'        => $data['dividend_yield'] ?? null,
                'open'                  => $data['open'] ?? null,
                'high'                  => $data['high'] ?? null,
                'low'                   => $data['low'] ?? null,
                'previous_close'        => $data['previous_close'] ?? null,
                'market_cap'            => $data['market_cap'] ?? null,
                'fuente'                => 'TwelveData',
            ];
        }

        return $results;
    }

    /* ============================================================
       🔸 Batch para scheduler
    ============================================================ */
    public function getBatch(array $items): array
    {
        $results = [];

        $cryptos = array_filter($items, fn($i) => $i['type'] === 'cripto');
        $stocks  = array_column(array_filter($items, fn($i) => $i['type'] === 'accion'), 'symbol');
        $bonds   = array_column(array_filter($items, fn($i) => $i['type'] === 'bono'), 'symbol');

        foreach ($cryptos as $item) {
            $data = $this->fetchCrypto($item['symbol']);
            if ($data) $results[] = $data;
            usleep(300000);
        }

        $results = array_merge($results, $this->fetchBatchTwelve($stocks, 'accion'));
        $results = array_merge($results, $this->fetchBatchTwelve($bonds, 'bono'));

        return $results;
    }
}
