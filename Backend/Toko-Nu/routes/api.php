<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route::get('/user', function (Request $request) {
//     return $request->user();
// })->middleware('auth:sanctum');

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Seller\ProfileController as SellerProfileController;
use App\Http\Controllers\Api\Buyer\ProfileController as BuyerProfileController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\Seller\ProductController as SellerProductController;
use App\Http\Controllers\Api\Buyer\ProductController as BuyerProductController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\Buyer\FavoriteController;
use App\Http\Controllers\Api\Buyer\BuyerOrderController;



Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/login/seller', [AuthController::class, 'loginseller']);
Route::post('/login/buyer', [AuthController::class, 'loginbuyer']);
Route::post('/login/driver', [AuthController::class, 'loginDriver']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);
Route::get('/user', [AuthController::class, 'index']);



Route::middleware(['auth:sanctum', 'role:seller'])->prefix('seller')->group(function () {
    Route::get('/products', [SellerProductController::class, 'index']);
    Route::post('/products', [SellerProductController::class, 'store']);
    Route::put('/products/{id}', [SellerProductController::class, 'update']);
    Route::delete('/products/{id}', [SellerProductController::class, 'destroy']);
    Route::get('/products/{id}', [SellerProductController::class, 'show']);
});

Route::middleware(['auth:sanctum', 'role:buyer'])->prefix('buyer')->group(function () {
    Route::get('/products', [BuyerProductController::class, 'index']);
    Route::get('/products/{id}', [BuyerProductController::class, 'show']);
    Route::get('/drivers', [BuyerOrderController::class, 'availableDrivers']);
    Route::get('/products/{id}', [BuyerOrderController::class, 'productDetail']);
    Route::post('/orders', [BuyerOrderController::class, 'store']);
    Route::get('/orders', [BuyerOrderController::class, 'index']);
});


Route::middleware('auth:sanctum')->prefix('seller')->group(function () {
    Route::get('/me', [SellerProfileController::class, 'me']); // yang tadi
    Route::post('/me/update', [SellerProfileController::class, 'update']); // 🔧 Update profil
});

Route::middleware('auth:sanctum')->prefix('buyer')->group(function () {
    Route::get('/me', [BuyerProfileController::class, 'me']);
    Route::post('/me/update', [BuyerProfileController::class, 'update']);
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/{productId}', [FavoriteController::class, 'store']);
    Route::delete('/favorites/{productId}', [FavoriteController::class, 'destroy']);
});

Route::get('/categories', [CategoryController::class, 'index']);

Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);


