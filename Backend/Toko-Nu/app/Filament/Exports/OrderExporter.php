<?php

namespace App\Filament\Exports;

use App\Models\Order;
use Filament\Actions\Exports\ExportColumn;
use Filament\Actions\Exports\Exporter;
use Filament\Actions\Exports\Models\Export;

class OrderExporter extends Exporter
{
    protected static ?string $model = Order::class;

    public static function getColumns(): array
    {
        return [
            ExportColumn::make('buyer.name')
                ->label('Buyer Name')
                ->state(fn (Order $record) => $record->buyer?->name ?? 'N/A'),

            ExportColumn::make('seller.name')
                ->label('Seller Name')
                ->state(fn (Order $record) => $record->seller?->name ?? 'N/A'),

            ExportColumn::make('driver.name')
                ->label('Driver Name')
                ->state(fn (Order $record) => $record->driver?->name ?? 'N/A'),

            ExportColumn::make('total_amount')->label('Total Amount'),
            ExportColumn::make('status')->label('Status'),
            ExportColumn::make('payment_status')->label('Payment Status'),
            ExportColumn::make('payment_method')->label('Payment Method'),

            // Kolom untuk produk yang dipesan dengan validasi
            ExportColumn::make('orderItems.product.name')
                ->label('Products')
                ->state(function (Order $record) {
                    return $record->orderItems->pluck('product.name')->filter()->implode(', ');
                }),

            ExportColumn::make('orderItems.product.price')
                ->label('Prices')
                ->state(function (Order $record) {
                    return $record->orderItems->pluck('product.price')->filter()->map(fn ($price) => number_format($price, 0, ',', '.'))->implode(', ');
                }),
        ];
    }

    public static function getCompletedNotificationBody(Export $export): string
    {
        $body = 'Your order export has completed and ' . number_format($export->successful_rows) . ' ' . str('row')->plural($export->successful_rows) . ' exported.';

        if ($failedRowsCount = $export->getFailedRowsCount()) {
            $body .= ' ' . number_format($failedRowsCount) . ' ' . str('row')->plural($failedRowsCount) . ' failed to export.';
        }

        return $body;
    }
}
