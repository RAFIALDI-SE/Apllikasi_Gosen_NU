<?php

namespace App\Http\Controllers\Api\Seller;

namespace App\Http\Controllers\Api\Seller;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ProductController extends Controller
{
    public function index()
    {
        $products = Product::with('category') // jika ingin tampil kategori juga
                    ->where('user_id', Auth::id())
                    ->get();

        return response()->json($products);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'name'        => 'required|string|max:255',
            'description' => 'required|string',
            'price'       => 'required|numeric|min:0',
            'stock'       => 'required|integer|min:0',
            'image'       => 'nullable|image|max:2048',
        ]);

        // Simpan file image jika ada
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('product_images', 'public');
            $validated['image'] = $path;
        }

        $validated['user_id'] = Auth::id();

        $product = Product::create($validated);

        return response()->json([
            'message' => 'Produk berhasil ditambahkan',
            'product' => $product,
        ]);
    }

    public function show($id)
{
    $product = Product::with('category')->findOrFail($id);

    // Pastikan ini seller yang punya produk
    if ($product->user_id !== Auth::id()) {
        return response()->json(['message' => 'Tidak diizinkan'], 403);
    }

    return response()->json([
        'id'            => $product->id,
        'name'          => $product->name,
        'description'   => $product->description,
        'price'         => $product->price,
        'stock'         => $product->stock,
        'image'         => $product->image,
        'category_id'   => $product->category_id,
        'category_name' => $product->category?->name,
    ]);
}



    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        if ($product->user_id !== Auth::id()) {
            return response()->json(['message' => 'Tidak diizinkan'], 403);
        }

        $validated = $request->validate([
            'category_id' => 'nullable|exists:categories,id',
            'name'        => 'required|string|max:255',
            'description' => 'required|string',
            'price'       => 'required|numeric|min:0',
            'stock'       => 'required|integer|min:0',
            'image'       => 'nullable|image|max:2048',
        ]);

        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('product_images', 'public');
            $validated['image'] = $path;
        }

        $product->update($validated);

        return response()->json(['message' => 'Produk berhasil diperbarui']);
    }


    public function destroy($id)
    {
        $product = Product::findOrFail($id);

        if ($product->user_id !== Auth::id()) {
            return response()->json(['message' => 'Tidak diizinkan'], 403);
        }

        $product->delete();

        return response()->json(['message' => 'Produk berhasil dihapus']);
    }

}
