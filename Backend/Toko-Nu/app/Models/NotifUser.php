<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;


class NotifUser extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'type', 'title', 'body', 'is_read'];

    public function user() {
        return $this->belongsTo(User::class);
    }
}
