________________________________________
Panduan Repositori
Selamat datang di repositori kami! Proyek ini dikelola menggunakan dua branch utama, yaitu main dan master, untuk memastikan alur kerja yang terstruktur dan efisien.
________________________________________
Perbedaan Branch main dan master

•	main: Branch ini berisi versi aplikasi yang sudah final dan siap pakai. Semua fitur sudah terintegrasi dan berfungsi dengan baik. Jika Anda ingin langsung menggunakan atau meng-clone proyek yang stabil, wajib gunakan branch ini.

      - Kapan digunakan? Ketika Anda butuh kode yang sudah selesai, lengkap, dan stabil untuk langsung digunakan.
      
•	master: Branch ini adalah tempat pengembangan per fitur. Setiap kali ada fitur baru yang dikembangkan dan di-push, perubahannya akan muncul di sini. Karena ini adalah lingkungan pengembangan, beberapa bagian kode mungkin belum sinkron atau masih dalam tahap pengerjaan. Branch ini berfungsi sebagai panduan tentang bagaimana aplikasi ini dibangun, fitur demi fitur.

      - Kapan digunakan? Ketika Anda ingin melihat proses pengembangan, berkontribusi pada proyek, atau memahami struktur kode dari setiap fitur.
________________________________________
Panduan Instalasi Proyek
Proyek ini dibangun menggunakan dua framework: Laravel sebagai backend dan Flutter sebagai frontend. Ikuti langkah-langkah di bawah ini untuk menginstal dan menjalankan proyek.
1. Persiapan Awal
   
  1.	Clone Repositori:
  
  -      git clone https://github.com/RAFIALDI-SE/Apllikasi_Gosen_NU.git
  
  2.	Masuk ke Direktori Proyek:

  -      cd nama-repositori

2. Instalasi Backend (Laravel)
   
  1.	Masuk ke direktori backend:
  
  -      cd backend
  
  2.	Instal Composer dependencies:
  
  -      composer install
  
  3.	Salin file .env.example untuk membuat file konfigurasi .env:
  
  -      cp .env.example .env
  
  4.	Buka file .env dan atur database credentials Anda.
  5.	Generate application key Laravel:
  
  -      php artisan key:generate
  
  6.	Jalankan migration untuk membuat tabel database:
     
  -      php artisan migrate

  8.	Buat file Admin Seeder
  
  -      php artisan make:seeder AdminSeeder

 lalu isi file :

       - <?php
      
      namespace Database\Seeders;
      
      use Illuminate\Database\Seeder;
      use App\Models\User;
      use Illuminate\Support\Facades\Hash;
      
      class AdminSeeder extends Seeder
      {
          /**
           * Run the database seeds.
           */
          public function run(): void
          {
              // Membuat user admin baru dengan data lengkap
              User::create([
                  'name' => 'Admin Gosen',
                  'email' => 'admin@gosen.id',
                  'email_verified_at' => now(),
                  'password' => Hash::make('password_rahasia_kamu'), // Ganti dengan password yang kuat
                  'phone' => '081234567890',
                  'role' => 'admin',
                  'is_active' => true,
                  'is_disabled' => false,
                  'profile_picture' => null,
                  'ktp_photo' => null,
                  'store_banner' => null,
                  'address' => 'Jl. Jalan Raya Gosen No. 123',
                  'district_id' => 1, // Sesuaikan dengan ID district yang valid
                  'village_id' => 1, // Sesuaikan dengan ID village yang valid
                  'latitude' => null,
                  'longitude' => null,
                  'remember_token' => null,
                  'created_at' => now(),
                  'updated_at' => now(),
              ]);
          }
      }

  
  9.	Jalankan server pengembangan Laravel:
     
  -      php artisan serve

3. Instalasi Frontend (Flutter)
   
  1.	Kembali ke direktori utama proyek, lalu masuk ke direktori frontend:
  
  -      cd ../frontend
  
  2.	Instal Flutter dependencies:
  
  -      flutter pub get
  
  3.	Jalankan aplikasi. Pastikan emulator atau perangkat fisik Anda sudah terhubung:
  -      flutter run


