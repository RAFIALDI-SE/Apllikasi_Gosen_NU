<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\User;
use App\Models\Order;
use Illuminate\Support\Facades\DB;
class BuyerOrderController extends Controller
{
    //
    public function productDetail($id)
    {
        $product = Product::with([
            'user:id,name,phone,address,latitude,longitude',
            'category:id,name'
        ])->findOrFail($id);

        return response()->json($product);
    }

    public function availableDrivers()
    {
        $drivers = User::where('role', 'driver')
            ->orderBy('is_active', 'desc')
            ->get(['id', 'name', 'profile_picture','address', 'phone', 'is_active'])
            ->map(function ($driver) {
                // Ubah path ke full URL jika ada gambarnya
                $driver->profile_picture = $driver->profile_picture
                    ? asset('storage/' . $driver->profile_picture)
                    : null;
                return $driver;
            });

        return response()->json($drivers);
    }


    public function store(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1',
            'driver_id' => 'required|exists:users,id',
            'delivery_address' => 'required|string',
            'delivery_latitude' => 'required|numeric',
            'delivery_longitude' => 'required|numeric',
        ]);

        $buyer = $request->user();
        $product = Product::findOrFail($request->product_id);

        if ($request->quantity > $product->stock) {
            return response()->json(['message' => 'Stok tidak mencukupi'], 400);
        }

        $total = $product->price * $request->quantity;
        $deliveryFee = 10000; // Sementara flat fee, nanti bisa dinamis
        $grandTotal = $total + $deliveryFee;

        DB::beginTransaction();
        try {
            // Kurangi stok
            $product->stock -= $request->quantity;
            $product->save();

            // Simpan order
            $order = Order::create([
                'buyer_id' => $buyer->id,
                'seller_id' => $product->user_id,
                'driver_id' => $request->driver_id,
                'total_product_price' => $total,
                'delivery_fee' => $deliveryFee,
                'total_amount' => $grandTotal,
                'status' => 'pending',
                'payment_status' => 'unpaid',
                'payment_method' => 'cod',
                'delivery_address' => $request->delivery_address,
                'delivery_latitude' => $request->delivery_latitude,
                'delivery_longitude' => $request->delivery_longitude,
            ]);

            // Simpan item
            $order->items()->create([
                'product_id' => $product->id,
                'quantity' => $request->quantity,
                'price_at_order_time' => $product->price,
            ]);

            DB::commit();
            return response()->json(['message' => 'Order berhasil dibuat', 'order_id' => $order->id], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Gagal membuat order', 'error' => $e->getMessage()], 500);
        }
    }

}
