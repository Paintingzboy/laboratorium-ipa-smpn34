# Setup Supabase Peminjaman

1. Buat project baru di [Supabase Dashboard](https://supabase.com/dashboard). Simpan password database di password manager; jangan kirimkan ke chat atau masukkan ke website.
2. Di project baru, buka SQL Editor dan jalankan seluruh isi `data/supabase-schema.sql`.
3. Buka Project Settings > API. Isi Project URL dan anon/publishable key ke `data/supabase-config.js`. Jangan masukkan `service_role` key ke website.
4. Buka Authentication > Users, lalu buat akun email/password untuk asisten lab.
5. Kembali ke SQL Editor dan jalankan perintah berikut setelah mengganti email contoh dengan email akun asisten:

	```sql
	update auth.users
	set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"lab_role":"assistant"}'::jsonb
	where email = 'asisten@sekolah.sch.id';
	```

	Role harus berada di `app_metadata`, bukan `user_metadata`, agar tidak dapat diubah sendiri oleh pemilik akun.
6. Host website melalui HTTP/HTTPS, buka halaman peminjaman, lalu login menggunakan akun asisten tersebut.

Pengunjung dapat mengirim pengajuan dan melihat item, jumlah, waktu, serta status yang sama. Nama, kelas, dan keterangan hanya terlihat setelah asisten lab login. Daftar diperbarui otomatis setiap 15 detik.

Pengajuan lama yang hanya tersimpan di `localStorage` browser tidak otomatis dipindahkan ke Supabase.
