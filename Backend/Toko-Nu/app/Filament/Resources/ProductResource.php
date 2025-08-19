<?php

namespace App\Filament\Resources;

use App\Filament\Exports\ProductExporter;
use App\Filament\Resources\ProductResource\Pages;
use App\Filament\Resources\ProductResource\RelationManagers;
use App\Models\Product;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static ?string $navigationGroup = 'General';

    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                //
            ]);
    }



public static function table(Table $table): Table
{
    return $table
        ->columns([
            ImageColumn::make('image')
        ->label('Gambar')
        ->getStateUsing(function ($record) {
            return asset('storage/' . $record->image);
        })
        ->circular(), // opsional

            TextColumn::make('name')->searchable()->sortable(),
            TextColumn::make('description')->limit(50),
            TextColumn::make('price')->money('IDR', locale: 'id'),
            TextColumn::make('stock')->label('Stok'),

            TextColumn::make('category.name')
                ->label('Kategori')
                ->badge()
                ->color('success'),

            TextColumn::make('user.name')
                ->label('Pemilik Produk')
                ->color('gray'),
        ])
        ->filters([
            // bisa tambahkan filter jika mau
        ])
        ->actions([
            // Tables\Actions\EditAction::make(),
            // Tables\Actions\DeleteAction::make(),
        ])
        ->bulkActions([
            Tables\Actions\BulkActionGroup::make([
                // Tables\Actions\DeleteBulkAction::make(),
                Tables\Actions\ExportBulkAction::make()
                    ->exporter(ProductExporter::class),
            ]),
        ])
        ->headerActions([
            Tables\Actions\ExportAction::make()
                ->exporter(ProductExporter::class),
        ]);
}

    public static function getEloquentQuery(): Builder
        {
            return parent::getEloquentQuery()->with(['category', 'user']);
        }


    public static function getPages(): array
    {
        return [
            'index' => Pages\ListProducts::route('/'),
            'create' => Pages\CreateProduct::route('/create'),
            'edit' => Pages\EditProduct::route('/{record}/edit'),
        ];
    }
}
