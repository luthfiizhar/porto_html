# AGENTS.md — Analisis Proyek `porto_html`

> Dokumen ini adalah hasil audit awal sekaligus panduan kerja untuk agent.
> Basis analisis: commit `1e603f7` (Initial commit), 24 Oktober 2026.
> Revisi 24 Oktober 2026: logo navbar/drawer memakai `assets/izhrmn-logo.png`;
> breakpoint nav dinaikkan ke 760px; section stats diganti current status strip;
> role hero memakai efek typing; branding copy memakai "Digital Solutions Partner".
> Nomor baris di bawah mengacu pada working tree terbaru.
> Sifat audit: **statis** (baca kode, cek struktur, hitung kontras, cek aset).
> Lighthouse dan screen reader belum dijalankan; layout logo/nav sudah dicek dengan Chrome headless.
> Nomor baris dapat bergeser setelah perubahan kode.

---

## 0. Aturan kerja singkat

- Proyek ini **satu file** `index.html` tanpa build tool, tanpa backend, tanpa `package.json`.
  Jangan menambahkan framework, bundler, atau dependency baru tanpa permintaan eksplisit.
- Pertahankan karakter visual: **Light Elegant / Stripe-like**, light + dark mode, tipografi ringan.
- Gunakan CSS custom property yang sudah ada di `:root` dan `[data-theme="dark"]`.
  Jangan hardcode warna baru di komponen tanpa alasan.
- Konten portofolio berbahasa **Inggris**; dokumen internal dan komentar boleh berbahasa Indonesia.
- Setiap perubahan UI wajib dicek di **light + dark**, **mobile + desktop**, dan **prefers-reduced-motion**.
- Jangan mengarang data karier. Sumber konten kanonik ada di project SvelteKit
  `/mnt/d/Projects/porto_svelte` (`src/lib/data/*.ts`).
- Section current status (Role/Based in/Focus/Availability) menggantikan statistik
  angka. Jangan mengembalikan `data-count`/count-up tanpa permintaan eksplisit.
- Jika menemukan dua versi data yang bertentangan, **jangan menebak** — tandai dan minta konfirmasi.
- Optimalkan aset sebelum menambah gambar. Jangan menambah PNG besar tanpa kompresi.
- Setelah perubahan, jalankan checklist di bagian 11.

---

## 1. Ringkasan proyek

Portofolio pribadi **Luthfi Izhariman**, software developer yang membranding diri
sebagai **Digital Solutions Partner** di Jakarta. Dibuat sebagai file HTML lokal yang bisa
langsung dibuka di browser, tanpa server dan tanpa proses build.

| Aspek | Kondisi |
|---|---|
| Entry point | `index.html` (910 baris, ±54 KB) |
| Build | Tidak ada |
| Backend | Tidak ada |
| Dependency runtime | Google Fonts (opsional; ada fallback system font) |
| Data | Array JS inline + markup statis |
| Tema | Light/dark, tersimpan di `localStorage`, default ikut `prefers-color-scheme` |
| Responsif | Breakpoint 920px, 760px (nav → drawer), 640px, dan 480px (status 1 kolom) |
| Interaksi | Vanilla JS: theme, typing role, filter proyek, timeline `<details>`, drawer, form `mailto:` |
| Aset | ±5,36 MB total; ±4,65 MB direferensikan; ±0,70 MB tidak terpakai |
| Git | 1 commit; ada perubahan lokal (logo + breakpoint nav) |

**Kekuatan utama**

- Visual konsisten dan rapi; token warna, shadow, radius, dan tipografi terpusat.
- Anti-flash theme: script kecil di `<head>` menerapkan tema sebelum paint.
- Aksesibilitas dasar sudah ada: `lang`, skip link, landmark, `aria-label` nav,
  `aria-expanded` hamburger, focus-visible, `role="status"` pada pesan form.
- Menghormati `prefers-reduced-motion` untuk scroll, reveal, dan typing role.
- Efek typing memakai `setTimeout` berantai dan caret CSS; saat reduced motion role statis.
- Semua path aset lokal yang direferensikan ada; tidak ada anchor rusak;
  tidak ada ID duplikat; tag HTML seimbang; kedua inline script lolos `node --check`.
- Filter proyek dan timeline memakai data terstruktur, mudah dirawat.
- CV disimpan lokal (`assets/CVLuthfi.pdf`), jadi tetap bisa diakses offline.

**Risiko utama**

