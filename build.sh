#!/usr/bin/env bash
# Build artefak deploy untuk Cloudflare Pages.
# Tujuan: hanya index.html + aset yang benar-benar dipakai yang ikut ter-publish,
# sehingga AGENTS.md / PLAN.md / .gitignore tidak bisa diakses publik.
#
# Pemakaian lokal:  ./build.sh && python3 -m http.server -d dist 8000
# Di Cloudflare Pages: build command "bash build.sh", output directory "dist"

set -euo pipefail
cd "$(dirname "$0")"

rm -rf dist
mkdir -p dist

cp index.html dist/
cp -r assets dist/

# Aset yang tidak direferensikan index.html (lihat AGENTS.md bagian 3).
UNUSED=(
  assets/api_services.svg
  assets/deploy_services.svg
  assets/web_services.svg
  assets/undraw_web-developer_gxaa.svg
  assets/mobile_dev_new.png
)
for f in "${UNUSED[@]}"; do
  rm -f "dist/$f"
done

# Header cache opsional, kalau nanti ditambahkan di root.
if [ -f _headers ]; then cp _headers dist/; fi
if [ -f _redirects ]; then cp _redirects dist/; fi

echo "dist/ siap: $(find dist -type f | wc -l) file, $(du -sh dist | cut -f1)"
