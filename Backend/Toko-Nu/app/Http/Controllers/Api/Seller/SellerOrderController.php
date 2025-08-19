<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;

class SellerOrderController extends Controller
{
    //
    public function index(Request $request)
    {
        $orders = Order::with(['orderItems.product', 'buyer', 'driver'])
            ->where('seller_id', $request->user()->id)
            ->where('created_at', '<=', now()->subMinutes(5)) // Tambahkan ini
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'status' => 'success',
            'orders' => $orders
        ]);
    }

    public function confirmBySeller(Request $request,$id)
    {
        $user = $request->user();
        $order = Order::where('id', $id)->where('seller_id', $user->id)->first();

        if (!$order) {
            return response()->json(['message' => 'Pesanan tidak ditemukan'], 404);
        }

        if ($order->status !== 'pending') {
            return response()->json(['message' => 'Status hanya bisa diubah dari pending ke confirmed'], 400);
        }

        if (now()->diffInMinutes($order->created_at) <= 5) {
            $order->status = 'confirmed';
            $order->save();

            return response()->json(['message' => 'Status berhasil diubah ke confirmed']);
        } else {
            return response()->json(['message' => 'Pesanan sudah lebih dari 5 menit dan tidak bisa diubah'], 400);
        }
    }


    public function markAsDelivering(Order $order)
    {
        if ($order->status !== 'confirmed') {
            return response()->json(['message' => 'Pesanan belum dikonfirmasi.'], 400);
        }

        $order->status = 'delivering';
        $order->save();

        return response()->json(['message' => 'Pesanan sedang dalam pengantaran.']);
    }



}
