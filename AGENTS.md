# AGENTS.md — Analisis Proyek `porto_html`

> Dokumen ini adalah hasil audit awal sekaligus panduan kerja untuk agent.
> Basis analisis: commit `1e603f7` (Initial commit), 24 Oktober 2026.
> Revisi 24 Oktober 2026: logo navbar/drawer memakai `assets/izhrmn-logo.png`;
> breakpoint nav dinaikkan ke 760px; section stats diganti current status strip;
> role hero memakai efek typing; branding copy memakai "Digital Solutions Partner";
> font self-hosted, gambar responsif WebP, dan token kontras diperbaiki.
> Nomor baris di bawah mengacu pada working tree terbaru.
> Sifat audit: **statis** + Lighthouse 13.4.1 mobile (Chromium headless).
> Screen reader manual belum dijalankan. Nomor baris dapat bergeser setelah perubahan kode.

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
| Entry point | `index.html` (937 baris, ±55 KB) |
| Build | Tidak ada |
| Backend | Tidak ada |
| Dependency runtime | Tidak ada; font WOFF2 di-host lokal (`assets/fonts/`) |
| Data | Array JS inline + markup statis |
| Tema | Light/dark, tersimpan di `localStorage`, default ikut `prefers-color-scheme` |
| Responsif | Breakpoint 920px, 760px (nav → drawer), 640px, dan 480px (status 1 kolom) |
| Interaksi | Vanilla JS: theme, typing role, filter proyek, timeline `<details>`, drawer, form `mailto:` |
| Aset | ±5,78 MB di repo; initial load Lighthouse 141 KiB; ±0,70 MB tidak terpakai |
| Git | 1 commit; ada perubahan lokal (logo, branding, optimasi performa) |

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
- Font self-hosted, hero/logo responsif, dan WebP untuk project; Lighthouse mobile
  **Performance 99–100 / Accessibility 100 / Best Practices 100 / SEO 100**.
- Kontras light/dark lolos; tidak ada request third-party saat load.

**Risiko utama**

1. Sebagian besar konten **tidak terlihat jika JavaScript gagal/dinonaktifkan**.
2. **Theme toggle hilang di mobile** (≤640px) dan tidak ada di drawer.
3. Drawer off-canvas **masih bisa difokuskan keyboard saat tertutup**.
4. Data tanggal karier **tidak konsisten** antara Experience dan Timeline.
5. Konten proyek/timeline di-inject via JS; meta social/SEO belum lengkap.
6. Repo masih menyimpan fallback PNG project (±3,9 MB) dan ±0,70 MB aset tidak dipakai;
   ini tidak memengaruhi initial load karena gambar project lazy-loaded.

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
- Font self-hosted di `assets/fonts/`; offline tetap memakai font yang sama. Fallback `system-ui` hanya jika font gagal dimuat.
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
    ├── favicon/               # ikon 16/32/192/512, favicon.ico, apple-touch, manifest
    ├── izhrmn-logo.png        # 600×166, 12 KB, fallback logo transparan
    ├── izhrmn-logo-260.png    # 260×72, 6 KB, varian srcset
    ├── izhrmn-logo-390.png    # 390×108, 9 KB, varian srcset
    ├── photo_no_bg.png        # 605×1100, ±696 KB, fallback hero PNG
    ├── photo_no_bg-320.webp   # 320×320, 17 KB
    ├── photo_no_bg-520.webp   # 520×520, 31 KB
    ├── photo_no_bg-640.webp   # 640×640, 40 KB, varian terbesar
    ├── CVLuthfi.pdf           # 88 KB
    ├── fonts/                 # self-hosted Latin WOFF2, total ±50 KB
    │   ├── source-sans-3-latin.woff2
    │   └── source-code-pro-latin.woff2
    ├── projects/              # 7 screenshot PNG (±3,88 MB) + WebP (±243 KB)
    │   ├── vms.png / vms.webp
    │   ├── mrbs.png / mrbs.webp
    │   ├── gads.png / gads.webp
    │   ├── propman_mobile.png / propman_mobile.webp
    │   ├── propman_web.png / propman_web.webp
    │   ├── emr.png / emr.webp
    │   └── absensi.png / absensi.webp
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
| Navbar | — | 453 | Logo `Izhrmn`, 6 link, theme toggle, hamburger |
| Mobile drawer | `drawer` | 480 | Logo + 6 link; **tanpa theme toggle** |
| Hero | `home` | 497 | Nama, role typing, deskripsi, CTA CV/kontak, sosial, current status strip |
| About | `about` | 556 | Ringkasan profil, info grid 6 item, status freelance |
| Services | `services` | 583 | 5 layanan bernomor 01–05 |
| Resume | `resume` | 616 | Experience (5), Education (1), Skills (15), Timeline (15, `<details>`) |
| Projects | `projects` | 657 | Filter All/Web/Mobile + 7 kartu (di-inject JS) |
| Contact | `contact` | 674 | 3 kartu info + form `mailto:` |
| Footer | — | 723 | Brand, sosial, back-to-top, copyright dinamis |

