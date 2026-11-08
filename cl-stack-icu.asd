;;; Stub for reading this .asd before cffi-grovel is installed (#. = read-time).
#.(progn
    (unless (find-package "CFFI-GROVEL")
      (make-package "CFFI-GROVEL" :use '())
      (export (intern "GROVEL-FILE" "CFFI-GROVEL") "CFFI-GROVEL"))
    nil)

(defsystem "cl-stack-icu"
  :version "79.1.2"
  :description "ICU4C native overlays + CFFI (+ MF2 C++ shim) for cl-stack unicode/i18n/l10n"
  :author "egao1980"
  :license "MIT"
  :defsystem-depends-on ("cffi-grovel" (:version "asdf-native" "0.3.0"))
  :depends-on ("cffi")
  :serial t
  :pathname "src"
  ;; Prefer overlay grovel-cache/ (no CC). Local-dev falls back to grovel-file.
  :components
  #.(let* ((asd (or *load-truename* *load-pathname*))
           (root (when asd (uiop:pathname-directory-pathname asd)))
           (cache (when root (probe-file (merge-pathnames "grovel-cache/grovel.cffi.lisp" root)))))
      (if cache
          '((:file "package")
            (:file "grovel-cached" :pathname "../grovel-cache/grovel.cffi")
            ;; data → uc → i18n → MF2 shim, by absolute path from $CL_STACK_ICU_NATIVE,
            ;; native/ (overlay) or lib/<os>-<arch>/ (checkout), then keg-only Homebrew
            ;; icu4c; else the system ICU.
            (:native-library "icudata" :versions ("79") :names (:windows ("icudt79.dll" "icudt.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "icuuc" :versions ("79") :names (:windows ("icuuc79.dll" "icuuc.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "icui18n" :versions ("79") :names (:windows ("icuin79.dll" "icuin.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "cl_stack_icu_mf2" :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/lib/"))
            (:file "ffi")
            (:file "ffi-i18n")
            (:file "ffi-extra")
            (:file "ffi-mf2"))
          '((:file "package")
            (cffi-grovel:grovel-file "grovel")
            ;; data → uc → i18n → MF2 shim, by absolute path from $CL_STACK_ICU_NATIVE,
            ;; native/ (overlay) or lib/<os>-<arch>/ (checkout), then keg-only Homebrew
            ;; icu4c; else the system ICU.
            (:native-library "icudata" :versions ("79") :names (:windows ("icudt79.dll" "icudt.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "icuuc" :versions ("79") :names (:windows ("icuuc79.dll" "icuuc.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "icui18n" :versions ("79") :names (:windows ("icuin79.dll" "icuin.dll"))
             :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/opt/icu4c/lib/" "/usr/local/opt/icu4c/lib/"))
            (:native-library "cl_stack_icu_mf2" :env "CL_STACK_ICU_NATIVE" :system t
             :fallback-directories ("/opt/homebrew/lib/"))
            (:file "ffi")
            (:file "ffi-i18n")
            (:file "ffi-extra")
            (:file "ffi-mf2"))))
  :in-order-to ((test-op (test-op "cl-stack-icu/tests")))
  ;; Native-library overlays: lib/<os>-<arch>/ per platform, derived from the
  ;; :native-library components. The grovel output folds into the same platform.
  :properties
  (:cl-repo
   (:provides ("cl-stack-icu")
    :overlays
    ((:platform (:os "linux" :arch "amd64")
      :layers ((:role "cffi-grovel-output"
                :files (("grovel/linux-amd64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "linux" :arch "arm64")
      :layers ((:role "cffi-grovel-output"
                :files (("grovel/linux-arm64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "darwin" :arch "arm64")
      :layers ((:role "cffi-grovel-output"
                :files (("grovel/darwin-arm64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "windows" :arch "amd64")
      :layers ((:role "cffi-grovel-output"
                :files (("grovel/windows-amd64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))))))

(defsystem "cl-stack-icu/tests"
  :depends-on ("cl-stack-icu" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "ffi-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
