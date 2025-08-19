<?php

namespace App\Filament\Resources;

use App\Filament\Resources\BuyerResource\Pages;
use App\Filament\Resources\BuyerResource\RelationManagers;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class BuyerResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationGroup = 'Users';

    protected static ?string $navigationIcon = 'heroicon-o-shopping-cart';

    protected static ?string $pluralModelLabel = 'Buyer';

    protected static ?string $modelLabel = 'buyer';

    public static function getEloquentQuery(): \Illuminate\Database\Eloquent\Builder
    {
        return parent::getEloquentQuery()->where('role', 'buyer');
    }

    public static function form(Form $form): Form
    {
        return $form
        ->schema([
            TextInput::make('name')->required(),
            TextInput::make('email')->email()->required(),
            TextInput::make('phone'),
            TextInput::make('address'),
            TextInput::make('latitude'),
            TextInput::make('longitude'),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->sortable()->searchable(),
                TextColumn::make('email')->sortable(),
                TextColumn::make('phone'),
                TextColumn::make('role')->badge()->color('primary'),
                TextColumn::make('address')->limit(20),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
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
            'index' => Pages\ListBuyers::route('/'),
            'create' => Pages\CreateBuyer::route('/create'),
            'edit' => Pages\EditBuyer::route('/{record}/edit'),
        ];
    }
}