Urutan baca dan hierarki heading baik: satu `h1`, beberapa `h2`, `h3` untuk sub-bagian.

---

## 5. Design system

Token utama (baris 37–78):

| Token | Light | Dark | Pemakaian |
|---|---|---|---|
| `--bg` | `#ffffff` | `#0a1628` | background utama |
| `--bg-soft` | `#f6f9fc` | `#0e1e33` | section `.alt` |
| `--surface` | `#ffffff` | `#0f2136` | card, drawer, form |
| `--heading` | `#061b31` | `#eef3f9` | judul |
| `--label` | `#273951` | `#c9d6e4` | label/nav |
| `--body` | `#5b7089` | `#92a6ba` | body text |
| `--muted` | `#61748d` | `#7e95ac` | meta, tanggal, hint |
| `--border` | `#e5edf5` | rgba(148,180,214,.14) | garis |
| `--accent` | `#533afd` | `#8b7dff` | CTA, link, aksen |
| `--accent-hover` | `#4434d4` | `#a193ff` | hover |
| `--on-accent` | `#ffffff` | `#081222` | teks di atas aksen |
| `--success` | `#15be53` | sama | dot/status |
| `--success-text` | `#0f7a37` | `#4ade80` | pesan sukses |
| `--error` | `#c81e5b` | `#ff8fb3` | pesan error |
| `--footer-bg` | `#1c1e54` | `#081222` | footer |
| `--radius` | `6px` | sama | card |

- Font self-hosted: **Source Sans 3** (300–600 variable) untuk teks,
  **Source Code Pro** (400–500 variable) untuk label teknis, angka, dan brand.
  `@font-face` ada di awal `<style>`; tidak ada request Google Fonts.
- Logo: `assets/izhrmn-logo-390.png` + `srcset` 260/390/600, tinggi tampil 36px,
  di navbar dan drawer. Di dark mode diberi `filter: invert(1) hue-rotate(180deg)`.
  Jika logo diganti, pertahankan latar transparan, rasio, dan varian srcset.
- Hero image: `<picture>` WebP 320/520/640 + fallback PNG, preload `imagesrcset`,
  `fetchpriority=high`, rendered 320×320 (square). Project cards memakai WebP
  dengan fallback PNG dan atribut width/height.
- Current status strip: `<dl>` 4 item (Role, Based in, Focus, Availability), label
  mono uppercase, nilai Source Sans; 4 kolom → 2×2 di ≤920px → 1 kolom di ≤480px.
- Role hero: `ROLES = ['Software Developer', 'UI/UX Designer', 'System Integrator']`,
  efek typing + caret. Caret disembunyikan saat `prefers-reduced-motion`.
