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

---
---

# Lampiran — pertanyaan sulit, dan jawaban jujurnya

**Tidak diucapkan.** Ini persiapan untuk sesi tanya jawab, termasuk pertanyaan yang akan diajukan orang yang paling kritis. Kalau jawaban jujurnya adalah sebuah keterbatasan, ditulis sebagai keterbatasan.

---

### "Kamu hampir tidak membangun apa-apa. Mana aplikasinya?"

Dua aplikasi, di perangkat asli. Aplikasi watch yang merekam race HYROX, bertahan saat dimatikan paksa, dan menulis struktur sebagai `HKWorkoutEvent`. Aplikasi iPhone yang membacanya kembali dan menandai asal setiap angka. Keduanya di-sign, di-install, dan dijalankan di Apple Watch Ultra 3 dan iPhone 16 Pro Max — tidak pernah di simulator.

Yang **tidak** saya bangun adalah jalur pengiriman data dari watch ke iPhone, dan itu keputusan yang tercatat, bukan sesuatu yang terlewat.

### "Memutuskan tidak mengerjakan bagian terbesar terdengar seperti menghindari kerja."

Memang begitu, kalau keputusannya datang lebih dulu. Keputusannya datang setelah tiga pengukuran: E2.3 menunjukkan offset menghapus kebutuhan rekonsiliasi sepenuhnya, E3.2 menunjukkan metadata saya ikut menyeberang sendiri, E4.0 menunjukkan payload race penuh — 25 segmen, 601 karakter — menyeberang tanpa terpotong.

Catatan keputusannya ada di `design/L4-transport-decision.md`, lengkap dengan kondisi yang akan membatalkannya. Kalau salah satu kondisi itu terbukti, keputusannya berbalik. Itu yang membedakan keputusan dari alasan.

### "Dua kesimpulanmu salah. Kenapa saya harus percaya yang lain?"

Justru karena Anda bisa melihat keduanya. B1 dan B2 di indeks bukti adalah kesalahan saya, diralat **di tempatnya**, dengan teks yang salah tetap disimpan di atas ralatnya.

Kalau saya hapus, Anda tidak punya cara memeriksa cara berpikir saya. Fakta bahwa catatannya memuat ralatnya sendiri adalah alasan untuk mempercayai sisanya — bukan alasan untuk meragukannya.

### "Bagaimana saya tahu prediksinya benar-benar ditulis sebelum tesnya?"

Riwayat git. Setiap prediksi adalah commit yang mendahului commit hasilnya. Aturannya tertulis di awal workbook: prediksi tidak pernah diubah setelah tesnya berjalan.

Itu bisa diperiksa, dan itu satu-satunya alasan prediksi yang salah punya nilai.

### "Aplikasimu kehilangan 1,2% waktu race. Itu tidak cukup akurat."

Tidak begitu. Angka itu mengukur seberapa sering aplikasinya **diizinkan berjalan**, bukan akurasi apa pun yang direkam. Setiap nilai waktu di jalur produk adalah pengurangan antara dua timestamp — `Date().timeIntervalSince(...)` — dan `ProtocolMachine` sama sekali tidak menghitung tick.

Angka 1,2% itu berasal dari penghitung yang saya buat khusus untuk mengukur penghentian aplikasi. Rekaman race-nya tidak pernah melenceng, dan sejak 4 September tampilan jamnya dirender oleh sistem, jadi tampilannya pun tidak tertinggal.

### "Kenapa tidak pakai WorkoutKit? Apple membuatnya untuk ini."

Sudah saya evaluasi. `CustomWorkout` dengan `displayName` memang menampilkan nama HYROX, tapi mengganti layar langsung buatan saya dengan antarmuka interval milik Apple — state machine, tombol advance, dan alur koreksinya semua hilang.

Satu metadata key memberi hasil penamaan yang sama sambil mempertahankan semuanya. Aplikasi Health bawaan Apple sekarang menampilkan workout saya sebagai HYROX. Pertukarannya: satu baris metadata melawan keseluruhan pengalaman live.

