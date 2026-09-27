# Rencana Portofolio Web — porto_html

Versi: 1.0
Tanggal: 27 Sep 2026
Status: Perencanaan -> Implementasi

## Tujuan

Portofolio pribadi Luthfi Izhariman (Software Developer) sebagai file HTML
lokal yang bisa langsung dibuka di browser, tanpa build tool dan tanpa
backend.

## Sumber Konten

- Konten diambil dari project SvelteKit yang sudah ada:
  `/mnt/d/Projects/porto_svelte/`
  - Data asli: `src/lib/data/*.ts` (site, home, services, resume, projects, contact)
  - Konten yang ditulis manual di sana tetap dipakai apa adanya (nama, role,
    pengalaman, timeline, skill, proyek, kontak)
- Aset disalin ke folder `assets/`:
  - `assets/photo_no_bg.png` — foto profil hero
  - `assets/projects/*.png` — screenshot 7 proyek
  - `assets/*.svg` + `mobile_dev_new.png` — ilustrasi services (cadangan)
  - `assets/CVLuthfi.pdf` — CV lokal (link "Download CV" mengarah ke sini,
    bukan Google Drive, supaya tetap jalan offline)

## Keputusan Desain

- Arah visual: **Light Elegant**, mengadopsi prinsip design system Stripe
  (via skill popular-web-designs):
  - Latar putih bersih, judul deep navy `#061b31` (bukan hitam murni)
  - Aksen ungu Stripe `#533afd` untuk CTA & link
  - Tipografi ringan (weight 300) dengan letter-spacing negatif di judul besar
  - Shadow biru-berlapis khas Stripe: `rgba(50,50,93,0.25)` + `rgba(0,0,0,0.1)`
  - Border-radius konservatif 4–8px (tanpa pill)
  - Font: Source Sans 3 (Google Fonts) + Source Code Pro untuk label teknis
- Theme: **Light + Dark mode**, toggle manual (ikon matahari/bulan),
  tersimpan di localStorage, default mengikuti prefers-color-scheme
- **Responsive mobile**: nav jadi hamburger/drawer, grid menumpuk,
  tipografi mengecil

## Struktur Halaman (single page, anchor nav)

1. Navbar — brand "Izhrmn", menu (About, Services, Resume, Projects, Contact), toggle theme
2. Hero — nama, role berganti (Software/Web/Mobile/Full Stack Developer),
   deskripsi, tombol Download CV + tombol kontak, link GitHub/LinkedIn,
   baris statistik (8+ tahun, 20 proyek, 15 stack, 999+ commit)
3. About — foto + info (nama, telepon, email, nationality, freelance, bahasa)
4. Services — daftar bernomor 01–05 (Web, Mobile, REST API, Deploy & Maintenance, UI/UX)
5. Resume —
   - Experience (5 entri kerja)
   - Education (Telkom University)
   - Skills (15 chip teknologi)
   - Timeline karier (15 entri, dibuat expandable agar halaman tetap ringkas)
6. Projects — 7 kartu proyek + filter tag (All / Web / Mobile), stack per proyek
7. Contact — kartu info (phone, email, address) + form yang mengirim lewat
   `mailto:` (tanpa backend)
8. Footer — copyright, sosmed, back-to-top

## Teknis

- Satu file `index.html` self-contained: CSS & JS embed, tanpa dependency build
- Font: Google Fonts (Source Sans 3, Source Code Pro) — butuh internet sekali;
  fallback system-ui jika offline
- Interaksi ringan vanilla JS: theme toggle, rotating roles, filter proyek,
  drawer mobile, reveal-on-scroll (respect prefers-reduced-motion)
- Tidak ada data palsu: semua angka/teks dari data SvelteKit asli
- Verifikasi: parse HTML + buka di browser lokal

## Perubahan Konten (catatan)

- "CSS 5" di data skill asli ditampilkan sebagai "CSS" (kemungkinan typo)
- "Languanges" di data asli ditampilkan sebagai "Languages"
- CV link diarahkan ke `assets/CVLuthfi.pdf` (lokal) alih-alih Google Drive
- Deskripsi "About me" kosong di data asli -> diganti ringkasan dari `home.description`

## Status Pengerjaan

- [x] Setup folder + salin aset
- [x] Rencana ini
- [x] index.html (hero, about, services)
- [x] index.html (resume + timeline)
- [x] index.html (projects + filter)
- [x] index.html (contact + footer)
- [x] Dark/light mode + responsive
- [x] Verifikasi