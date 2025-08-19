<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotifUser extends Model
{
    use HasFactory;

    protected $table = 'notifusers';


    protected $fillable = ['user_id', 'type', 'title', 'body', 'is_read'];

    public function user() {
        return $this->belongsTo(User::class);
    }
}
