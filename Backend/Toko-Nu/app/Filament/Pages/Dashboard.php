<?php

namespace App\Filament\Pages;

use Filament\Pages\Page;
use App\Models\User;
use App\Models\Category;
use App\Models\Product;

class Dashboard extends Page
{
    protected static ?string $navigationIcon = 'heroicon-o-home';
    protected static string $view = 'filament.pages.dashboard';

    public function getViewData(): array
    {
        return [
            'userCount' => User::count(),
            'categoryCount' => Category::count(),
            'product' => Product::count(),
            'categories' => Category::latest()->take(5)->get(), // ambil 5 kategori terbaru
        ];
    }
}