### "Jumlah sampel. Satu atlet, beberapa sesi saja."

Benar, dan itu membatasi sebagian klaim, tapi tidak semuanya.

**Tidak terbatas:** perilaku platformnya. Kehilangan 79% tanpa workout session, recovery yang tidak idempotent, atomicity di tiga titik crash yang disuntikkan, metadata yang menyeberang pada panjang race penuh. Ini properti watchOS dan HealthKit, bisa direproduksi siapa pun.

**Terbatas:** apa pun tentang perilaku atlet. Bahwa orang kelelahan salah menekan tombol dibuktikan oleh satu orang yang salah menekan satu kali. Itu observasi nyata, dan itu bukan penelitian.

### "Satu watch, satu iPhone, satu versi OS."

Benar, dan itu tercatat sebagai risiko di catatan keputusan L4. Belum ada pengujian lintas versi watchOS, di perangkat lama, atau di watch yang tidak terpasang dengan iPhone-nya sendiri. Sesi 90 menit juga belum pernah dijalankan utuh; sesi nyata terpanjang adalah 5 menit 11 detik, dan race penuhnya diisi data uji, bukan dilakukan.

### "Istirahat 2,03 detik itu — kenapa tidak di-debounce saja tombolnya?"

Debounce menyembunyikannya. Kalau dua tekanan berjarak 0,333 detik digabung diam-diam, rekamannya menampilkan satu tanda yang bersih dan tidak ada apa pun yang menunjukkan bahwa di situ ada manusia yang ragu.

Itu akan menciptakan nilai yang terbaca sebagai MARKED padahal sebenarnya dibuat-buat — persis ketidakjujuran yang ingin dicegah oleh klasifikasi saya. Desainnya sekarang memunculkannya di layar review, menyatakan buktinya, dan mencatat bahwa koreksi telah dilakukan. Aplikasi Workout bawaan Apple tidak melakukan debounce dan tidak menandai apa pun, jadi belum ada pendekatan yang jadi standar industri.

### "Bukankah empat kategori itu cuma pelabelan?"

Itu mengubah kodenya. `WorkoutReview` menahan label `FROM MARKED + MEASURED` kecuali segmen terakhir benar-benar berakhir bersamaan dengan workout-nya. `segmentSourceAgreement` melaporkan berapa durasi yang dibandingkan dan menyebut satu yang dilewati. Tampilan kosong di iOS menolak menyatakan bahwa tidak ada workout, karena izin yang ditolak dan penyimpanan yang kosong tidak bisa dibedakan.

Masing-masing adalah kalimat yang sekarang tidak boleh lagi diucapkan aplikasinya.

### "Apa yang sebenarnya kamu pelajari, dibanding apa yang dikerjakan alatnya?"

Yang bisa dibawa ke mana-mana adalah kebiasaan, dan itu bisa diuji pada saya: sekarang saya menulis dulu apa yang saya harapkan sebelum menjalankan apa pun, dan saya memperlakukan hasil yang lolos sebagai klaim tentang tesnya, bukan tentang kenyataannya.

Buktinya bahwa kebiasaan itu melekat: lima dari tujuh belas kegagalan yang saya indeks ditemukan **di dalam alat yang saya buat sendiri untuk menangkap kegagalan seperti itu** — dan saya terus menemukannya, termasuk dua pada hari terakhir, karena saya memang mencarinya.

### "Kenapa jumlahnya tujuh belas, padahal draf sebelumnya menyebut sebelas?"

Karena angka sebelumnya ditambah terus, tidak pernah dihitung satu per satu. Workbook menyebut instance "ketiga", "kesepuluh", dan "kedua belas", dan tidak pernah menyebut yang kesebelas.

Menyusun `EVIDENCE-INDEX.md` menghasilkan angka yang bisa diperiksa untuk pertama kalinya. Klaimnya benar bentuknya dan salah ukurannya, dan salahnya justru karena alasan yang sama dengan isi indeks itu sendiri: angkanya tidak pernah diperiksa.
