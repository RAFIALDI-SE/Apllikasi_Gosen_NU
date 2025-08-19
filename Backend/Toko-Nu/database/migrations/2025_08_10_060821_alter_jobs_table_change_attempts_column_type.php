<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            // Hapus kolom attempts yang lama dan buat yang baru dengan tipe data berbeda
            $table->smallInteger('attempts')->unsigned()->change();
        });
    }

    public function down(): void
    {
        Schema::table('jobs', function (Blueprint $table) {
            // Kembalikan ke tipe data TINYINT jika diperlukan
            $table->tinyInteger('attempts')->unsigned()->change();
        });
    }
};
