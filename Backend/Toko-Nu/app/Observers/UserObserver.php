<?php

namespace App\Observers;

use App\Models\User;

class UserObserver
{
    /**
     * Handle the User "created" event.
     */
    public function created(User $user): void
    {
        //
    }

    /**
     * Handle the User "updated" event.
     */
    public function updated(User $user)
    {
        if ($user->isDirty('is_disabled')) { // cek apakah kolom is_disabled berubah
            if ($user->is_disabled) {
                // Jika akun dinonaktifkan
                $user->products()->update(['is_hidden' => true]);

                \App\Models\NotifUser::create([
                    'user_id' => $user->id,
                    'type' => 'account_disabled',
                    'title' => 'Akun Anda Dinonaktifkan',
                    'body' => 'Akun Anda telah dinonaktifkan karena pelanggaran ketentuan. Semua produk Anda disembunyikan.',
                    'is_read' => false,
                ]);
            } else {
                // Jika akun diaktifkan kembali
                $user->products()->update(['is_hidden' => false]);

                \App\Models\NotifUser::create([
                    'user_id' => $user->id,
                    'type' => 'account_enabled',
                    'title' => 'Akun Anda Diaktifkan Kembali',
                    'body' => 'Akun Anda telah diaktifkan kembali. Silahkan Unhide produk anda agar tampil di pembeli lagi.',
                    'is_read' => false,
                ]);
            }
        }
    }



    /**
     * Handle the User "deleted" event.
     */
    public function deleted(User $user): void
    {
        //
    }

    /**
     * Handle the User "restored" event.
     */
    public function restored(User $user): void
    {
        //
    }

    /**
     * Handle the User "force deleted" event.
     */
    public function forceDeleted(User $user): void
    {
        //
    }
}
