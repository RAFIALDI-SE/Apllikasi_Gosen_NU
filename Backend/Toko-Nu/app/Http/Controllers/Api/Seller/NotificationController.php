<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\NotifUser;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Ambil semua notifikasi seller yang sedang login
     */
    public function index(Request $request)
    {
        $notifications = NotifUser::where('user_id', $request->user()->id)
                        ->latest()
                        ->get();


        return response()->json($notifications);
    }

    public function markAsRead(Request $request, $id)
    {
        $notif = NotifUser::where('id', $id)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $notif->update(['is_read' => true]);

        return response()->json(['message' => 'Notification marked as read']);
    }


    public function unreadCount(Request $request)
    {
        $count = NotifUser::where('user_id', $request->user()->id)
                        ->where('is_read', false)
                        ->count();

        return response()->json(['count' => $count]);
    }


}
