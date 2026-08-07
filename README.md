# cl-stack-icu

ICU4C **native overlays** + **CFFI** (+ **MF2 C++ shim**) for cl-stack unicode / i18n / l10n backends.

| Piece | Role |
|-------|------|
| Natives | `libicudata` + `libicuuc` + `libicui18n` + `libcl_stack_icu_mf2` |
| Grovel | `cffi-grovel` at overlay build — consumers load `grovel-cache/` (no CC) |
| Bindings | unicode + locale/ures + collation + number/date + plurals + lists + locale case |
| MF2 | C ABI shim over ICU `message2::MessageFormatter` (not MF1/`umsg`) |
| Not shipped | `libicuio` |
| Platforms | `linux/amd64`, `linux/arm64`, `darwin/arm64`, `windows/amd64` |

Package version tracks upstream ICU (`78.1` → tag `v78.1`).

## Consumers

```lisp
(asdf:load-system "cl-stack-icu")
(cl-stack-icu:icu-version-string) ; => "78.1" — natives already loaded
(cl-stack-icu:mf2-format-message "Hello {$name}!" '(("name" . "Ada")))
```

No `load-icu` / `ensure-*` — libs load at ASDF load time.

With [cl-repository](https://github.com/egao1980/cl-repository) overlays, natives + grovel cache install without a C toolchain. Local-dev:

```bash
./scripts/build-icu.sh          # ICU + MF2 shim (or build-icu.ps1 on Windows)
./scripts/stage-grovel.sh cl-stack-icu
```

Env:

| Variable | Purpose |
|----------|---------|
| `CL_STACK_ICU_INCLUDE` | Header root for grovel / shim (`…/include`) |
| `CL_STACK_ICU_NATIVE` | Extra dir for `cffi:*foreign-library-directories*` |
| `ICU_VERSION` | Upstream pin (default `78.1`) |

## License

MIT (Lisp + shim). Bundled ICU4C: Unicode License V3 — see `NOTICE`.
