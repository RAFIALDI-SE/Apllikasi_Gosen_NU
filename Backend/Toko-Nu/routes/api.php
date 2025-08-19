<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route::get('/user', function (Request $request) {
//     return $request->user();
// })->middleware('auth:sanctum');

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Seller\ProfileController as SellerProfileController;
use App\Http\Controllers\Api\Buyer\ProfileController as BuyerProfileController;
use App\Http\Controllers\Api\Driver\ProfileController as DriverProfileController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\Seller\ProductController as SellerProductController;
use App\Http\Controllers\Api\Seller\SellerOrderController;
use App\Http\Controllers\Api\Buyer\ProductController as BuyerProductController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\Buyer\FavoriteController;
use App\Http\Controllers\Api\Buyer\ReviewController;
use App\Http\Controllers\Api\Buyer\BuyerOrderController;
use App\Http\Controllers\Api\Driver\DriverController;
use App\Http\Controllers\Api\Driver\DriverDeliveryController;
use App\Models\Favorite;

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
    Route::get('/orders', [SellerOrderController::class, 'index']);
    Route::post('/orders/{id}/confirm', [SellerOrderController::class, 'confirmBySeller']);
    Route::post('/orders/{order}/delivering', [SellerOrderController::class, 'markAsDelivering']);
    Route::put('/products/toggle/{id}', [SellerProductController::class, 'toggleVisibility']);

});

Route::middleware(['auth:sanctum', 'role:buyer'])->prefix('buyer')->group(function () {
    Route::get('/products', [BuyerProductController::class, 'index']);
    Route::get('/products/{id}', [BuyerProductController::class, 'show']);
    Route::get('/drivers', [BuyerOrderController::class, 'availableDrivers']);
    Route::get('/products/{id}', [BuyerOrderController::class, 'productDetail']);
    Route::post('/orders', [BuyerOrderController::class, 'store']);
    Route::get('/orders', [BuyerOrderController::class, 'index']);
    Route::post('/orders/{id}/cancel', [BuyerOrderController::class, 'cancelByBuyer']);
    Route::get('ordersdetail/{id}', [BuyerOrderController::class, 'show']);

});


Route::middleware('auth:sanctum')->prefix('seller')->group(function () {
    Route::get('/me', [SellerProfileController::class, 'me']); // yang tadi
    Route::post('/me/update', [SellerProfileController::class, 'update']); // 🔧 Update profil
});


Route::middleware('auth:sanctum')->prefix('driver')->group(function () {
    Route::get('/me', [DriverProfileController::class, 'me']); // yang tadi
    Route::post('/me/update', [DriverProfileController::class, 'update']); // 🔧 Update profil
    Route::get('/deliveries/history', [DriverDeliveryController::class, 'history']);
    Route::get('/deliveries/today', [DriverDeliveryController::class, 'todayDeliveries']);
    Route::post('/orders/{order}/delivered', [DriverDeliveryController::class, 'markAsDelivered']);
    Route::get('/location', [DriverDeliveryController::class, 'RealtimeLocation']);

});

Route::middleware('auth:sanctum')->prefix('buyer')->group(function () {
    Route::get('/me', [BuyerProfileController::class, 'me']);
    Route::post('/me/update', [BuyerProfileController::class, 'update']);
    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/{productId}', [FavoriteController::class, 'store']);
    Route::delete('/favorites/{productId}', [FavoriteController::class, 'destroy']);
    Route::get('/products/{id}/reviews', [ReviewController::class, 'index']);
    Route::get('/products/{id}/my-review', [ReviewController::class, 'myReview']);
    Route::post('/products/{id}/reviews', [ReviewController::class, 'store']);
    Route::delete('/products/{id}/reviews', [ReviewController::class, 'destroy']);

});


// routes/api.php
Route::middleware('auth:sanctum')->prefix('driver')->group(function () {
    Route::post('/toggle-active', [DriverController::class, 'toggleActive']);
    Route::get('/status', [DriverController::class, 'status']);
});



Route::get('/categories', [CategoryController::class, 'index']);

Route::get('/events', [EventController::class, 'index']);
Route::get('/events/{id}', [EventController::class, 'show']);


Route::get('/districts', function () {
    return \App\Models\District::all(['id', 'name']);
});

Route::get('/districts/{id}/villages', function ($id) {
    return \App\Models\Village::where('district_id', $id)->get(['id', 'name']);
});


use App\Http\Controllers\Api\Seller\NotificationController;

Route::middleware('auth:sanctum')->prefix('seller')->group(function () {
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
});




