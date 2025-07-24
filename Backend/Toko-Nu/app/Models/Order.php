<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'buyer_id', 'seller_id', 'driver_id', 'total_product_price', 'delivery_fee', 'total_amount',
        'status', 'payment_status', 'payment_method', 'delivery_address', 'delivery_latitude',
        'delivery_longitude', 'paid_at', 'paid_by'
    ];

    public function buyer() {
        return $this->belongsTo(User::class, 'buyer_id');
    }

    public function seller() {
        return $this->belongsTo(User::class, 'seller_id');
    }

    public function driver() {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function orderItems() {
        return $this->hasMany(OrderItem::class);
    }

    public function paymentConfirmer() {
        return $this->belongsTo(User::class, 'paid_by');
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }
}
