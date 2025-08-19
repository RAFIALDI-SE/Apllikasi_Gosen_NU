<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;
use App\Models\User;
use App\Models\Order;
use Illuminate\Support\Facades\DB;
use App\Models\DeliveryFee;


class BuyerOrderController extends Controller
{
    //

    public function index(Request $request)
    {
        $orders = Order::with(['orderItems.product.user', 'buyer','seller', 'driver'])
        ->where('buyer_id', $request->user()->id)
        ->orderByDesc('created_at')
        ->get();


        return response()->json([
            'status' => 'success',
            'orders' => $orders
        ]);
    }



    public function productDetail($id)
    {
        $product = Product::with([
            'user:id,name,phone,address,latitude,longitude',
            'category:id,name'
        ])->findOrFail($id);

        return response()->json($product);
    }


    public function availableDrivers(Request $request)
    {
        $query = User::where('role', 'driver');

        if ($request->has('district_id')) {
            $query->where('district_id', $request->district_id);
        }

        if ($request->has('village_id')) {
            $query->where('village_id', $request->village_id);
        }

        $drivers = $query->orderBy('is_active', 'desc')
            ->get(['id', 'name', 'profile_picture', 'address', 'phone', 'is_active'])
            ->map(function ($driver) {
                $driver->profile_picture = $driver->profile_picture
                    ? asset('storage/' . $driver->profile_picture)
                    : null;
                return $driver;
            });

        return response()->json($drivers);
    }



    /**
     * Hitung jarak antara dua titik koordinat (latitude & longitude) dalam km.
     * Menggunakan formula Haversine.
     *
     * @param float $lat1 Latitude titik pertama
     * @param float $lon1 Longitude titik pertama
     * @param float $lat2 Latitude titik kedua
     * @param float $lon2 Longitude titik kedua
     * @return float Jarak dalam kilometer
     */
    private function getDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // Radius bumi dalam km

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        $distance = $earthRadius * $c;

        return $distance;
    }

    /**
     * Simpan order baru.
     *
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer|min:1',
            'driver_id' => 'required|exists:users,id',
            'delivery_address' => 'required|string',
            'delivery_latitude' => 'required|numeric',
            'delivery_longitude' => 'required|numeric',
            'note' => 'nullable|string|max:500',
        ]);

        $buyer = $request->user();
        $product = Product::findOrFail($request->product_id);

        // Pastikan penjual memiliki latitude dan longitude
        if (empty($product->user->latitude) || empty($product->user->longitude)) {
            return response()->json(['message' => 'Lokasi penjual tidak ditemukan'], 400);
        }

        if ($request->quantity > $product->stock) {
            return response()->json(['message' => 'Stok tidak mencukupi'], 400);
        }

        $total = $product->price * $request->quantity;

        // Ambil lokasi seller dari product->user
        $sellerLatitude = $product->user->latitude;
        $sellerLongitude = $product->user->longitude;

        // Hitung jarak
        $distance = $this->getDistance(
            $sellerLatitude,
            $sellerLongitude,
            $request->delivery_latitude,
            $request->delivery_longitude
        );

        // Cari delivery fee yang sesuai dengan jarak
        $deliveryFee = DeliveryFee::where('min_distance', '<=', $distance)
            ->where(function ($query) use ($distance) {
                $query->where('max_distance', '>', $distance)
                      ->orWhereNull('max_distance');
            })
            ->first();

        // Tetapkan biaya kirim. Jika tidak ada tarif yang cocok, tetapkan 0.
        $calculatedDeliveryFee = $deliveryFee->price ?? 0;
        $grandTotal = $total + $calculatedDeliveryFee;

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
                'delivery_fee' => $calculatedDeliveryFee, // Gunakan biaya yang dihitung
                'total_amount' => $grandTotal,
                'status' => 'pending',
                'payment_status' => 'unpaid',
                'payment_method' => 'cod',
                'note' => $request->note,
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


    public function cancelByBuyer(Request $request ,$id)
    {
        $user = $request->user();
        $order = Order::with('orderItems.product')->where('id', $id)->where('buyer_id', $user->id)->first();

        if (!$order) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        // Jika lebih dari 5 menit dan status masih pending, ubah otomatis jadi confirmed
        if ($order->status === 'pending' && now()->diffInMinutes($order->created_at) > 5) {
            $order->status = 'confirmed';
            $order->save();

            return response()->json(['message' => 'Pesanan telah dikonfirmasi otomatis karena melewati batas pembatalan.']);
        }

        // Cek jika status bukan pending
        if ($order->status !== 'pending') {
            return response()->json(['message' => 'Pesanan tidak dapat dibatalkan'], 400);
        }

        // Kembalikan stok
        foreach ($order->orderItems as $item) {
            $product = $item->product;
            $product->stock += $item->quantity;
            $product->save();
        }

        // Update status order
        $order->status = 'cancelled';
        $order->save();

        return response()->json(['message' => 'Pesanan berhasil dibatalkan']);
    }

    public function show(Request $request ,$id)
    {
        $order = Order::with([
            'orderItems.product.user',
            'seller',
            'driver',
            'buyer' // ← tambahkan ini!
        ])
        ->where('buyer_id', $request->user()->id)
        ->where('id', $id)
        ->first();

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order tidak ditemukan atau tidak milik Anda.'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'order' => $order
        ]);
    }



}