1. Sebagian besar konten **tidak terlihat jika JavaScript gagal/dinonaktifkan**.
2. **Theme toggle hilang di mobile** (≤640px) dan tidak ada di drawer.
3. Drawer off-canvas **masih bisa difokuskan keyboard saat tertutup**.
4. Beban gambar besar (±3,9 MB project + ±696 KB foto) dan ada ±0,70 MB aset mati.
5. Beberapa kontras warna gagal WCAG AA, terutama tombol dark mode dan teks muted.
6. Data tanggal karier **tidak konsisten** antara Experience dan Timeline.
7. Konten proyek/timeline di-inject via JS; meta social/SEO belum lengkap.

---

## 2. Cara menjalankan dan memverifikasi

Cara paling aman (font dan download attribute berperilaku normal):

```bash
cd /home/luthfi/Projects/porto_html
python3 -m http.server 8000
# buka http://localhost:8000
```

Alternatif tanpa server:

```bash
xdg-open index.html
```

Catatan:

- `file://` didukung karena semua path relatif dan tidak ada `fetch`.
- Google Fonts membutuhkan internet. Jika offline, fallback `system-ui` dipakai.
- Form kontak tidak mengirim data ke server; ia membuka aplikasi email lewat `mailto:`.
- `download` pada link CV bisa diabaikan sebagian browser saat `file://`; link tetap membuka PDF.

Cek statis cepat:

```bash
cd /home/luthfi/Projects/porto_html
python3 - <<'PY'
import os, re
h = open('index.html', encoding='utf-8').read()
for p in sorted(set(re.findall(r'assets/[A-Za-z0-9_./-]+', h))):
    print('OK  ' if os.path.exists(p) else 'MISS', p)
ids = re.findall(r'\sid="([^"]+)"', h)
print('duplicate ids:', [i for i in set(ids) if ids.count(i) > 1] or 'none')
print('noscript:', '<noscript' in h)
print('og/twitter:', 'property="og:' in h or 'name="twitter:' in h)
PY
```

Verifikasi JS:

```bash
python3 - <<'PY'
import re
h = open('index.html', encoding='utf-8').read()
for i, s in enumerate(re.findall(r'<script>(.*?)</script>', h, re.S), 1):
    open(f'/tmp/porto_{i}.js', 'w').write(s)
PY
for f in /tmp/porto_*.js; do node --check "$f"; done
```

---

## 3. Struktur file

```
porto_html/
├── index.html                 # seluruh markup, CSS, dan JS
├── PLAN.md                    # rencana awal (status: selesai)
├── AGENTS.md                  # dokumen ini
├── .gitignore                 # .DS_Store, *.log, *.tmp
└── assets/
    ├── favicon.png            # 4 KB
    ├── izhrmn-logo.png        # 600×166, 12 KB, logo navbar/drawer (transparan)
    ├── photo_no_bg.png        # 605×1100, ±696 KB, dipakai hero
    ├── CVLuthfi.pdf           # 88 KB
    ├── projects/              # 7 screenshot PNG, total ±3,88 MB
    │   ├── vms.png            # 667×400, 438 KB
    │   ├── mrbs.png           # 667×400, 476 KB
    │   ├── gads.png           # 666×400, 529 KB
    │   ├── propman_mobile.png # 666×400, 414 KB
    │   ├── propman_web.png    # 999×600, 944 KB
    │   ├── emr.png            # 999×600, 786 KB
    │   └── absensi.png        # 666×400, 392 KB
    ├── api_services.svg       # tidak dipakai
    ├── deploy_services.svg    # tidak dipakai
    ├── web_services.svg       # tidak dipakai
    ├── undraw_web-developer_gxaa.svg # tidak dipakai
    └── mobile_dev_new.png     # 2000×2000, 687 KB, tidak dipakai
```

**Tidak ada**: `package.json`, test, linter, CI, README, `robots.txt`, `sitemap.xml`.

---

## 4. Peta halaman

Single page dengan anchor nav.

| Section | ID | Baris | Isi |
|---|---|---:|---|
| Navbar | — | 429 | Logo `Izhrmn`, 6 link, theme toggle, hamburger |
| Mobile drawer | `drawer` | 456 | Logo + 6 link; **tanpa theme toggle** |
| Hero | `home` | 473 | Nama, role typing, deskripsi, CTA CV/kontak, sosial, current status strip |
| About | `about` | 529 | Ringkasan profil, info grid 6 item, status freelance |
| Services | `services` | 556 | 5 layanan bernomor 01–05 |
| Resume | `resume` | 589 | Experience (5), Education (1), Skills (15), Timeline (15, `<details>`) |
| Projects | `projects` | 630 | Filter All/Web/Mobile + 7 kartu (di-inject JS) |
| Contact | `contact` | 647 | 3 kartu info + form `mailto:` |
| Footer | — | 696 | Brand, sosial, back-to-top, copyright dinamis |

Urutan baca dan hierarki heading baik: satu `h1`, beberapa `h2`, `h3` untuk sub-bagian.