- Bobot judul 300, letter-spacing negatif, line-height rapat.
- Shadow berlapis khas Stripe: `--shadow-1/2/3`.
- Tombol utama memakai `--accent` + `--on-accent`; tombol ghost memakai border aksen.
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
| Projects | `projects.ts` | `PROJECTS` (7 entri + `w`/`h`), di-inject; WebP + fallback PNG |
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
| Tanggal PT Rekayasa Prima Mandiri | `index.html:629` vs `:764` | Experience: **Oct — Dec 2023**; Timeline: **Oct 2022**. Ini juga tidak konsisten di data sumber. Perlu konfirmasi manusia. |
| Year footer | `index.html:741` | Fallback statis `2026`; JS memperbarui, tetapi no-JS akan basi. |
| Foto About | PLAN | PLAN menyebut foto di About; implementasi hanya foto di hero. |

Catatan: beberapa typo sumber sudah dikoreksi di HTML (mis. “assis”, “webapplication”,
“Utiltiy”). Jika menyinkronkan ulang, jangan mengembalikan typo tersebut.

---

## 7. Perilaku JavaScript

| Fitur | Baris | Catatan |
|---|---:|---|
| Terapkan tema sebelum paint | 9–17 | Baca `localStorage`, fallback `prefers-color-scheme`; try/catch |
| Theme toggle | 780–787 | Set `data-theme`, simpan ke `localStorage` |
| Typing role | 788–827 | `setTimeout` berantai: hold → hapus → ketik role berikutnya; reduced motion statis |
| Render proyek | 829–842 | `innerHTML` dari array statis; `<picture>` WebP + fallback PNG |
| Render timeline | 844–858 | `<details>` + `<summary>` |
| Filter proyek | 860–871 | Class `.hidden`; `data-tags` dicek dengan `indexOf` |
| Reveal on scroll | 873–879 | `IntersectionObserver`, threshold 0.12 |
| Active nav | 881–896 | `rootMargin: -40% 0px -55% 0px` |
| Drawer | 898–915 | Open/close, overlay, Escape, tutup saat link diklik |
| Form `mailto:` | 917–932 | Validasi hanya non-empty; encode subject/body; kelas `.is-error` |
| Year | 934–935 | `new Date().getFullYear()` |

Semua script berada di akhir `<body>` kecuali script tema di `<head>`.
Kedua script lolos pemeriksaan sintaks Node.

---

## 8. Hasil audit

### 8.1 Temuan berdasarkan prioritas

