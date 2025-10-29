<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;

Route::prefix('admin')->group(function () {
    Route::get('/users', [AdminController::class, 'index'])->name('admin.users');
    Route::post('/users/{id}/activate', [AdminController::class, 'activate'])->name('admin.users.activate');
    Route::post('/users/{id}/deactivate', [AdminController::class, 'deactivate'])->name('admin.users.deactivate');
});
use App\Http\Controllers\ServicesSoap\ServicesSoapController;

Route::any('/soap', [ServicesSoapController::class, 'handle']);
