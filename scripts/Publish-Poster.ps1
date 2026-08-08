<#
.SYNOPSIS
  Adaptasi poster HTML (dari folder D:\Danu\Trade\posters\) jadi halaman
  "Riset & Analisis Harian" di situs EdukasiTrader, otomatis.

.DESCRIPTION
  Script ini:
    1. Membaca file poster sumber (hasil sistem trading kamu).
    2. Menyalin isi <style> dan <div class="poster">...</div> apa adanya
       (tidak mengubah kata-kata/analisis di dalamnya).
    3. Mengganti nama CSS custom property (--bg, --text, --border, dst) dan
       class yang berpotensi bentrok (.disclaimer, .footer, selector body{})
       supaya tidak menimpa gaya situs utama.
    4. Membungkusnya dengan header/nav/footer situs + compliance banner
       "bukan ajakan bertransaksi" + kode iklan Adsterra standar.
    5. Menyimpan hasilnya ke market-analysis/<slug>.html.
    6. (Opsional, default aktif) Menambahkan card baru di homepage
       (section "Riset & Analisis Harian") dan entry baru di sitemap.xml.

.PARAMETER SourcePath
  Path lengkap ke file poster sumber, contoh:
  D:\Danu\Trade\posters\CPI-2026-08-12.html

.PARAMETER Slug
  Nama file output (tanpa .html), dipakai untuk URL. Contoh:
  xauusd-cpi-12-agustus-2026

.PARAMETER Title
  Judul halaman & <title> tag. Kalau dikosongkan, diambil otomatis dari
  <title> file sumber.

.PARAMETER Excerpt
  Ringkasan 1-2 kalimat untuk meta description & card di homepage.

.PARAMETER CardTag
  Label kecil di card homepage. Default: "Analisis Harian".

.PARAMETER SkipHomepage
  Kalau dipakai, script TIDAK menambahkan card ke index.html / sitemap.xml
  (cuma generate halaman market-analysis-nya saja).

.EXAMPLE
  .\scripts\Publish-Poster.ps1 `
    -SourcePath "D:\Danu\Trade\posters\NFP-2026-09-05.html" `
    -Slug "xauusd-nfp-5-september-2026" `
    -Title "XAUUSD Briefing — NFP 5 September 2026" `
    -Excerpt "Catatan riset menjelang rilis Non-Farm Payrolls — konteks makro dan level teknikal emas."
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$SourcePath,

  [Parameter(Mandatory = $true)]
  [string]$Slug,

  [string]$Title = "",
  [string]$Excerpt = "",
  [string]$CardTag = "Analisis Harian",
  [switch]$SkipHomepage
)

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$SiteRoot   = Split-Path -Parent $PSScriptRoot
$OutputDir  = Join-Path $SiteRoot "market-analysis"
$OutputPath = Join-Path $OutputDir "$Slug.html"
$IndexPath  = Join-Path $SiteRoot "index.html"
$SitemapPath = Join-Path $SiteRoot "sitemap.xml"
$SiteBaseUrl = "https://larici.github.io/edukasitrader"

if (-not (Test-Path $SourcePath)) {
  throw "File sumber tidak ditemukan: $SourcePath"
}
if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# ---------------------------------------------------------------------------
# 1. Baca file sumber
# ---------------------------------------------------------------------------
$raw = [System.IO.File]::ReadAllText($SourcePath, [System.Text.Encoding]::UTF8)

if ($Title -eq "") {
  if ($raw -match '<title>(.*?)</title>') {
    $Title = $Matches[1].Trim()
  } else {
    $Title = $Slug
  }
}
if ($Excerpt -eq "") {
  $Excerpt = "Catatan riset pasar — konteks makro dan level teknikal. Opini pribadi, bukan ajakan bertransaksi."
}

# ---------------------------------------------------------------------------
# 2. Ekstrak blok <style> dan blok <div class="poster">...</div>
# ---------------------------------------------------------------------------
$styleStartTag = '<style>'
$styleEndTag   = '</style>'
$sIdx = $raw.IndexOf($styleStartTag)
$eIdx = $raw.IndexOf($styleEndTag)
if ($sIdx -lt 0 -or $eIdx -lt 0) {
  throw "Tidak menemukan blok <style>...</style> di file sumber. Pastikan formatnya sesuai template poster standar."
}
$styleBlock = $raw.Substring($sIdx + $styleStartTag.Length, $eIdx - ($sIdx + $styleStartTag.Length))