---

## 5. Design system

Token utama (baris 22–63):

| Token | Light | Dark | Pemakaian |
|---|---|---|---|
| `--bg` | `#ffffff` | `#0a1628` | background utama |
| `--bg-soft` | `#f6f9fc` | `#0e1e33` | section `.alt` |
| `--surface` | `#ffffff` | `#0f2136` | card, drawer, form |
| `--heading` | `#061b31` | `#eef3f9` | judul |
| `--label` | `#273951` | `#c9d6e4` | label/nav |
| `--body` | `#64748d` | `#92a6ba` | body text |
| `--muted` | `#8ea0b5` | `#647d94` | meta, tanggal, hint |
| `--border` | `#e5edf5` | rgba(148,180,214,.14) | garis |
| `--accent` | `#533afd` | `#8b7dff` | CTA, link, aksen |
| `--accent-hover` | `#4434d4` | `#a193ff` | hover |
| `--success` | `#15be53` | sama | dot/status |
| `--footer-bg` | `#1c1e54` | `#081222` | footer |
| `--radius` | `6px` | sama | card |

- Font: **Source Sans 3** (300/400/600) untuk teks, **Source Code Pro** (400/500)
  untuk label teknis, angka, dan brand.
- Logo: `assets/izhrmn-logo.png` (600×166, latar transparan) di navbar dan drawer;
  tinggi tampil 36px. Di dark mode diberi `filter: invert(1) hue-rotate(180deg)`.
  Jika logo diganti, pertahankan latar transparan dan rasio aslinya.
- Current status strip: `<dl>` 4 item (Role, Based in, Focus, Availability), label
  mono uppercase, nilai Source Sans; 4 kolom → 2×2 di ≤920px → 1 kolom di ≤480px.
- Role hero: `ROLES = ['Software Developer', 'UI/UX Designer', 'System Integrator']`,
  efek typing + caret. Caret disembunyikan saat `prefers-reduced-motion`.
- Bobot judul 300, letter-spacing negatif, line-height rapat.
- Shadow berlapis khas Stripe: `--shadow-1/2/3`.
- Tombol utama memakai `--accent` + teks putih; tombol ghost memakai border aksen.
- Radius konservatif 4–6px; tidak ada pill.
- `text-wrap: pretty` dipakai pada heading dan paragraf.

Breakpoint:

- `≤920px`: grid hero/about/resume/contact menjadi 1 kolom, project 1 kolom, status strip 2×2.
- `≤760px`: nav link disembunyikan dan hamburger muncul (logo butuh ruang lebih).
- `≤640px`: theme toggle disembunyikan; form padding mengecil.
- `≤480px`: status strip menjadi 1 kolom agar teks role tidak terlalu sempit.

---

## 6. Data dan sinkronisasi konten

Sumber kanonik: `/mnt/d/Projects/porto_svelte/src/lib/data/*.ts`.

| Data | Sumber SvelteKit | Bentuk di `index.html` |
|---|---|---|
| Identitas | `site.ts` | Markup hero/about/contact |
| Role & status | `site.ts` + `resume.ts` | `ROLES` (Software Developer / UI/UX Designer / System Integrator) + current status strip |
| About | `resume.ts` `getAbout()` | Markup about |
| Experience/Education | `resume.ts` | Markup resume |
| Skills | `resume.ts` | 15 chip |
| Timeline | `resume.ts` | `TIMELINE` (15 entri), di-inject |
| Projects | `projects.ts` | `PROJECTS` (7 entri), di-inject |
| Services | `services.ts` | 5 baris teks (tanpa ilustrasi) |
| Contact | `contact.ts` + `site.ts` | Kartu + form |

### Deviasi yang disengaja

| Hal | Sumber | Di HTML | Alasan |
|---|---|---|---|
| CV | Google Drive | `assets/CVLuthfi.pdf` | Offline, sesuai PLAN |
| Skill “CSS 5” | typo | “CSS” | Koreksi |
| “Languanges” | typo | “Languages” | Koreksi |
| “English, Indonesia” | kurang tepat | “English, Indonesian” | Koreksi |
| “FLutter” | typo | “Flutter” | Koreksi |
| About description | kosong | ringkasan dari `home.description` | Agar tidak kosong |
| Tag proyek `All` | ada di setiap item | hanya `Web`/`Mobile`; `All` ditangani filter | Menghindari duplikasi |
| Ilustrasi services | 5 gambar | tidak dipakai | Desain list teks |
| Statistik 20/15/999 | `home.ts` | tidak ditampilkan | Diganti current status strip yang faktual, tanpa vanity metric |
| Positioning | `site.role` = “Software Developer” | “Digital Solutions Partner” di title, eyebrow, footer, meta; hero description baru | Branding sebagai penyedia solusi digital |