| ID | Prioritas | Temuan | Lokasi | Dampak |
|---|---|---|---|---|
| T1 | **Tinggi** | Konten `.reveal` default `opacity: 0`; hanya JS yang menambahkan `.visible`. Project & timeline juga di-inject JS. Tanpa JS, hampir semua section kosong. | CSS 405–406; observer 874–879; markup 532–550, 649, 669 | Konten hilang untuk no-JS, crawler lama, atau jika JS error |
| T2 | **Tinggi** | Theme toggle disembunyikan di `≤640px`, dan drawer tidak punya toggle. | 434; drawer 480–493 | Pengguna mobile tidak bisa ganti tema manual |
| T3 | **Tinggi** | Drawer tertutup hanya di-`translateX`; tidak ada `visibility`, `inert`, `aria-hidden`, focus trap, focus return, atau scroll lock. | CSS 150–158; JS 898–915 | Link off-screen masih masuk tab order; fokus bisa “hilang”; background ikut scroll |
| T4 | **Selesai** | Kontras sudah diperbaiki. `--muted` light `#61748d`, dark `#7e95ac`; `--on-accent` untuk tombol/filter/skip; `--error` dan `--success-text` per tema. Lighthouse Accessibility 100. | Token 37–78; 108, 196–197, 326, 344 | — |
| T5 | **Selesai** | Hero memakai `<picture>` WebP 320/520/640 + fallback PNG, preload `imagesrcset`, `fetchpriority=high`. Project cards memakai WebP + fallback PNG. Initial load Lighthouse 141 KiB (dari 809 KiB). Repo masih menyimpan fallback PNG. | 18, 526–527, 749–757, 834 | — |
| T6 | **Sedang** | Tanggal PT Rekayasa Prima Mandiri berbeda antara Experience (Oct–Dec 2023) dan Timeline (Oct 2022). | 629 vs 764 | Data karier tidak konsisten |
| T7 | **Selesai** | “Years of experience” hardcode 8 sudah dihapus bersama section stats lama; diganti current status strip. | 532–550 | Tidak ada angka yang bisa basi |
| T8 | **Sebagian** | Favicon set, apple-touch, dan manifest sudah ada. Belum ada Open Graph/Twitter Card, canonical, JSON-LD, `theme-color`, `author`. Konten proyek/timeline tidak ada di HTML awal. Lighthouse SEO 100 di localhost, tetapi preview sosial tetap belum ada. | `<head>` 5–448 | Preview sosial jelek; crawler non-JS lemah |
| T9 | **Rendah** | Drawer tidak punya `aria-controls`, `role="dialog"`, `aria-modal`; active nav tidak pakai `aria-current`; filter tidak pakai `aria-pressed`; error form tidak terhubung ke field (`aria-invalid`/`aria-describedby`). | 453–493, 881–896, 664–671, 697–715 | Pengalaman screen reader kurang optimal |
| T10 | **Rendah** | `word-break: break-all` pada kontak memotong email/telepon di tengah karakter. | 368 | Tipografi kurang rapi |
| T11 | **Rendah** | Form memakai `novalidate` dan hanya cek kosong; format email tidak diverifikasi. | 697, 917–932 | Email invalid bisa lolos ke `mailto:` |
| T12 | **Selesai** | Error/success memakai token `--error` / `--success-text`, bukan warna hardcode; JS memakai class `.is-error`. | 386–387, 925, 931 | — |
| T13 | **Rendah** | `innerHTML` menyusun title/desc tanpa escaper umum; hanya `alt` yang meng-escape `&`. | 829–842, 844–858 | Aman untuk data statis saat ini; berisiko jika data eksternal |
| T14 | **Selesai** | Google Fonts diganti self-hosted WOFF2 (`assets/fonts/`); tidak ada stylesheet font render-blocking atau request third-party. | 20–35 | — |
| T15 | **Selesai** | Hero/logo memakai `srcset`/`sizes`; logo punya varian 260/390/600; project card punya WebP + width/height. LCP discovery score 1. | 456, 482, 526–527, 834 | — |
| T16 | **Selesai** | Nav 641–760px sempat mepet karena logo lebih lebar dari teks brand. Drawer sekarang aktif pada `≤760px`. | 429–432 | Risiko overflow teratasi; tetap cek 761px ke atas |
| T17 | **Rendah** | Tidak ada README, test, linter, CI, atau dokumentasi deploy. | root | Onboarding dan regresi manual |
| T18 | **Rendah** | `color-scheme` tidak diset; scrollbar/control native bisa tidak cocok dengan dark mode. | CSS root | Detail polish |
| T19 | **Rendah** | Footer punya `margin-top: 96px` setelah section contact yang sudah berpadding, sehingga jarak terasa berlebih. | 393 | Estetika |
| T20 | **Rendah** | Beberapa ikon dekoratif (mis. `+` timeline, dot) tidak `aria-hidden`. | 229, 262, 850 | Bisa dibacakan screen reader sebagai noise |

### 8.2 Lighthouse terbaru (mobile)

Dijalankan 24 Oktober 2026 dengan Lighthouse 13.4.1, Chromium headless, viewport mobile 412×823, terhadap `http://localhost:8000`.

| Kategori | Skor |
|---|---:|
| Performance | **99–100** (varians antar run) |
| Accessibility | **100** |
| Best Practices | **100** |
| SEO | **100** |

| Metrik | Nilai |
|---|---:|
| FCP | 1,4 s |
| LCP | 1,7 s |
| TBT | 0 ms |
| CLS | 0,01 |
| TTI | 1,7 s |
| Total transfer | 141 KiB |
| Request | 5 |

Sisa audit yang tidak terhindarkan di localhost: cache lifetime 0 dan tanpa kompresi (server `python3 -m http.server`). `unminified-css`/`unminified-javascript` hanya ±6 KiB dan tidak menurunkan skor.

