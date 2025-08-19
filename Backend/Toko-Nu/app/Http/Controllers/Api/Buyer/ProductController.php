<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['category', 'user:id,name'])
                    ->where('is_hidden', false)
                    ->whereHas('user', function ($q) {
                        $q->where('is_disabled', false);
                    });


        if ($request->has('search')) {
            $search = $request->search;
            $query->where('name', 'like', "%$search%");
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('seller_id')) {
            $query->where('user_id', $request->seller_id);
        }

        $products = $query->latest()->get();

        return response()->json($products);
    }



    public function show($id)
    {
        $product = Product::with(['category:id,name', 'user:id,name'])->find($id);

        if (!$product) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }

        return response()->json([
            'id' => $product->id,
            'user_id' => $product->user_id,
            'category_id' => $product->category_id,
            'name' => $product->name,
            'description' => $product->description,
            'price' => $product->price,
            'stock' => $product->stock,
            'image' => $product->image,
            'category' => [
                'id' => $product->category->id ?? null,
                'name' => $product->category->name ?? null,
            ],
            'user' => [
                'id' => $product->user->id ?? null,
                'name' => $product->user->name ?? null,
            ],
        ]);
    }




    // public function search(Request $request)
    // {
    //     $query = Product::with(['category', 'user:id,name']);

    //     if ($request->has('name')) {
    //         $query->where('name', 'like', '%' . $request->name . '%');
    //     }

    //     if ($request->has('category')) {
    //         $query->whereHas('category', function ($q) use ($request) {
    //             $q->where('name', 'like', '%' . $request->category . '%');
    //         });
    //     }

    //     if ($request->has('seller')) {
    //         $query->whereHas('user', function ($q) use ($request) {
    //             $q->where('name', 'like', '%' . $request->seller . '%');
    //         });
    //     }

    //     $products = $query->latest()->get();

    //     return response()->json($products);
    // }


}
