;;; Stub for reading this .asd before cffi-grovel is installed (#. = read-time).
#.(progn
    (unless (find-package "CFFI-GROVEL")
      (make-package "CFFI-GROVEL" :use '())
      (export (intern "GROVEL-FILE" "CFFI-GROVEL") "CFFI-GROVEL"))
    nil)

(defsystem "cl-stack-icu"
  :version "78.1"
  :description "ICU4C native overlays + CFFI for cl-stack unicode/i18n/l10n"
  :author "egao1980"
  :license "MIT"
  :defsystem-depends-on ("cffi-grovel")
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
            (:file "ffi"))
          '((:file "package")
            (cffi-grovel:grovel-file "grovel")
            (:file "ffi"))))
  :in-order-to ((test-op (test-op "cl-stack-icu/tests")))
  :properties
  (:cl-repo
   (:cffi-libraries ("libicudata" "libicuuc" "libicui18n")
    :provides ("cl-stack-icu")
    :overlays
    ((:platform (:os "linux" :arch "amd64")
      :layers ((:role "native-library"
                :files (("lib/linux-amd64/libicudata.so.78" . "libicudata.so.78")
                        ("lib/linux-amd64/libicudata.so" . "libicudata.so")
                        ("lib/linux-amd64/libicuuc.so.78" . "libicuuc.so.78")
                        ("lib/linux-amd64/libicuuc.so" . "libicuuc.so")
                        ("lib/linux-amd64/libicui18n.so.78" . "libicui18n.so.78")
                        ("lib/linux-amd64/libicui18n.so" . "libicui18n.so")))
               (:role "cffi-grovel-output"
                :files (("grovel/linux-amd64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "linux" :arch "arm64")
      :layers ((:role "native-library"
                :files (("lib/linux-arm64/libicudata.so.78" . "libicudata.so.78")
                        ("lib/linux-arm64/libicudata.so" . "libicudata.so")
                        ("lib/linux-arm64/libicuuc.so.78" . "libicuuc.so.78")
                        ("lib/linux-arm64/libicuuc.so" . "libicuuc.so")
                        ("lib/linux-arm64/libicui18n.so.78" . "libicui18n.so.78")
                        ("lib/linux-arm64/libicui18n.so" . "libicui18n.so")))
               (:role "cffi-grovel-output"
                :files (("grovel/linux-arm64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "darwin" :arch "arm64")
      :layers ((:role "native-library"
                :files (("lib/darwin-arm64/libicudata.78.dylib" . "libicudata.78.dylib")
                        ("lib/darwin-arm64/libicudata.dylib" . "libicudata.dylib")
                        ("lib/darwin-arm64/libicuuc.78.dylib" . "libicuuc.78.dylib")
                        ("lib/darwin-arm64/libicuuc.dylib" . "libicuuc.dylib")
                        ("lib/darwin-arm64/libicui18n.78.dylib" . "libicui18n.78.dylib")
                        ("lib/darwin-arm64/libicui18n.dylib" . "libicui18n.dylib")))
               (:role "cffi-grovel-output"
                :files (("grovel/darwin-arm64/grovel.cffi.lisp" . "grovel.cffi.lisp")))))
     (:platform (:os "windows" :arch "amd64")
      :layers ((:role "native-library"
                :files (("lib/windows-amd64/icudt78.dll" . "icudt78.dll")
                        ("lib/windows-amd64/icuuc78.dll" . "icuuc78.dll")
                        ("lib/windows-amd64/icuin78.dll" . "icuin78.dll")))
               (:role "cffi-grovel-output"
                :files (("grovel/windows-amd64/grovel.cffi.lisp"
                         . "grovel.cffi.lisp")))))))))

(defsystem "cl-stack-icu/tests"
  :depends-on ("cl-stack-icu" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "ffi-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