### Deviasi yang belum diselesaikan

| Hal | Lokasi | Detail |
|---|---|---|
| Tanggal PT Rekayasa Prima Mandiri | `index.html:602` vs `:737` | Experience: **Oct — Dec 2023**; Timeline: **Oct 2022**. Ini juga tidak konsisten di data sumber. Perlu konfirmasi manusia. |
| Year footer | `index.html:708` | Fallback statis `2026`; JS memperbarui, tetapi no-JS akan basi. |
| Foto About | PLAN | PLAN menyebut foto di About; implementasi hanya foto di hero. |

Catatan: beberapa typo sumber sudah dikoreksi di HTML (mis. “assis”, “webapplication”,
“Utiltiy”). Jika menyinkronkan ulang, jangan mengembalikan typo tersebut.

---

## 7. Perilaku JavaScript

| Fitur | Baris | Catatan |
|---|---:|---|
| Terapkan tema sebelum paint | 9–17 | Baca `localStorage`, fallback `prefers-color-scheme`; try/catch |
| Theme toggle | 753–760 | Set `data-theme`, simpan ke `localStorage` |
| Typing role | 761–800 | `setTimeout` berantai: hold → hapus → ketik role berikutnya; reduced motion statis |
| Render proyek | 802–815 | `innerHTML` dari array statis |
| Render timeline | 817–831 | `<details>` + `<summary>` |
| Filter proyek | 833–844 | Class `.hidden`; `data-tags` dicek dengan `indexOf` |
| Reveal on scroll | 846–852 | `IntersectionObserver`, threshold 0.12 |
| Active nav | 854–869 | `rootMargin: -40% 0px -55% 0px` |
| Drawer | 871–888 | Open/close, overlay, Escape, tutup saat link diklik |
| Form `mailto:` | 890–905 | Validasi hanya non-empty; encode subject/body |
| Year | 907–908 | `new Date().getFullYear()` |

Semua script berada di akhir `<body>` kecuali script tema di `<head>`.
Kedua script lolos pemeriksaan sintaks Node.

---

## 8. Hasil audit

### 8.1 Temuan berdasarkan prioritas

