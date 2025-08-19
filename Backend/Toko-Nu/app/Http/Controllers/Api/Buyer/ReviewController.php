<?php

namespace App\Http\Controllers\API\Buyer;


use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReviewController extends Controller
{
    public function index($productId)
    {
        $reviews = Review::with('buyer')
            ->where('product_id', $productId)
            ->latest()
            ->get();

        return response()->json($reviews);
    }

    public function store(Request $request, $productId)
    {
        $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string',
        ]);

        $review = Review::updateOrCreate(
            [
                'buyer_id' => Auth::id(),
                'product_id' => $productId,
            ],
            [
                'rating' => $request->rating,
                'comment' => $request->comment,
            ]
        );

        return response()->json(['message' => 'Review berhasil disimpan', 'review' => $review]);
    }

    public function destroy($productId)
    {
        $review = Review::where('buyer_id', Auth::id())
                        ->where('product_id', $productId)
                        ->first();

        if (!$review) {
            return response()->json(['message' => 'Review tidak ditemukan'], 404);
        }

        $review->delete();

        return response()->json(['message' => 'Review berhasil dihapus']);
    }

    public function myReview($productId)
    {
        $review = Review::where('buyer_id', Auth::id())
                        ->where('product_id', $productId)
                        ->first();

        return response()->json($review);
    }
}