### 8.3 Detail temuan penting

#### T1 — Konten hilang tanpa JS

Alurnya:

1. `.reveal` di-set `opacity: 0` (baris 405).
2. JS menambahkan `.visible` lewat `IntersectionObserver` (baris 874–879).
3. `PROJECTS` dan `TIMELINE` di-render dengan `innerHTML` (baris 829–858).

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

Baris 434 menyembunyikan `.nav-actions #theme-toggle` pada `≤640px`.
Drawer (baris 480–493) hanya berisi logo dan link navigasi, tanpa tombol tema.
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

#### T4 — Kontras (selesai)

Token dan komponen sudah diperbarui:

| Pasangan | Rasio | Status |
|---|---:|---|
| `--muted` light `#61748d` di white / soft | 4,78:1 / 4,53:1 | Lolos AA |
| `--body` light `#5b7089` di white / soft | 5,09:1 / 4,82:1 | Lolos AA |
| `--muted` dark `#7e95ac` di bg / surface | 5,85:1 / 5,25:1 | Lolos AA |
| `--on-accent` dark `#081222` di `#8b7dff` | 5,59:1 | Lolos AA |
| `--on-accent` dark di hover `#a193ff` | 6,73:1 | Lolos AA |
| `--success-text` light `#0f7a37` di white | 5,44:1 | Lolos AA |
| `--error` light `#c81e5b` di white | 5,54:1 | Lolos AA |

Perubahan utama:

- `--body` light digelapkan, `--muted` light digelapkan dan dark diterangkan.
- `--on-accent` dipakai untuk `.btn-primary`, `.filter-btn.active`, dan `.skip`.
- `--success-text` dan `--error` ditambahkan per tema; JS memakai class `.is-error`.
- `tag-mini` dark memakai `--accent-hover` agar lolos kontras.
- Lighthouse Accessibility sekarang **100**.

#### T5 — Aset (selesai untuk initial load)

Strategi baru:

- Hero: crop 605×605 dari foto asli, WebP 320/520/640, `<picture>` + fallback PNG,
  preload `imagesrcset`, `fetchpriority=high`. File terpilih di Lighthouse 31 KiB
  (sebelumnya 692 KiB PNG).
- Logo: varian PNG 260/390/600 dengan `srcset`; Lighthouse memilih 260 (6 KiB).
- Project: 7 WebP (±243 KiB total) + fallback PNG, width/height, `loading=lazy`.
- Font: self-hosted WOFF2 (±50 KiB), tanpa request Google Fonts.
- Initial load Lighthouse: **141 KiB / 5 request** (sebelumnya 809 KiB / 7 request).

Repo masih menyimpan fallback PNG project (±3,88 MB) dan aset tidak terpakai
(4 SVG + `mobile_dev_new.png`, ±0,70 MB). Ini tidak masuk initial load, tetapi bisa
dihapus jika tidak diperlukan.

#### T6 — Tanggal karier

- Experience (baris 629): `Oct — Dec 2023`.
- Timeline (baris 764): `Oct 2022`.
- Data sumber SvelteKit juga memiliki ketidakcocokan ini.

Jangan menebak. Konfirmasi ke pemilik data, lalu samakan keduanya.
Jika mengubah salah satu, cek juga urutan kronologis timeline dan durasi experience.

#### T7 — Years of experience (selesai)

Section angka 8/20/15/999 sudah dihapus dan diganti current status strip
(role, based in, focus, availability) pada baris 532–550. Tidak ada lagi
`data-count` atau animasi count-up. `getYearsOfExperience()` di sumber SvelteKit
tidak lagi dipakai di halaman ini.

#### T8 — SEO dan social preview

Sudah ada: `<title>`, meta description, favicon lengkap (ICO/16/32/apple-touch),
manifest, `lang="en"`, heading hierarkis, teks alt pada gambar, dan URL sosial yang benar.

Belum ada:

