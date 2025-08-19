<?php

// app/Filament/Resources/DeliveryFeeResource.php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryFeeResource\Pages;
use App\Models\DeliveryFee;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Filament\Tables\Columns\TextColumn;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Card;

class DeliveryFeeResource extends Resource
{
    protected static ?string $model = DeliveryFee::class;
    protected static ?string $navigationIcon = 'heroicon-o-truck';
    protected static ?string $navigationGroup = 'Settings';
    protected static ?string $modelLabel = 'Delivery Fee';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Card::make()
                    ->schema([
                        TextInput::make('min_distance')
                            ->label('Jarak Minimal (km)')
                            ->numeric()
                            ->required(),
                        TextInput::make('max_distance')
                            ->label('Jarak Maksimal (km)')
                            ->helperText('Kosongkan untuk "ke atas" (misal: 10km ke atas)')
                            ->numeric(),
                        TextInput::make('price')
                            ->label('Harga (Rp)')
                            ->prefix('Rp')
                            ->numeric()
                            ->required(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('min_distance')->label('Jarak Minimal (km)'),
                TextColumn::make('max_distance')
                    ->label('Jarak Maksimal (km)')
                    ->formatStateUsing(fn ($state) => $state ? $state : 'Ke Atas'),
                TextColumn::make('price')->label('Harga')->money('IDR'),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveryFees::route('/'),
            'create' => Pages\CreateDeliveryFee::route('/create'),
            'edit' => Pages\EditDeliveryFee::route('/{record}/edit'),
        ];
    }
}