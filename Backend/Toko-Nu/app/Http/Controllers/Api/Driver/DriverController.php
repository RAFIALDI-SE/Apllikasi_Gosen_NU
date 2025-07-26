<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DriverController extends Controller
{
    public function toggleActive(Request $request)
    {
        $user = $request->user();
        $user->is_active = $request->is_active;
        $user->save();

        return response()->json(['message' => 'Status updated', 'is_active' => $user->is_active]);
    }

    public function status(Request $request)
    {
        return response()->json(['is_active' => $request->user()->is_active]);
    }
}
