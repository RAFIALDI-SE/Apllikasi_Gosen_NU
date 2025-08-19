<?php

namespace App\Http\Controllers\API\Driver;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use App\Models\Order;
use App\Models\DriverLocation;

class DriverDeliveryController extends Controller
{
    //

    public function history(Request $request)
    {
        $driver = $request->user(); // pastikan guard driver

        $deliveries = Order::with(['orderItems.product','buyer', 'seller'])
            ->where('driver_id', $driver->id)
            // ->where('status', 'delivered') // atau 'completed', tergantung logika aplikasi
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $deliveries
        ]);
    }
    public function todayDeliveries(Request $request)
    {
        $driver = $request->user();

        $today = Carbon::today();

        $orders = Order::with(['orderItems.product.user', 'buyer', 'seller'])
            ->where('driver_id', $driver->id)
            // ->where('status', 'confirmed')
            ->where('created_at', '<=', now()->subMinutes(5))
            ->whereDate('created_at', $today)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'data' => $orders
        ]);
    }

    public function markAsDelivered(Request $request, Order $order)
    {
        if ($order->status !== 'delivering') {
            return response()->json(['message' => 'Pesanan belum dalam proses pengantaran.'], 400);
        }

        $request->validate([
            'proof_image' => 'required|image|max:2048',
        ]);

        // Simpan gambar bukti pengantaran
        $imagePath = $request->file('proof_image')->store('proofs', 'public');

        // Update status dan bukti pengantaran
        $order->status = 'delivered';
        $order->delivery_proof = $imagePath;

        // Update juga payment_status menjadi paid
        $order->payment_status = 'paid';

        $order->save();

        return response()->json(['message' => 'Pesanan berhasil ditandai sebagai terkirim dan status pembayaran diupdate.']);
    }

    public function RealtimeLocation(Request $request)
    {
        if ($request->user()->role !== 'driver') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $location = DriverLocation::where('driver_id', $request->user()->id)->first();

        if (!$location) {
            return response()->json(['message' => 'Lokasi belum tersedia'], 404);
        }

        return response()->json([
            'latitude' => $location->latitude,
            'longitude' => $location->longitude,
        ]);
    }

}