- `og:title`, `og:description`, `og:image` (1200×630), `og:url`, `og:type`,
  `twitter:card`, `twitter:image`.
- `<link rel="canonical">`.
- JSON-LD `Person` (nama, role, URL, sameAs GitHub/LinkedIn).
- `meta name="theme-color"` (light/dark).
- `meta name="author"`.
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
- Escape semua data yang masuk `innerHTML` jika data kelak berasal dari luar.
- Set `color-scheme: light dark` dan sesuaikan per tema.
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

### P1 — kualitas dan konten

4. **Samakan tanggal karier** (T6) — konfirmasi lalu sinkronkan.
5. **SEO/social** (T8) — OG/Twitter, canonical, JSON-LD, theme-color.

### P2 — polish

6. A11y tambahan (T9), word-break (T10), validasi email (T11).
7. Escaping data (T13), README/CI (T17), `color-scheme` (T18), footer spacing (T19), ikon dekoratif (T20).
8. Pertimbangkan render statis project/timeline untuk SEO jangka panjang.
9. Hapus fallback PNG project setelah yakin browser target mendukung WebP; saat ini
   PNG tetap disimpan sebagai fallback.

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
- **Aset**: nama file deskriptif, huruf kecil, kompresi sebelum commit. Sediakan WebP
  (plus PNG fallback bila perlu) dan `srcset` untuk gambar yang tampil responsif.
- **Font**: self-hosted WOFF2 di `assets/fonts/`; jangan menambahkan Google Fonts.
- **Kontras**: gunakan `--on-accent`, `--error`, dan `--success-text`; jangan hardcode
  warna teks di komponen atau JS.
- **Git**: commit kecil dan jelas; jangan commit file sementara/`.DS_Store`.

---

## 11. Checklist verifikasi

### Struktural

- [ ] HTML parse tanpa tag tidak seimbang.
- [ ] Tidak ada ID duplikat.
- [ ] Semua `href="#..."` punya target.
- [ ] Semua `src`/`href` aset lokal ada (termasuk 7 gambar project).
- [ ] Tidak ada link eksternal rusak (GitHub, LinkedIn).
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
- [ ] Tanpa internet: font self-hosted tetap bekerja; fallback `system-ui` jika font gagal.
- [ ] Tidak ada error console saat offline.
- [ ] Hero/logo memakai varian WebP/PNG yang benar; project card memakai WebP + fallback.

### Performa / SEO

- [ ] Initial load tetap ±141 KiB (5 request) atau lebih kecil.
- [ ] Screenshot project tetap WebP + fallback PNG.
- [ ] Hero/logo memakai `srcset` dan ukuran tampilan sesuai.
- [ ] Lighthouse mobile: Performance/Accessibility/Best Practices/SEO ≥95.
- [ ] Ada OG image + title/description yang tampil benar saat share.
- [ ] Ada canonical/JSON-LD jika di-deploy.
- [ ] Tidak ada aset 404 di Network tab.

---

## 12. Catatan dan batasan audit

- Lighthouse 13.4.1 mobile sudah dijalankan dengan Chromium headless (Performance 99–100, kategori lain 100).
  Layout logo/nav juga dicek pada light/dark dan lebar 641–1440px. Screen reader manual,
  fokus drawer (T3), dan perilaku `mailto:` tetap perlu diverifikasi manual.
- Perhitungan kontras memakai nilai token CSS, bukan sampling piksel setelah render.
- Sumber konten SvelteKit berada di luar repo ini dan bisa berubah.
  Path `/mnt/d/Projects/porto_svelte` tersedia di mesin audit saat ini.
- `file://` dan `http://localhost` bisa berbeda untuk `download`, font, dan localStorage.
  Selalu uji keduanya jika mengubah tema, CV, atau form.
- Nomor baris mengacu pada working tree setelah optimasi performa; gunakan pencarian teks jika berubah.
- Jika ragu antara mempertahankan desain atau memperbaiki aksesibilitas,
  dahulukan aksesibilitas dan konten yang tetap terlihat tanpa JS.