| ID | Prioritas | Temuan | Lokasi | Dampak |
|---|---|---|---|---|
| T1 | **Tinggi** | Konten `.reveal` default `opacity: 0`; hanya JS yang menambahkan `.visible`. Project & timeline juga di-inject JS. Tanpa JS, hampir semua section kosong. | CSS 381–382; observer 847–852; markup 505–523, 622, 642 | Konten hilang untuk no-JS, crawler lama, atau jika JS error |
| T2 | **Tinggi** | Theme toggle disembunyikan di `≤640px`, dan drawer tidak punya toggle. | 410; drawer 456–469 | Pengguna mobile tidak bisa ganti tema manual |
| T3 | **Tinggi** | Drawer tertutup hanya di-`translateX`; tidak ada `visibility`, `inert`, `aria-hidden`, focus trap, focus return, atau scroll lock. | CSS 136–144; JS 871–888 | Link off-screen masih masuk tab order; fokus bisa “hilang”; background ikut scroll |
| T4 | **Tinggi** | Kontras gagal AA: `--muted` light 2,68:1 (di white) / 2,53:1 (di soft); dark 4,23:1 / 3,80:1. Teks putih di aksen dark `#8b7dff` hanya 3,24:1 (hover 2,58:1). | Token 30, 52; tombol 176–177; filter 305; skip 88 | Sulit dibaca, terutama label kecil dan CTA dark mode |
| T5 | **Sedang** | Beban gambar besar: project ±3,88 MB, foto hero ±696 KB; ±0,70 MB aset tidak dipakai. | `assets/` | LCP lambat, kuota mobile boros |
| T6 | **Sedang** | Tanggal PT Rekayasa Prima Mandiri berbeda antara Experience (Oct–Dec 2023) dan Timeline (Oct 2022). | 602 vs 737 | Data karier tidak konsisten |
| T7 | **Selesai** | “Years of experience” hardcode 8 sudah dihapus bersama section stats lama; diganti current status strip. | 505–523 | Tidak ada angka yang bisa basi |
| T8 | **Sedang** | Tidak ada Open Graph/Twitter Card, canonical, JSON-LD, `theme-color`, `author`, apple-touch-icon. Konten proyek/timeline tidak ada di HTML awal. | `<head>` 5–21 | Preview sosial jelek; SEO/crawler lemah |
| T9 | **Rendah** | Drawer tidak punya `aria-controls`, `role="dialog"`, `aria-modal`; active nav tidak pakai `aria-current`; filter tidak pakai `aria-pressed`; error form tidak terhubung ke field (`aria-invalid`/`aria-describedby`). | 429–469, 854–869, 637–644, 670–688 | Pengalaman screen reader kurang optimal |
| T10 | **Rendah** | `word-break: break-all` pada kontak memotong email/telepon di tengah karakter. | 345 | Tipografi kurang rapi |
| T11 | **Rendah** | Form memakai `novalidate` dan hanya cek kosong; format email tidak diverifikasi. | 670, 890–905 | Email invalid bisa lolos ke `mailto:` |
| T12 | **Rendah** | Warna error hardcode `#ea2261` (4,29:1 di white; 3,80:1 di surface dark); success `#15be53` di white hanya 2,46:1. Tidak ada token `--error`/`--on-accent`. | 363, 898 | Kontras status gagal; sulit dirawat |
| T13 | **Rendah** | `innerHTML` menyusun title/desc tanpa escaper umum; hanya `alt` yang meng-escape `&`. | 802–815, 817–831 | Aman untuk data statis saat ini; berisiko jika data eksternal |
| T14 | **Rendah** | Google Fonts stylesheet render-blocking; dua family beberapa weight. | 19–21 | First paint sedikit tertunda; offline pakai fallback |
| T15 | **Rendah** | Tidak ada `srcset`, width/height pada gambar proyek (container aspect-ratio membantu CLS), dan gambar hero eager ±696 KB. | 802–815; 501 | Mobile mengunduh gambar lebih besar dari kebutuhan |
| T16 | **Selesai** | Nav 641–760px sempat mepet karena logo lebih lebar dari teks brand. Drawer sekarang aktif pada `≤760px`. | 405–408 | Risiko overflow teratasi; tetap cek 761px ke atas |
| T17 | **Rendah** | Tidak ada README, test, linter, CI, atau dokumentasi deploy. | root | Onboarding dan regresi manual |
| T18 | **Rendah** | `color-scheme` tidak diset; scrollbar/control native bisa tidak cocok dengan dark mode. | CSS root | Detail polish |
| T19 | **Rendah** | Footer punya `margin-top: 96px` setelah section contact yang sudah berpadding, sehingga jarak terasa berlebih. | 368 | Estetika |
| T20 | **Rendah** | Beberapa ikon dekoratif (mis. `+` timeline, dot) tidak `aria-hidden`. | 208, 241, 823 | Bisa dibacakan screen reader sebagai noise |

### 8.2 Detail temuan penting

#### T1 — Konten hilang tanpa JS

Alurnya:

1. `.reveal` di-set `opacity: 0` (baris 381).
2. JS menambahkan `.visible` lewat `IntersectionObserver` (baris 847–852).
3. `PROJECTS` dan `TIMELINE` di-render dengan `innerHTML` (baris 802–831).

Jika JS dimatikan, gagal dimuat, atau `IntersectionObserver` tidak tersedia:

- Hero (termasuk current status strip) dan footer terlihat.
- Judul section, about, services, resume, skills, filter, contact, form, project, dan timeline
  tidak terlihat/kosong.
- Drawer/form/theme tidak berfungsi (selain tema awal dari `<head>`).

Perbaikan yang disarankan:

- Tambahkan fallback `<noscript>` yang memaksa `.reveal { opacity: 1; transform: none; }`.
- Buat pola bertahap: konten default terlihat, lalu JS menambahkan class `.js-ready`
  pada `<html>` sebelum observer aktif; CSS hanya menyembunyikan `.js-ready .reveal`.
- Bungkus pembuatan `IntersectionObserver` dengan feature check; jika tidak ada,
  tambahkan `.visible` ke semua `.reveal`.
- Pertimbangkan merender project dan timeline langsung di HTML, atau menyediakan
  fallback `<noscript>` yang berisi konten inti. Ini juga membantu SEO. Current status
  strip sudah berupa markup statis, jadi tetap terlihat tanpa JS.

#### T2 — Theme toggle mobile

Baris 410 menyembunyikan `.nav-actions #theme-toggle` pada `≤640px`.
Drawer (baris 456–469) hanya berisi logo dan link navigasi, tanpa tombol tema.
Akibatnya pengguna mobile tidak bisa memilih tema, meskipun preferensi tersimpan
dan tema awal mengikuti sistem.

Perbaikan: tambahkan tombol tema di `drawer-head` atau pertahankan toggle di nav mobile.
Pastikan `aria-label`, ikon matahari/bulan, dan persistensi tetap bekerja.

#### T3 — Drawer off-canvas dan fokus

Drawer hanya memakai `transform: translateX(100%)` dan tidak memiliki:

