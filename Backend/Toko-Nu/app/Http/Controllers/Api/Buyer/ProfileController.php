<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'message' => 'Data user login berhasil diambil',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'address' => $user->address,
                'district_id' => $user->district_id,
                'district' => $user->district ? $user->district->name : null,
                'village_id' => $user->village_id,
                'village' => $user->village ? $user->village->name : null,
                'latitude' => $user->latitude,
                'longitude' => $user->longitude,
                'profile_picture' => $user->profile_picture ? asset('storage/' . $user->profile_picture) : null,
                'ktp_photo' => $user->ktp_photo ? asset('storage/' . $user->ktp_photo) : null,
                'store_banner' => $user->store_banner ? asset('storage/' . $user->store_banner) : null,
                'created_at' => $user->created_at->toDateTimeString(),
            ]
        ]);
    }

    public function update(Request $request)
    {
        $user = $request->user();

        if ($user->role !== 'buyer') {
            return response()->json(['message' => 'Akses ditolak'], 403);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'address' => 'sometimes|string',
            'district_id' => 'nullable|exists:districts,id',
            'village_id' => 'nullable|exists:villages,id',
            'latitude' => 'sometimes|numeric',
            'longitude' => 'sometimes|numeric',
            'profile_picture' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'ktp_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'store_banner' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($request->hasFile('profile_picture')) {
            $validated['profile_picture'] = $request->file('profile_picture')->store('profile_pictures', 'public');
        }

        if ($request->hasFile('ktp_photo')) {
            $validated['ktp_photo'] = $request->file('ktp_photo')->store('ktp_photos', 'public');
        }

        if ($request->hasFile('store_banner')) {
            $validated['store_banner'] = $request->file('store_banner')->store('store_banners', 'public');
        }

        $user->update($validated);

        return response()->json([
            'message' => 'Profil berhasil diperbarui',
            'user' => $user->fresh(), // Pastikan data terbaru dikirim
        ]);
    }
}
