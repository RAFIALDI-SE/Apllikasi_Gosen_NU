<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        $favorites = $user->favoriteProducts()->with('user', 'category')->get();

        return response()->json([
            'favorites' => $favorites
        ]);
    }

    public function store($productId, Request $request)
    {
        $user = $request->user();

        $product = Product::findOrFail($productId);

        $user->favoriteProducts()->syncWithoutDetaching([$product->id]);

        return response()->json(['message' => 'Product added to favorites.']);
    }

    public function destroy($productId, Request $request)
    {
        $user = $request->user();

        $user->favoriteProducts()->detach($productId);

        return response()->json(['message' => 'Product removed from favorites.']);
    }
}