- `visibility: hidden` saat tertutup,
- `inert`/`aria-hidden="true"`,
- focus trap saat terbuka,
- pemindahan fokus ke tombol close,
- pengembalian fokus ke hamburger,
- `overflow: hidden` pada `body` saat terbuka,
- `role="dialog"`/`aria-modal="true"` (meskipun ini aside navigasi, untuk modal drawer sebaiknya).

Dampak: link drawer yang tidak terlihat tetap bisa dicapai dengan Tab; fokus bisa
berpindah ke elemen di belakang overlay; halaman di belakang tetap scroll.

Perbaikan: kelola state `open` di JS, set `inert`/`aria-hidden` saat tertutup,
focus trap sederhana, `document.body.style.overflow = 'hidden'` saat terbuka,
kembalikan fokus ke `#hamburger` saat ditutup.

#### T4 — Kontras

Dihitung dari token saat ini:

| Teks | Background | Rasio | Target AA normal |
|---|---|---:|---:|
| `--muted` `#8ea0b5` | white | 2,68:1 | 4,5:1 |
| `--muted` `#8ea0b5` | `#f6f9fc` | 2,53:1 | 4,5:1 |
| `--body` `#64748d` | `#f6f9fc` | 4,49:1 | 4,5:1 (borderline) |
| `--muted` dark `#647d94` | `#0a1628` | 4,23:1 | 4,5:1 |
| `--muted` dark `#647d94` | `#0f2136` | 3,80:1 | 4,5:1 |
| White on dark accent `#8b7dff` | — | 3,24:1 | 4,5:1 |
| White on dark accent hover `#a193ff` | — | 2,58:1 | 4,5:1 |
| `--success` `#15be53` | white | 2,46:1 | 4,5:1 |
| Error `#ea2261` | white | 4,29:1 | 4,5:1 |
| Error `#ea2261` | dark surface | 3,80:1 | 4,5:1 |

Perbaikan yang disarankan:

- Gelapkan `--muted` light menjadi sekitar `#5f748c` (≈4,8:1 di white, ≈4,55:1 di soft).
- Terangkan `--muted` dark menjadi sekitar `#7e95ac` (≈5,85:1 di bg, ≈5,25:1 di surface).
- Tambahkan token `--on-accent`: putih di light, gelap (`#081222`) di dark;
  pakai untuk `.btn-primary`, `.filter-btn.active`, dan `.skip`.
- Tambahkan `--error` per tema (mis. `#d81b60` light; versi lebih terang di dark)
  dan `--success-text` yang memenuhi kontras di light mode.
- Naikkan kontras `tag-mini` dark (saat ini sekitar 4,24:1 di surface) dengan
  mengurangi tint background atau memakai teks aksen yang lebih terang.
- Verifikasi ulang semua pasangan dengan alat kontras setelah perubahan.

#### T5 — Aset

Total aset ±5,36 MB; yang direferensikan ±4,65 MB. Project saja ±3,88 MB.
File terbesar: `propman_web.png` 944 KB, `emr.png` 786 KB, `photo_no_bg.png` 696 KB.
Lima file tidak dipakai: 4 SVG + `mobile_dev_new.png` (total ±0,70 MB).

Perbaikan:

- Konversi screenshot ke WebP/AVIF dengan kualitas ±75–82; target total project <1 MB.
- Resize sesuai ukuran tampil ×2 (mis. 1000×600 untuk 2 kolom, 700×420 untuk mobile).
- Optimalkan foto hero; 605×1100 untuk lingkaran 320px bisa diperkecil/di-crop.
- Hapus aset tidak terpakai dari repo atau pindahkan ke folder sumber di luar deploy.
- Tambahkan `srcset`/`sizes` dan `width`/`height` pada project card.
- Pertimbangkan self-host font yang di-subset jika offline/privacy penting.

#### T6 — Tanggal karier

- Experience (baris 602): `Oct — Dec 2023`.
- Timeline (baris 737): `Oct 2022`.
- Data sumber SvelteKit juga memiliki ketidakcocokan ini.

Jangan menebak. Konfirmasi ke pemilik data, lalu samakan keduanya.
Jika mengubah salah satu, cek juga urutan kronologis timeline dan durasi experience.

#### T7 — Years of experience (selesai)

Section angka 8/20/15/999 sudah dihapus dan diganti current status strip
(role, based in, focus, availability) pada baris 505–523. Tidak ada lagi
`data-count` atau animasi count-up. `getYearsOfExperience()` di sumber SvelteKit
tidak lagi dipakai di halaman ini.

#### T8 — SEO dan social preview

Sudah ada: `<title>`, meta description, favicon, `lang="en"`, heading hierarkis,
teks alt pada gambar, dan URL sosial yang benar.

