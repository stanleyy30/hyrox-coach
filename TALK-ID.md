# Challenge 4 — Presentasi 8 menit

Empat bagian, mengikuti speaker's talking points. Estimasi waktunya sekitar tujuh setengah menit, jadi masih ada ruang untuk bernapas.

---

# 1 · Apa yang saya pilih untuk dikembangkan
**±50 detik**

Challenge saya: **belajar membangun connected data tracking antara watchOS dan iOS.**

Growth focus statement saya menyebutkan bahwa saya akan mempelajari bagaimana hal itu bekerja — background execution, kepemilikan data, keandalan pengiriman data, dan sumber kebenaran data — dengan menghasilkan satu workout utuh yang direkam di jam tangan dan ditinjau di iPhone, **beserta catatan tentang apa saja yang prediksinya meleset**, supaya saya mampu membangun jalur data yang tetap bertahan meski layar mati dan aplikasinya dimatikan paksa, dan bisa menjelaskan kenapa itu bertahan.

Bagian terakhir itu saya tulis dengan sengaja. **Catatan tentang apa saja yang prediksinya meleset.** Nanti saya kembali ke sini.

Saya latihan HYROX. Delapan lari, delapan station, dan waktu istirahat di antaranya ikut dihitung. Saya ingin aplikasi yang merekam race itu di jam tangan dan menjelaskannya dengan jujur di iPhone.

---

# 2 · Titik awal saya, dan posisi saya sekarang
**±1 menit 30**

**Titik awal saya nol.** HealthKit, workout session, background execution, memindahkan data antara dua perangkat — semuanya belum pernah saya pakai.

Jadi saya tidak merencanakan untuk langsung membangun. **Saya merencanakan untuk memprediksi lebih dulu.**

Sebelum setiap eksperimen, saya menulis apa yang saya harapkan terjadi. Setelah dijalankan, saya menulis apa yang benar-benar terjadi, lalu selisih di antara keduanya. **Prediksi tidak boleh diubah setelah tesnya berjalan.** Prediksi yang salah itu buktinya, bukan kesalahan yang harus disembunyikan.

**Sepuluh hari kemudian:** enam siklus, dua puluh empat eksperimen, semuanya diuji di Apple Watch dan iPhone asli. Aplikasi watch yang merekam race dan tetap selamat saat aplikasinya dimatikan paksa. Aplikasi iPhone yang meninjaunya. Dan workbook dua ribu baris yang masih memuat semua prediksi saya yang meleset.

Ini hasil nyata dari metode itu. Siklus 4 direncanakan sebagai **bagian terbesar di proyek ini** — membangun jalur pengiriman data dari jam tangan ke iPhone. **Saya tidak membangunnya sama sekali.** Siklus 3 sudah lebih dulu membuktikan bahwa Apple memindahkannya secara gratis: di bawah empat belas detik, iPhone dalam keadaan terkunci, dan berada di ruangan lain. Jadi Siklus 4 berubah dari membangun menjadi memutuskan, dan saya menulis dokumen yang menjelaskan kenapa membangunnya justru pemborosan.

**Tugas terbesar yang saya rencanakan menghasilkan nol baris kode. Dan justru itu hasil yang paling saya yakini**, karena saya baru tahu itu aman dihapus setelah saya mengukurnya.

---

# 3 · Apa dan bagaimana saya belajar
**±3 menit 30 — ini bagian utamanya**

Satu momen saja, karena momen ini mengubah semua yang datang sesudahnya.

## Istirahat 2,03 detik

Di Siklus 5 saya berhenti menguji sambil duduk di meja dan mulai menjalankan **sesi latihan sungguhan**. Lari beneran, burpees beneran. Saya kehabisan napas, sambil menekan tombol di pergelangan tangan setiap pindah station.

Di istirahat kedua, **saya tidak sengaja menekannya dua kali.**

Aplikasi saya mencatat istirahat selama **2,03 detik.** Itu mustahil.

**Dan semua pengecekan yang saya tulis bilang datanya baik-baik saja.** Urutan waktunya benar. Tidak ada nilai negatif. Semuanya berada di dalam rentang workout. Pengecekan integritas saya melaporkan INTACT.

## Apa yang saya pelajari dari situ

Selama ini saya memperlakukan semua angka saya seolah sama kuatnya. Ternyata tidak. Ada empat jenis:

| **MEASURED** | Direkam sendiri oleh jam — detak jantung, kalori, total waktu |
|---|---|
| **MARKED** | Ada manusia yang menekan tombol — semua batas antar station |
| **DERIVED** | Dihitung dari keduanya — durasi tiap station |
| **UNSUPPORTED** | Datanya memang tidak bisa menjawabnya |

