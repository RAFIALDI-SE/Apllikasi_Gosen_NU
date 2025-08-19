<x-filament::page>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        {{-- Jumlah User --}}
        <x-filament::card>
            <div class="text-lg font-bold">👥 Jumlah Pengguna Terdaftar</div>
            <div class="text-3xl text-green-600 mt-2">{{ $userCount }}</div>
        </x-filament::card>

        {{-- Jumlah Kategori --}}
        <x-filament::card>
            <div class="text-lg font-bold">📂 Jumlah Kategori</div>
            <div class="text-3xl text-blue-600 mt-2">{{ $categoryCount }}</div>
        </x-filament::card>
    </div>

    <div class="mt-6">
        {{-- <x-filament::card>
            <div class="text-lg font-bold mb-2">🆕 5 Kategori Terbaru</div>
            <ul class="list-disc list-inside text-gray-700">
                @forelse ($categories as $category)
                    <li>{{ $category->name }}</li>
                @empty
                    <li>Tidak ada kategori.</li>
                @endforelse
            </ul>
        </x-filament::card> --}}
        <x-filament::card>
            <div class="text-lg font-bold">📦 Total Produk Tersedia</div>
            <div class="text-3xl text-blue-600 mt-2">{{ $product }}</div>
        </x-filament::card>
    </div>
</x-filament::page>
