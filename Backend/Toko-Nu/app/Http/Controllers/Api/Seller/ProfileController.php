<?php

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class ProfileController extends Controller
{


    public function me(Request $request)
    {
        $user = $request->user(); // 🔐 dapetin user yang sedang login (dari token)

        return response()->json([
            'message' => 'Data user login berhasil diambil',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'phone' => $user->phone,
                'address' => $user->address,
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

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'address' => 'sometimes|string',
            'latitude' => 'sometimes|numeric',
            'longitude' => 'sometimes|numeric',
            'profile_picture' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'ktp_photo' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
            'store_banner' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        // Simpan file jika dikirim
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
            'user' => $user
        ]);
    }



    // public function update(Request $request)
    // {
    //     $user = Auth::user();

    //     $data = $request->validate([
    //         'name' => 'sometimes|string|max:255',
    //         'phone' => 'sometimes|string|max:20',
    //         'address' => 'sometimes|string',
    //         'latitude' => 'nullable|numeric',
    //         'longitude' => 'nullable|numeric',
    //         'profile_picture' => 'nullable|file|image|max:2048',
    //         'ktp_photo' => 'nullable|file|image|max:2048',
    //         'store_banner' => 'nullable|file|image|max:2048',
    //     ]);

    //     // Upload file jika ada
    //     if ($request->hasFile('profile_picture')) {
    //         $data['profile_picture'] = $request->file('profile_picture')->store('profile_pictures', 'public');
    //     }

    //     if ($request->hasFile('ktp_photo')) {
    //         $data['ktp_photo'] = $request->file('ktp_photo')->store('ktp_photos', 'public');
    //     }

    //     if ($request->hasFile('store_banner')) {
    //         $data['store_banner'] = $request->file('store_banner')->store('store_banners', 'public');
    //     }

    //     $user->update($data);

    //     return response()->json([
    //         'message' => 'Profil berhasil diperbarui',
    //         'user' => [
    //             'id' => $user->id,
    //             'name' => $user->name,
    //             'email' => $user->email,
    //             'phone' => $user->phone,
    //             'role' => $user->role,
    //             'address' => $user->address,
    //             'latitude' => $user->latitude,
    //             'longitude' => $user->longitude,
    //             'profile_picture' => $user->profile_picture ? asset('storage/' . $user->profile_picture) : null,
    //             'ktp_photo' => $user->ktp_photo ? asset('storage/' . $user->ktp_photo) : null,
    //             'store_banner' => $user->store_banner ? asset('storage/' . $user->store_banner) : null,
    //             'created_at' => $user->created_at->toDateTimeString(),
    //             'updated_at' => $user->updated_at->toDateTimeString(),
    //         ],
    //     ]);
    // }
}
