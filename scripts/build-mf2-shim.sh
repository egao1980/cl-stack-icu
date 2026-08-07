#!/usr/bin/env bash
# Build libcl_stack_icu_mf2 into lib/<os>-<arch>/.
# Requires ICU already built (CL_STACK_ICU_INCLUDE + libs in DEST / prefix).
# Env: CL_STACK_ICU_INCLUDE, CL_STACK_ICU_PREFIX (optional install prefix), DEST_DIR
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAJOR="${ICU_MAJOR:-78}"

if [[ -z "${CL_STACK_ICU_INCLUDE:-}" && -f "$ROOT/build/cl-stack-icu-include" ]]; then
  export CL_STACK_ICU_INCLUDE="$(cat "$ROOT/build/cl-stack-icu-include")"
fi
: "${CL_STACK_ICU_INCLUDE:?set CL_STACK_ICU_INCLUDE to ICU include root}"

uname_s="$(uname -s)"
uname_m="$(uname -m)"
case "$uname_s" in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  *) echo "unsupported OS: $uname_s (Windows: build-mf2-shim.ps1)" >&2; exit 1 ;;
esac
case "$uname_m" in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "unsupported arch: $uname_m" >&2; exit 1 ;;
esac

OUT="${DEST_DIR:-$ROOT/lib/${os}-${arch}}"
PREFIX="${CL_STACK_ICU_PREFIX:-}"
if [[ -z "$PREFIX" ]]; then
  # Heuristic: include is $PREFIX/include
  PREFIX="$(cd "$(dirname "$CL_STACK_ICU_INCLUDE")" && pwd)"
fi
LIBDIR="$PREFIX/lib"
[[ -d "$PREFIX/lib64" && ! -d "$LIBDIR" ]] && LIBDIR="$PREFIX/lib64"
# Prefer sibling staged OUT for link (portable rpath).
STAGE_LIB="$OUT"

SRC="$ROOT/native/mf2/cl_stack_icu_mf2.cpp"
HDR="$ROOT/native/mf2/cl_stack_icu_mf2.h"
[[ -f "$SRC" && -f "$HDR" ]] || { echo "mf2 sources missing" >&2; exit 1; }

mkdir -p "$OUT" "$ROOT/build/mf2"
OBJ="$ROOT/build/mf2/cl_stack_icu_mf2.o"
CXX="${CXX:-c++}"
CXXFLAGS=(
  -std=c++17 -O2 -fPIC
  -fvisibility=hidden
  -DCL_STACK_ICU_MF2_BUILD=1
  -I"$CL_STACK_ICU_INCLUDE"
  -I"$ROOT/native/mf2"
)

echo "==> compile MF2 shim ($CXX)"
"$CXX" "${CXXFLAGS[@]}" -c "$SRC" -o "$OBJ"

if [[ "$os" == "darwin" ]]; then
  DEST_LIB="$OUT/libcl_stack_icu_mf2.dylib"
  echo "==> link $DEST_LIB"
  "$CXX" -shared -o "$DEST_LIB" "$OBJ" \
    -L"$STAGE_LIB" -L"$LIBDIR" \
    -Wl,-rpath,@loader_path \
    -licui18n -licuuc -licudata \
    -install_name "@loader_path/libcl_stack_icu_mf2.dylib"
  # Prefer staged sonames if present.
  if command -v install_name_tool >/dev/null; then
    for dep in libicui18n libicuuc libicudata; do
      # Only rewrite to @loader_path when the soname is staged beside the shim.
      if [[ -f "$OUT/${dep}.${MAJOR}.dylib" ]]; then
        install_name_tool -change \
          "$LIBDIR/${dep}.${MAJOR}.dylib" "@loader_path/${dep}.${MAJOR}.dylib" "$DEST_LIB" 2>/dev/null || true
        install_name_tool -change \
          "${dep}.${MAJOR}.dylib" "@loader_path/${dep}.${MAJOR}.dylib" "$DEST_LIB" 2>/dev/null || true
      fi
    done
    otool -L "$DEST_LIB" | awk '/^\t/ {print $1}' | while read -r d; do
      case "$d" in
        *libicu*.dylib)
          bn="$(basename "$d")"
          for base in libicudata libicuuc libicui18n; do
            case "$bn" in ${base}*) bn="${base}.${MAJOR}.dylib" ;; esac
          done
          [[ -f "$OUT/$bn" ]] && install_name_tool -change "$d" "@loader_path/$bn" "$DEST_LIB" 2>/dev/null || true
          ;;
      esac
    done
  fi
else
  DEST_LIB="$OUT/libcl_stack_icu_mf2.so"
  echo "==> link $DEST_LIB"
  "$CXX" -shared -o "$DEST_LIB" "$OBJ" \
    -L"$STAGE_LIB" -L"$LIBDIR" \
    -Wl,-rpath,'$ORIGIN' \
    -licui18n -licuuc -licudata
  if command -v patchelf >/dev/null; then
    patchelf --set-rpath '$ORIGIN' "$DEST_LIB"
  fi
fi

echo "OK: mf2 shim -> $DEST_LIB"
ls -la "$DEST_LIB"