Belum ada:

- `og:title`, `og:description`, `og:image` (1200×630), `og:url`, `og:type`,
  `twitter:card`, `twitter:image`.
- `<link rel="canonical">`.
- JSON-LD `Person` (nama, role, URL, sameAs GitHub/LinkedIn).
- `meta name="theme-color"` (light/dark).
- `meta name="author"`.
- `apple-touch-icon`.
- `robots.txt`/`sitemap.xml` jika akan di-deploy.

Karena project dan timeline di-inject JS, crawler yang tidak mengeksekusi JS
tidak melihat konten inti. Rendering statis atau fallback `<noscript>` dianjurkan.

#### T9–T20 — Perbaikan kecil

- Tambahkan `aria-controls="drawer"` pada hamburger.
- Gunakan `aria-current="page"` pada nav link aktif (bukan hanya class).
- Tambahkan `aria-pressed` pada filter.
- Tambahkan `aria-invalid` dan `aria-describedby` saat error form.
- Ganti `word-break: break-all` dengan `overflow-wrap: anywhere`/`word-break: break-word`
  agar email tidak terpotong di tengah karakter tanpa perlu.
- Validasi email dengan `input.checkValidity()` atau pola sederhana sebelum `mailto:`.
- Tambahkan token `--error` dan `--on-accent`; jangan hardcode warna di JS.
- Escape semua data yang masuk `innerHTML` jika data kelak berasal dari luar.
- Set `color-scheme: light dark` dan sesuaikan per tema.
- Tambahkan `width`/`height`/`decoding="async"` pada gambar proyek.
- Tambahkan `aria-hidden="true"` pada ikon dekoratif.
- Breakpoint nav sudah dinaikkan ke 760px; verifikasi ulang jika logo/lebar brand berubah.
- Pertimbangkan print stylesheet untuk CV/portofolio.
- Tambahkan README singkat dan, jika deploy, workflow pengecekan link/HTML.

---

## 9. Rencana perbaikan yang disarankan

### P0 — sebelum dipublikasikan

1. **Fallback no-JS dan error JS** (T1)
   - Konten default terlihat; `.reveal` hanya disembunyikan jika JS siap.
   - Feature check `IntersectionObserver`.
   - Acceptance: dengan JS disabled, semua section, 7 project, 15 timeline,
     dan current status strip tetap terlihat.
2. **Theme toggle mobile** (T2)
   - Tombol tema tersedia di drawer atau nav mobile.
   - Acceptance: toggle berfungsi di 375px, tersimpan setelah reload.
3. **Drawer accessibility** (T3)
   - `inert`/`aria-hidden` saat tertutup, focus trap, focus return, scroll lock.
   - Acceptance: Tab tidak mencapai drawer tertutup; Escape menutup dan fokus
     kembali ke hamburger; background tidak scroll.

### P1 — kualitas dan performa

4. **Perbaiki kontras** (T4) — token muted, `--on-accent`, error/success, tag dark.
5. **Optimalkan aset** (T5) — WebP/AVIF, resize, hapus aset mati, `srcset`.
6. **Samakan tanggal karier** (T6) — konfirmasi lalu sinkronkan.
7. **SEO/social** (T8) — OG/Twitter, canonical, JSON-LD, theme-color.

### P2 — polish

8. A11y tambahan (T9), word-break (T10), validasi email (T11), token error (T12).
9. Escaping data (T13), font strategy (T14), image dimensions (T15); breakpoint nav (T16) sudah selesai.
10. README/CI (T17), `color-scheme` (T18), footer spacing (T19), ikon dekoratif (T20).
11. Pertimbangkan render statis project/timeline untuk SEO jangka panjang.

---

## 10. Konvensi implementasi

- **Satu file**: kecuali aset, semua perubahan UI masuk `index.html`.
- **CSS**: ikuti urutan bagian yang ada (tokens → base → navbar → drawer → hero →
  sections → resume → projects → contact → footer → reveal → responsive).
  Gunakan komentar `/* ============ ... ============ */` yang sudah ada.
- **Selector**: pertahankan nama class yang sudah dipakai; jangan rename tanpa alasan.
- **Warna**: gunakan token; jika perlu token baru, definisikan di light dan dark.
- **JS**: vanilla ES5-style (`var`, `function`) agar konsisten dan aman di browser lama.
  Tidak ada modul, transpiler, atau polyfill.
- **Data**: array `PROJECTS`/`TIMELINE` tetap di dalam file. Jika menambah proyek,
  update juga `assets/projects/` dan pastikan filter `tags` benar.
