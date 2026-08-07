#!/usr/bin/env bash
# Build shared ICU4C (data + uc + i18n) into lib/<os>-<arch>/.
# Env: ICU_VERSION (default 78.1), DEST_DIR, CL_STACK_ICU_INCLUDE (set for grovel)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICU_VERSION="${ICU_VERSION:-78.1}"
JOBS="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
MAJOR="${ICU_VERSION%%.*}"

uname_s="$(uname -s)"
uname_m="$(uname -m)"
case "$uname_s" in
  Linux) os=linux; plat=Linux ;;
  Darwin) os=darwin; plat=macOS ;;
  *) echo "unsupported OS: $uname_s (Windows: use build-icu.ps1)" >&2; exit 1 ;;
esac
case "$uname_m" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported arch: $uname_m" >&2; exit 1 ;;
esac

OUT="${DEST_DIR:-$ROOT/lib/${os}-${arch}}"
BUILD="$ROOT/build/icu-${ICU_VERSION}-${os}-${arch}"
SRC_TGZ="$ROOT/build/icu4c-${ICU_VERSION}-sources.tgz"
SRC_URL="https://github.com/unicode-org/icu/releases/download/release-${ICU_VERSION}/icu4c-${ICU_VERSION}-sources.tgz"

mkdir -p "$ROOT/build" "$OUT"
if [[ ! -f "$SRC_TGZ" ]]; then
  echo "==> download $SRC_URL"
  curl -fsSL "$SRC_URL" -o "$SRC_TGZ"
fi

rm -rf "$BUILD"
mkdir -p "$BUILD"
tar -xzf "$SRC_TGZ" -C "$BUILD" --strip-components=1
# tarball top-level is "icu/"; sources live under icu/source/
SRC="$BUILD/source"
if [[ ! -d "$SRC" ]]; then
  SRC="$BUILD/icu/source"
fi
if [[ ! -x "$SRC/runConfigureICU" ]]; then
  echo "runConfigureICU not found under $BUILD" >&2
  ls -la "$BUILD" "$BUILD/icu" 2>/dev/null || true
  exit 1
fi

PREFIX="$BUILD/prefix"
mkdir -p "$BUILD/build" "$PREFIX"
echo "==> configure/build ICU ${ICU_VERSION} ($plat) -> $OUT"
(
  cd "$BUILD/build"
  # Portable overlays: rpath relative to the shared object.
  if [[ "$os" == "darwin" ]]; then
    export LDFLAGS="${LDFLAGS:-} -Wl,-rpath,@loader_path"
  else
    export LDFLAGS="${LDFLAGS:-} -Wl,-rpath,\$ORIGIN"
  fi
  "$SRC/runConfigureICU" "$plat" \
    --prefix="$PREFIX" \
    --disable-samples \
    --disable-tests \
    --enable-shared \
    --disable-static \
    --enable-rpath
  make -j"$JOBS"
  make install
)

INCLUDE="$PREFIX/include"
if [[ ! -f "$INCLUDE/unicode/utypes.h" ]]; then
  echo "ICU headers missing under $INCLUDE" >&2
  exit 1
fi
export CL_STACK_ICU_INCLUDE="$INCLUDE"
printf '%s\n' "$CL_STACK_ICU_INCLUDE" >"$ROOT/build/cl-stack-icu-include"
echo "CL_STACK_ICU_INCLUDE=$CL_STACK_ICU_INCLUDE"

rm -rf "$OUT"
mkdir -p "$OUT"
LIBDIR="$PREFIX/lib"
[[ -d "$PREFIX/lib64" ]] && LIBDIR="$PREFIX/lib64"
# Prefer lib/ when both exist (common ICU layout).
[[ -d "$PREFIX/lib" ]] && LIBDIR="$PREFIX/lib"

stage_real() {
  # Copy the real file behind SRC to DESTNAME (no dangling soname symlinks in overlays).
  local src="$1" destname="$2"
  local real
  real="$(readlink -f "$src" 2>/dev/null || true)"
  if [[ -z "$real" || ! -f "$real" ]]; then
    real="$src"
  fi
  if [[ ! -f "$real" ]]; then
    echo "missing library: $src" >&2
    return 1
  fi
  cp -f "$real" "$OUT/$destname"
}

if [[ "$os" == "linux" ]]; then
  for base in libicudata libicuuc libicui18n; do
    cand=""
    for c in "$LIBDIR/${base}.so.${MAJOR}" "$LIBDIR/${base}.so."*; do
      [[ -e "$c" ]] || continue
      cand="$c"
      break
    done
    if [[ -z "$cand" ]]; then
      echo "ICU library not found: ${base} under $LIBDIR" >&2
      ls -la "$LIBDIR" || true
      exit 1
    fi
    stage_real "$cand" "${base}.so.${MAJOR}"
    # Unversioned name for CFFI (:or … "libicuuc.so") — hard copy, not symlink.
    cp -f "$OUT/${base}.so.${MAJOR}" "$OUT/${base}.so"
  done
  if command -v patchelf >/dev/null; then
    for f in "$OUT"/libicu*.so*; do
      [[ -f "$f" ]] || continue
      patchelf --set-rpath '$ORIGIN' "$f"
    done
  fi
elif [[ "$os" == "darwin" ]]; then
  for base in libicudata libicuuc libicui18n; do
    cand=""
    for c in "$LIBDIR/${base}.${MAJOR}.dylib" "$LIBDIR/${base}."*.dylib; do
      [[ -e "$c" ]] || continue
      cand="$c"
      break
    done
    if [[ -z "$cand" ]]; then
      echo "ICU library not found: ${base} under $LIBDIR" >&2
      ls -la "$LIBDIR" || true
      exit 1
    fi
    stage_real "$cand" "${base}.${MAJOR}.dylib"
    cp -f "$OUT/${base}.${MAJOR}.dylib" "$OUT/${base}.dylib"
  done
  if command -v install_name_tool >/dev/null && command -v otool >/dev/null; then
    for f in "$OUT"/libicu*.dylib; do
      [[ -f "$f" ]] || continue
      install_name_tool -id "@loader_path/$(basename "$f")" "$f" 2>/dev/null || true
      otool -L "$f" | awk '/^\t/ {print $1}' | while read -r dep; do
        case "$dep" in
          *libicudata*.dylib|*libicuuc*.dylib|*libicui18n*.dylib)
            bn="$(basename "$dep")"
            for base in libicudata libicuuc libicui18n; do
              case "$bn" in
                ${base}*) bn="${base}.${MAJOR}.dylib" ;;
              esac
            done
            if [[ -f "$OUT/$bn" ]]; then
              install_name_tool -change "$dep" "@loader_path/$bn" "$f" 2>/dev/null || true
            fi
            ;;
        esac
      done
    done
  fi
fi

echo "==> staged:"
ls -la "$OUT"
echo "OK: icu ${ICU_VERSION} -> ${os}/${arch}"

# MF2 C++ shim (links against staged ICU libs).
export CL_STACK_ICU_PREFIX="$PREFIX"
export CL_STACK_ICU_INCLUDE
export DEST_DIR="$OUT"
export ICU_MAJOR="$MAJOR"
chmod +x "$ROOT/scripts/build-mf2-shim.sh"
"$ROOT/scripts/build-mf2-shim.sh"
