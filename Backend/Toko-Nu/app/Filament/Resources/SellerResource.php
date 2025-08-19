<?php

namespace App\Filament\Resources;

use App\Filament\Resources\SellerResource\Pages;
use App\Filament\Resources\SellerResource\RelationManagers;
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
use SebastianBergmann\CodeCoverage\Report\Text;

class SellerResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationGroup = 'Users';

    protected static ?string $navigationIcon = 'heroicon-o-banknotes';

    protected static ?string $pluralModelLabel = 'Sellers';

    protected static ?string $modelLabel = 'Seller';

    public static function getEloquentQuery(): \Illuminate\Database\Eloquent\Builder
    {
        return parent::getEloquentQuery()->where('role', 'seller');
    }

    public static function form(Form $form): Form
{
    return $form
        ->schema([
            Forms\Components\Section::make('Informasi Seller')
                ->schema([
                    Forms\Components\Grid::make(2)
                        ->schema([
                            TextInput::make('name')
                                ->label('Nama Seller')
                                ->required(),

                            TextInput::make('email')
                                ->label('Email')
                                ->email()
                                ->required(),

                            TextInput::make('phone')
                                ->label('Nomor Telepon'),

                            TextInput::make('address')
                                ->label('Alamat')
                                ->columnSpanFull(),

                            TextInput::make('latitude')
                                ->label('Latitude'),

                            TextInput::make('longitude')
                                ->label('Longitude'),
                        ]),
                ])
                ->collapsible(),

            Forms\Components\Section::make('Status Akun')
                ->schema([
                    Forms\Components\Toggle::make('is_disabled')
                        ->label('Akun Dinonaktifkan')
                        ->default(false)
                        ->helperText('Jika diaktifkan, semua produk seller akan disembunyikan.'),
                ])
                ->collapsible(),
        ]);
}


    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->sortable()->searchable(),
                TextColumn::make('email')->sortable(),
                TextColumn::make('phone'),
                TextColumn::make('role')->badge()->color('success'),
                TextColumn::make('address')->limit(20),
                Tables\Columns\IconColumn::make('is_disabled')
                ->boolean()
                ->label('Disabled?')
                ->trueColor('danger')
                ->falseColor('success'),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                // Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    // Tables\Actions\DeleteBulkAction::make(),
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
            'index' => Pages\ListSellers::route('/'),
            'create' => Pages\CreateSeller::route('/create'),
            'edit' => Pages\EditSeller::route('/{record}/edit'),
        ];
    }
}