$posterStartTag = '<div class="poster">'
$pIdx = $raw.IndexOf($posterStartTag)
$bodyEndIdx = $raw.LastIndexOf('</body>')
if ($pIdx -lt 0 -or $bodyEndIdx -lt 0) {
  throw 'Tidak menemukan <div class="poster">...</div> sebelum </body>. Pastikan formatnya sesuai template poster standar.'
}
$posterBlock = $raw.Substring($pIdx, $bodyEndIdx - $pIdx).TrimEnd()

# ---------------------------------------------------------------------------
# 3. Cegah bentrok dengan style.css situs utama
# ---------------------------------------------------------------------------

# 3a. Prefix semua CSS custom property (--nama) dengan "p-" supaya tidak
#     menimpa variabel --bg/--text/--border milik situs utama.
$varNames = [regex]::Matches($styleBlock, '--([\w-]+)\s*:') |
  ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

foreach ($name in $varNames) {
  $pattern = "--$([regex]::Escape($name))(?![\w-])"
  $replacement = "--p-$name"
  $styleBlock  = [regex]::Replace($styleBlock,  $pattern, $replacement)
  $posterBlock = [regex]::Replace($posterBlock, $pattern, $replacement)
}

# 3b. Rename class yang sudah dipakai situs utama (.disclaimer, .footer)
$classRenames = @{ 'disclaimer' = 'poster-disclaimer'; 'footer' = 'poster-footer' }
foreach ($old in $classRenames.Keys) {
  $new = $classRenames[$old]
  $styleBlock  = $styleBlock  -replace "\.$old(?=[\s\{\.,:])", ".$new"
  $posterBlock = $posterBlock -replace "class=`"$old`"", "class=`"$new`""
}

# 3c. Ganti selector top-level "body{" jadi ".poster-container{" supaya
#     tidak menimpa background/layout <body> situs utama.
$styleBlock = [regex]::Replace($styleBlock, '\bbody\{', '.poster-container{')

# ---------------------------------------------------------------------------
# 4. Susun halaman akhir dari template
# ---------------------------------------------------------------------------
$adSlotTop = @'
    <div class="ad-slot">
      <script>
        atOptions = {
          'key' : '95130429aa13b28790da6b9e46158bfc',
          'format' : 'iframe',
          'height' : 250,
          'width' : 300,
          'params' : {}
        };
      </script>
      <script src="https://www.highperformanceformat.com/95130429aa13b28790da6b9e46158bfc/invoke.js"></script>
    </div>
'@

$adSlotBottom = @'
    <div class="ad-slot">
      <script async="async" data-cfasync="false" src="https://pl30756138.effectivecpmnetwork.com/4a3f1dc3807941e53dfe4463a21a0e4e/invoke.js"></script>
      <div id="container-4a3f1dc3807941e53dfe4463a21a0e4e"></div>
    </div>
'@

$complianceNotice = @'
    <div class="compliance-notice">
      <strong>Bukan ajakan bertransaksi.</strong> Konten di bawah ini adalah catatan analisis pasar pribadi yang kami bagikan sebagai referensi publik — berisi opini terhadap data makro dan level teknikal saat disusun, bukan sinyal trading resmi, rekomendasi personal, atau ajakan untuk membuka posisi tertentu. Pasar bisa bergerak sangat berbeda dari skenario yang dibahas. Selalu lakukan riset dan pertimbangan risiko sendiri.
    </div>
'@

$extraCss = @'

  .compliance-notice{
    max-width:880px;
    margin:0 auto 20px;
    padding:16px 20px;
    background:var(--bg-alt);
    border:1px solid var(--accent-dim);
    border-left:4px solid var(--accent);
    border-radius:8px;
    color:var(--text-dim);
    font-size:0.88rem;
    line-height:1.6;
  }
  .compliance-notice strong{color:var(--text);}
'@

$template = @"
<!DOCTYPE html>
<html lang="id">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>$Title — EdukasiTrader</title>
<meta name="description" content="$Excerpt">
<link rel="stylesheet" href="../assets/css/style.css">
<style>$styleBlock$extraCss
</style>
</head>
<body>

