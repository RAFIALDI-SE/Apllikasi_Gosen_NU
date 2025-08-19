<?php

namespace App\Filament\Resources\DeliveryFeeResource\Pages;

use App\Filament\Resources\DeliveryFeeResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditDeliveryFee extends EditRecord
{
    protected static string $resource = DeliveryFeeResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
