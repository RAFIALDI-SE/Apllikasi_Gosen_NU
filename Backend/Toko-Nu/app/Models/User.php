<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'role',
        'profile_picture',
        'ktp_photo',
        'store_banner',
        'address',
        'district_id',
        'village_id',
        'latitude',
        'longitude',
        'is_active',
        'is_disabled'
    ];


    protected $hidden = [
        'password', 'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'latitude' => 'float',
        'longitude' => 'float',
        'password' => 'hashed',
    ];

    public function products() {
        return $this->hasMany(Product::class);
    }

    public function ordersAsBuyer() {
        return $this->hasMany(Order::class, 'buyer_id');
    }

    public function ordersAsSeller() {
        return $this->hasMany(Order::class, 'seller_id');
    }

    public function ordersAsDriver() {
        return $this->hasMany(Order::class, 'driver_id');
    }

    public function reviews() {
        return $this->hasMany(Review::class, 'buyer_id');
    }

    public function notifuser() {
        return $this->hasMany(NotifUser::class);
    }

    public function driverLocation() {
        return $this->hasOne(DriverLocation::class, 'driver_id');
    }

    public function favoriteProducts()
    {
        return $this->belongsToMany(Product::class, 'favorites', 'buyer_id', 'product_id');
    }

    public function district()
    {
        return $this->belongsTo(District::class);
    }

    public function village()
    {
        return $this->belongsTo(Village::class);
    }

    public function location()
    {
        return $this->hasOne(DriverLocation::class, 'driver_id');
    }




}