<header class="site-header">
  <div class="wrap">
    <a href="../index.html" class="logo">Edukasi<span>Trader</span></a>
    <nav class="main-nav">
      <a href="../index.html">Beranda</a>
      <a href="../about.html">Tentang</a>
      <a href="../contact.html">Kontak</a>
      <a href="../privacy.html">Privasi</a>
    </nav>
  </div>
</header>

<main>
  <div class="wrap" style="max-width: 960px;">

$complianceNotice

$adSlotTop

    <div class="poster-container">

$posterBlock

    </div>

$adSlotBottom

  </div>
</main>

<footer class="site-footer">
  <div class="wrap">
    <div>
      <a href="../about.html">Tentang</a>
      <a href="../contact.html">Kontak</a>
      <a href="../privacy.html">Kebijakan Privasi</a>
      <a href="https://www.effectivecpmnetwork.com/setnp40u3t?key=fe8199ed8dd693be00f1924c13a1b7ec" target="_blank" rel="noopener sponsored">Rekomendasi</a>
    </div>
    <div>&copy; 2026 EdukasiTrader.</div>
  </div>
</footer>

</body>
</html>
"@

[System.IO.File]::WriteAllText($OutputPath, $template, $Utf8NoBom)
Write-Host "Halaman dibuat: $OutputPath"

# ---------------------------------------------------------------------------
# 5. Tambahkan ke homepage + sitemap (kecuali -SkipHomepage)
# ---------------------------------------------------------------------------
if (-not $SkipHomepage) {

  # --- index.html ---
  $indexContent = [System.IO.File]::ReadAllText($IndexPath, [System.Text.Encoding]::UTF8)

  $sectionPattern = '(?s)(<section class="category-section" id="riset-harian">.*?<div class="article-grid">)(.*?)(\s*</div>\s*</section>)'
  $sectionMatch = [regex]::Match($indexContent, $sectionPattern)
  if (-not $sectionMatch.Success) {
    Write-Warning "Section #riset-harian tidak ditemukan di index.html — card tidak ditambahkan otomatis. Tambahkan manual."
  } else {
    $newCard = @"


        <article class="card">
          <div class="tag">$CardTag</div>
          <h2><a href="market-analysis/$Slug.html">$Title</a></h2>
          <p class="excerpt">$Excerpt</p>
          <a class="read-more" href="market-analysis/$Slug.html">Baca selengkapnya →</a>
        </article>
"@
    $updatedInner = $sectionMatch.Groups[2].Value + $newCard
    $indexContent = $indexContent.Remove($sectionMatch.Index, $sectionMatch.Length).Insert(
      $sectionMatch.Index,
      $sectionMatch.Groups[1].Value + $updatedInner + $sectionMatch.Groups[3].Value
    )

    # update jumlah "(N catatan)"
    $indexContent = [regex]::Replace(
      $indexContent,
      '(id="riset-harian">\s*<h2 class="category-title">Riset &amp; Analisis Harian <span class="category-count">\()(\d+)( catatan\)</span>)',
      {
        param($m)
        $count = [int]$m.Groups[2].Value + 1
        $m.Groups[1].Value + $count + $m.Groups[3].Value
      }
    )

    [System.IO.File]::WriteAllText($IndexPath, $indexContent, $Utf8NoBom)
    Write-Host "Card baru ditambahkan ke index.html"
  }

  # --- sitemap.xml ---
  $sitemapContent = [System.IO.File]::ReadAllText($SitemapPath, [System.Text.Encoding]::UTF8)
  $newUrlEntry = @"
  <url>
    <loc>$SiteBaseUrl/market-analysis/$Slug.html</loc>
    <changefreq>never</changefreq>
    <priority>0.6</priority>
  </url>
</urlset>
"@
  if ($sitemapContent -match '</urlset>\s*$') {
    $sitemapContent = $sitemapContent -replace '</urlset>\s*$', $newUrlEntry
    [System.IO.File]::WriteAllText($SitemapPath, $sitemapContent, $Utf8NoBom)
    Write-Host "Entry baru ditambahkan ke sitemap.xml"
  } else {
    Write-Warning "Tidak menemukan penutup </urlset> di sitemap.xml — entry tidak ditambahkan otomatis."
  }
}

Write-Host ""
Write-Host "Selesai. Langkah selanjutnya:"
Write-Host "  1. Cek hasilnya: $OutputPath"
Write-Host "  2. git add, commit, push seperti biasa dari folder adsterra-blog"
