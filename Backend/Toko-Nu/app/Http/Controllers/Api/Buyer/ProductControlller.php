<?php

namespace App\Http\Controllers\Api\Buyer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Product;

class ProductController extends Controller
{
    public function index()
    {
        $products = Product::with(['category', 'user:id,name'])->latest()->get();

        return response()->json($products);
    }

    public function show($id)
    {
        $product = Product::with(['category', 'user:id,name,email'])->find($id);

        if (!$product) {
            return response()->json(['message' => 'Produk tidak ditemukan'], 404);
        }

        return response()->json([
            'id' => $product->id,
            'name' => $product->name,
            'price' => $product->price,
            'description' => $product->description,
            'stock' => $product->stock,
            'category_name' => $product->category->name ?? null,
            'seller_name' => $product->user->name ?? null,
            'image' => $product->image,
        ]);
    }

}
