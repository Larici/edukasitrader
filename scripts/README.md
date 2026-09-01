# Publish-Poster.ps1

Script otomatis untuk mengubah poster HTML dari `D:\Danu\Trade\posters\`
menjadi halaman "Riset & Analisis Harian" di situs EdukasiTrader — tanpa
perlu adaptasi manual satu-satu.

## Yang Dilakukan Script Ini

1. Membaca file poster sumber apa adanya (isi analisis tidak diubah).
2. Mengganti nama CSS custom property (`--bg`, `--text`, `--border`, dst.)
   dan class yang bentrok dengan `style.css` situs utama (`.disclaimer`,
   `.footer`, selector `body{...}`) supaya tampilan poster tidak merusak
   atau tertimpa gaya situs utama.
3. Membungkus poster dengan header/nav/footer situs, banner
   "Bukan ajakan bertransaksi", dan kode iklan Adsterra standar
   (Banner 300x250 di atas, Native Banner di bawah).
4. Menyimpan hasilnya ke `market-analysis/<slug>.html`.
5. Menambahkan card baru di posisi **paling atas** section "Riset &
   Analisis Harian" di `index.html` (jadi urutan tampilan selalu terbaru
   di atas), termasuk update angka "(N catatan)", dan entry baru ke
   `sitemap.xml` — kecuali dipanggil dengan `-SkipHomepage`.

## Cara Pakai

Dari folder `adsterra-blog`, jalankan lewat PowerShell:

```powershell
.\scripts\Publish-Poster.ps1 `
  -SourcePath "D:\Danu\Trade\posters\NFP-2026-09-05.html" `
  -Slug "xauusd-nfp-5-september-2026" `
  -Title "XAUUSD Briefing — NFP 5 September 2026" `
  -Excerpt "Gold breakout ke ATH baru jelang NFP 5 September — apakah data tenaga kerja malam ini jadi pemicu lanjutan, atau titik balik? Cek breakdown skenario dan level kunci sebelum rilis."
```

### Menulis `-Excerpt` yang Bagus (Hook, Bukan Cuma Ringkasan)

`-Excerpt` dipakai di dua tempat sekaligus: `<meta name="description">` halaman
(muncul di hasil pencarian Google) dan card di homepage (yang menentukan orang
klik atau lewat). Jangan cuma daftar isi ("membahas X, Y, Z") — tulis sebagai
**hook**:

- Buka dengan fakta/angka paling menarik dari poster (harga bergerak berapa,
  bias engine berapa persen, level kunci berapa).
- Ciptakan rasa ingin tahu — pertanyaan terbuka soal apa yang akan terjadi
  saat rilis biasanya efektif ("apakah lanjut turun, atau rebound?").
- Tetap jujur pada isi poster — hook boleh menarik, tapi jangan clickbait
  yang isinya tidak sesuai.
- Idealnya 1–2 kalimat, muat di card homepage tanpa terlalu panjang.

Contoh nyata dari poster yang sudah live:
> "Gold ambruk ke $4.468 usai pidato hawkish Jackson Hole — apakah ISM
> Manufacturing & JOLTS malam ini jadi lanjutan pelemahan, atau pemicu
> rebound? Market Bias Engine kami baca 63% Bearish. Cek breakdown 15 data
> makro, 3 skenario harga, dan level kunci sebelum rilis."

Setelah selesai, cek hasilnya di browser, lalu commit & push seperti biasa:

```bash
git add -A
git commit -m "Add market analysis: NFP 5 September 2026"
git push
```

### Parameter

| Parameter | Wajib? | Keterangan |
|---|---|---|
| `-SourcePath` | Ya | Path lengkap ke file poster sumber |
| `-Slug` | Ya | Nama file output (jadi bagian URL), contoh: `xauusd-nfp-5-september-2026` |
| `-Title` | Tidak | Kalau dikosongkan, diambil otomatis dari `<title>` file sumber |
| `-Excerpt` | Tidak | Hook + resume singkat untuk meta description & card homepage (lihat panduan di atas). Ada default generik kalau dikosongkan — sebaiknya selalu diisi manual |
| `-CardTag` | Tidak | Label kecil di card homepage. Default: `Analisis Harian` |
| `-SkipHomepage` | Tidak | Kalau dipakai, halaman dibuat tapi TIDAK otomatis masuk homepage/sitemap |

## Syarat Format Poster Sumber

Script mengandalkan struktur yang konsisten dari sistem poster kamu:

- Ada satu blok `<style>...</style>` di `<head>`.
- Ada satu `<div class="poster">...</div>` yang jadi konten utama,
  langsung sebelum `</body>`.

Kalau format poster berubah drastis di kemudian hari, script mungkin perlu
disesuaikan lagi.

## Kalau Homepage Berubah Struktur

Bagian auto-insert ke `index.html` mengandalkan section dengan
`id="riset-harian"` yang sudah ada. Kalau section ini di-refactor/dihapus,
jalankan dengan `-SkipHomepage` dan tambahkan card + entry sitemap secara
manual.