Pembagian yang kelihatan jelas adalah antara "direkam" dan "dihitung". **Pembagian itu keliru.** Batas yang sebenarnya justru ada di dalam kata "direkam". Total waktu saya dan waktu mulai station sama-sama timestamp, dan di layar tampilannya identik. Yang satu berasal dari sensor. Yang satu lagi berasal dari **orang kelelahan yang menekan tombol.**

Lalu saya menemukan jenis kelima yang tidak ada di rencana mana pun. Aplikasi saya menampilkan **"SkiErg"** padahal yang saya lakukan burpees — karena aplikasinya **berasumsi**, dan tidak pernah bertanya. Jenis itu saya beri nama **ASSUMED**.

## Pola di baliknya

Begitu saya menyadarinya, saya melihatnya di mana-mana. **Sinyal hijau yang menyembunyikan kegagalan — tujuh belas kali, dan semuanya sudah saya indeks.**

- Aplikasinya terlihat sehat sementara **79%** waktu race hilang, tanpa crash dan tanpa error.
- Izin akses melaporkan berhasil padahal pembacaannya diblokir, karena HealthKit mengembalikan daftar kosong, bukan error.
- Pengecekan integritas saya meloloskan istirahat dua detik yang mustahil itu.
- Alat pembanding saya menampilkan **AGREE** padahal tidak membandingkan apa pun.

Beberapa di antaranya ada **di dalam alat yang saya buat justru untuk menangkap masalah.** Dua di antaranya **kesalahan saya sendiri** — saya pernah menyimpulkan HealthKit sudah menghapus semua workout saya, padahal hari itu juga semuanya muncul lagi, utuh. Ralat itu masih ada di workbook saya.

**Yang saya pelajari, dalam satu kalimat: tes yang lolos hanya membuktikan apa yang benar-benar dia periksa.**

Jadi sekarang pengecekan saya menyebutkan apa saja yang dia periksa. Alih-alih hanya `AGREE`, alat saya menampilkan:

> `AGREE — 6 durasi dibandingkan; yang terakhir dilewati, karena tidak ada data sesudahnya untuk dibandingkan`

## Satu hal yang membuat saya lebih percaya diri

Di akhir proyek, saya mencoba **aplikasi Workout bawaan Apple.** Saya menekan tombol lap-nya dua kali, **berjarak 0,333 detik.** Aplikasinya mencatat keduanya, tanpa keberatan, tanpa penanda apa pun.

**Apple pun belum menyelesaikan masalah ini.** Jadi ini bukan soal saya masih pemula. Menyelesaikannya dengan benar adalah kontribusi yang nyata.

---

# 4 · Bukti pembelajaran
**±1 menit 30**

**Aplikasinya** — aplikasi watch yang merekam race HYROX dan bertahan saat dimatikan paksa, serta aplikasi iPhone yang menandai dari mana setiap angka berasal.

**Workbook-nya** — dua ribu baris. Setiap prediksi sebelum tes, setiap hasil sesudahnya, dan setiap selisihnya. Termasuk dua kesimpulan yang harus saya ralat.

**Catatan keputusan** — tiga dokumen, termasuk yang menyatakan jangan membangun jalur pengiriman data sendiri, lengkap dengan kondisi yang bisa membatalkan keputusan itu.

**Commit-nya** — setiap temuan adalah satu commit dengan alasannya tertulis di pesan commit.

**Di perangkatnya, dan ini bisa saya tunjukkan langsung:** tiga penghitung waktu berdampingan selama workout. Satu menghitung pakai timer dan mulai tertinggal saat jam tangan menghentikan aplikasinya. Dua lainnya menghitung dari timestamp dan tetap benar. **Satu layar itu adalah keseluruhan siklus pertama saya, terjadi langsung di depan Anda.**

**Dan satu baris kode.** Tidak ada tipe workout HYROX di HealthKit. Saya menambahkan satu metadata key, dan **aplikasi Health bawaan Apple sekarang menampilkan workout saya sebagai HYROX** — sementara saya tetap memakai layar saya sendiri.

## Langkah saya berikutnya

Saya merancang layarnya dulu di atas kertas, pakai Sketch, **sebelum** menulis kode antarmuka lagi. Dua masalah terburuk saya adalah masalah desain yang seharusnya ketahuan sejak di kertas.

Saya sudah membuat fitur undo, dan **waktu saya benar-benar melakukan kesalahan di tengah race, saya tidak memakainya** — karena letaknya di layar yang berbeda.

Dan aplikasi saya masih memberi tahu atletnya station apa yang dia lakukan, bukan bertanya.

**Terima kasih.**
