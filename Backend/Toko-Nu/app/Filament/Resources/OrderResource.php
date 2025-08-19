<?php

namespace App\Filament\Resources;

use App\Filament\Exports\OrderExporter;
use App\Filament\Resources\OrderResource\Pages;
use App\Models\Order;
use App\Models\OrderItem;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Section as FormsSection; // Alias untuk Forms\Components\Section
use Filament\Infolists\Infolist;
use Filament\Infolists\Components\TextEntry;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\Section as InfolistSection; // Alias untuk Infolists\Components\Section

class OrderResource extends Resource
{
    protected static ?string $model = Order::class;
    protected static ?string $navigationIcon = 'heroicon-o-shopping-bag';
    protected static ?string $navigationGroup = 'Transaction';

    // Method infolist untuk halaman ViewOrder
    public static function infolist(Infolist $infolist): Infolist
    {
        return $infolist
            ->schema([
                InfolistSection::make('Order Information') // Menggunakan InfolistSection
                    ->schema([
                        TextEntry::make('buyer.name')->label('Buyer Name'),
                        TextEntry::make('seller.name')->label('Seller Name'),
                        TextEntry::make('driver.name')->label('Driver Name')->placeholder('N/A'),
                        TextEntry::make('total_amount')->label('Total Amount')->money('IDR'),
                        TextEntry::make('status')->badge(),
                        TextEntry::make('payment_status')->badge(),
                        TextEntry::make('payment_method'),
                    ])->columns(2),

                InfolistSection::make('Products') // Menggunakan InfolistSection
                    ->schema([
                        RepeatableEntry::make('orderItems')
                            ->label('Ordered Products')
                            ->schema([
                                ImageEntry::make('product.image')
                                    ->label('Image')
                                    ->getStateUsing(fn (OrderItem $record) => asset('storage/' . $record->product->image)),
                                TextEntry::make('product.name')->label('Product Name'),
                                TextEntry::make('product.price')->label('Price')->money('IDR'),
                            ])
                            ->columns(3),
                    ])
                    ->collapsed(false),
            ]);
    }

    // Method form untuk halaman EditOrder
    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                FormsSection::make('Order Information') // Menggunakan FormsSection
                    ->schema([
                        TextInput::make('buyer.name')->label('Buyer Name')->disabled(),
                        TextInput::make('seller.name')->label('Seller Name')->disabled(),
                        TextInput::make('driver.name')
                            ->label('Driver Name')
                            ->disabled()
                            ->placeholder('N/A'),
                        TextInput::make('total_amount')
                            ->label('Total Amount')
                            ->disabled()
                            ->formatStateUsing(fn ($state) => 'Rp ' . number_format($state, 0, ',', '.')),
                        TextInput::make('status')->label('Status'),
                        TextInput::make('payment_status')->label('Payment Status'),
                        TextInput::make('payment_method')->label('Payment Method'),
                    ])->columns(2),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('buyer.name')
                    ->label('Buyer Name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('seller.name')
                    ->label('Seller Name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('driver.name')
                    ->label('Driver Name')
                    ->searchable()
                    ->sortable()
                    ->placeholder('N/A'),
                TextColumn::make('orderItems.product.name')
                    ->label('Products')
                    ->listWithLineBreaks()
                    ->bulleted(),
                TextColumn::make('orderItems.product.price')
                    ->label('Prices')
                    ->money('IDR')
                    ->listWithLineBreaks()
                    ->bulleted(),
                TextColumn::make('total_amount')
                    ->money('IDR')
                    ->sortable(),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'confirmed' => 'primary',
                        'delivering' => 'info',
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        default => 'secondary',
                    })
                    ->sortable(),
                TextColumn::make('payment_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'paid' => 'success',
                        'unpaid' => 'warning',
                        default => 'secondary',
                    })
                    ->sortable(),
                TextColumn::make('payment_method')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Order Date')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                // Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    // Tables\Actions\DeleteBulkAction::make(),
                    Tables\Actions\ExportBulkAction::make()
                        ->exporter(OrderExporter::class),
                ]),
            ])
            ->headerActions([
                Tables\Actions\ExportAction::make()
                    ->exporter(OrderExporter::class),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOrders::route('/'),
            'create' => Pages\CreateOrder::route('/create'),
            // 'view' => Pages\ViewOrder::route('/{record}'), // 'view' yang tadinya dikomen, diaktifkan lagi
            'edit' => Pages\EditOrder::route('/{record}/edit'),
        ];
    }
}