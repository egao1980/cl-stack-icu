# cl-stack-icu

ICU4C **native overlays** + thin **CFFI** for cl-stack unicode / i18n / l10n backends.

| Piece | Role |
|-------|------|
| Natives | `libicudata` + `libicuuc` + `libicui18n` (Windows: `icudt` / `icuuc` / `icuin`) |
| Grovel | `cffi-grovel` at overlay build — consumers load `grovel-cache/` (no CC) |
| Platforms | `linux/amd64`, `linux/arm64`, `darwin/arm64`, `windows/amd64` |

Package version tracks upstream ICU (`78.1` → tag `v78.1`).

## Consumers

Backends (`unicode-backend-icu`, `i18n-backend-icu`, `l10n-backend-icu`) should `:depends-on ("cl-stack-icu")`.

```lisp
(asdf:load-system "cl-stack-icu")
(cl-stack-icu:icu-version-string) ; => "78.1" — natives already loaded
```

No `load-icu` / `ensure-*` calls in consumer code — libs load at ASDF load time.

With [cl-repository](https://github.com/egao1980/cl-repository) overlays, natives + grovel cache install without a C toolchain. Local-dev: build ICU then grovel:

```bash
./scripts/build-icu.sh          # or build-icu.ps1 on Windows
./scripts/stage-grovel.sh cl-stack-icu
```

Env:

| Variable | Purpose |
|----------|---------|
| `CL_STACK_ICU_INCLUDE` | Header root for grovel (`…/include`) |
| `CL_STACK_ICU_NATIVE` | Extra dir for `cffi:*foreign-library-directories*` |
| `ICU_VERSION` | Upstream pin (default `78.1`) |

## License

MIT (Lisp). Bundled ICU4C: Unicode License V3 — see `NOTICE`.