- **Konten**: jangan mengubah fakta karier tanpa sumber; sinkronkan dengan SvelteKit.
- **Aksesibilitas**: setiap interaksi harus bisa keyboard; jangan menghapus focus outline;
  hormati reduced motion.
- **Responsif**: uji minimal 320, 375, 480, 640, 768, 920, 1024, 1440px.
- **Aset**: nama file deskriptif, huruf kecil, kompresi sebelum commit.
- **Git**: commit kecil dan jelas; jangan commit file sementara/`.DS_Store`.

---

## 11. Checklist verifikasi

### Struktural

- [ ] HTML parse tanpa tag tidak seimbang.
- [ ] Tidak ada ID duplikat.
- [ ] Semua `href="#..."` punya target.
- [ ] Semua `src`/`href` aset lokal ada (termasuk 7 gambar project).
- [ ] Tidak ada link eksternal rusak (GitHub, LinkedIn, Google Fonts).
- [ ] Kedua inline script lolos `node --check`.

### Visual dan responsif

- [ ] Light dan dark mode konsisten di semua section.
- [ ] Tidak ada horizontal scroll di 320/375/480/640/768/1024/1440px.
- [ ] Nav tidak overflow di 761px ke atas; drawer aktif di ≤760px.
- [ ] Drawer membuka/menutup, overlay, Escape, dan klik link bekerja.
- [ ] Project filter All/Web/Mobile menampilkan kartu yang benar.
- [ ] Timeline `<details>` bisa dibuka/tutup, termasuk via keyboard.
- [ ] Hero photo dan badge tidak menutupi teks di mobile.
- [ ] Footer tidak terlalu rapat/lebar di mobile.

### Aksesibilitas

- [ ] Skip link muncul saat fokus.
- [ ] Semua tombol/link punya nama aksesibel.
- [ ] Fokus terlihat di light dan dark.
- [ ] Drawer tertutup tidak bisa difokuskan.
- [ ] Fokus kembali ke hamburger setelah drawer ditutup.
- [ ] `aria-expanded`/`aria-controls` benar.
- [ ] Nav aktif memakai `aria-current` (jika diperbaiki).
- [ ] Filter memakai `aria-pressed` (jika diperbaiki).
- [ ] Error form terbaca dan terhubung ke field.
- [ ] Kontras teks ≥4,5:1 (≥3:1 untuk teks besar).
- [ ] `prefers-reduced-motion` menonaktifkan animasi.
- [ ] Typing role berhenti dan caret tersembunyi saat reduced motion.
- [ ] Uji dengan keyboard saja dan screen reader dasar.

### Fungsional

- [ ] Theme toggle bekerja dan persist setelah reload.
- [ ] Default tema mengikuti sistem saat belum ada pilihan.
- [ ] Tidak ada flash tema saat reload.
- [ ] Download CV membuka/mengunduh `assets/CVLuthfi.pdf`.
- [ ] Form membuka aplikasi email dengan subject/body terisi.
- [ ] Validasi kosong menampilkan pesan error.
- [ ] Year footer mengikuti tahun berjalan.

### No-JS / offline

- [ ] Dengan JS disabled: semua section, project, timeline, dan current status strip terlihat.
- [ ] Tanpa internet: font fallback bekerja, layout tidak rusak.
- [ ] Tidak ada error console saat offline.

### Performa / SEO

- [ ] Total aset yang diunduh masuk akal (<2 MB ideal untuk halaman ini).
- [ ] Screenshot project dalam WebP/AVIF dan ukuran sesuai tampilan.
- [ ] Hero image tidak menjadi LCP yang berat.
- [ ] Ada OG image + title/description yang tampil benar saat share.
- [ ] Ada canonical/JSON-LD jika di-deploy.
- [ ] Tidak ada aset 404 di Network tab.

---

## 12. Catatan dan batasan audit

- Audit awal tidak menjalankan browser sungguhan. Layout logo/nav sudah dicek dengan
  Chrome headless pada light/dark dan lebar 641–1440px. Fokus drawer (T3) dan perilaku
  `mailto:` tetap perlu diverifikasi manual.
- Perhitungan kontras memakai nilai token CSS, bukan sampling piksel setelah render.
- Sumber konten SvelteKit berada di luar repo ini dan bisa berubah.
  Path `/mnt/d/Projects/porto_svelte` tersedia di mesin audit saat ini.
- `file://` dan `http://localhost` bisa berbeda untuk `download`, font, dan localStorage.
  Selalu uji keduanya jika mengubah tema, CV, atau form.
- Nomor baris mengacu pada commit `1e603f7`; gunakan pencarian teks jika sudah berubah.
- Jika ragu antara mempertahankan desain atau memperbaiki aksesibilitas,
  dahulukan aksesibilitas dan konten yang tetap terlihat tanpa JS.
