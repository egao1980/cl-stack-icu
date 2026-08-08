(in-package #:cl-stack-icu)

;;; ICU ships versioned C entry points by default (u_strlen_78). Bind via major.

(defmacro defcfun-icu ((c-name lisp-name) return-type &body args)
  `(defcfun (,(format nil "~A_~D" c-name +icu-soname-major+) ,lisp-name)
       ,return-type ,@args))

(define-condition icu-error (error)
  ((code :initarg :code :reader icu-error-code)
   (message :initarg :message :reader icu-error-message))
  (:report (lambda (c s)
             (format s "ICU error ~A (~A)"
                     (icu-error-code c)
                     (icu-error-message c)))))

(defun u-success-p (code)
  "U_SUCCESS — code <= U_ZERO_ERROR (warnings are success)."
  (<= code (foreign-enum-value 'u-error-code :zero-error)))

(defun u-failure-p (code)
  (not (u-success-p code)))

(defun check-icu (code &optional (op "icu"))
  (unless (u-success-p code)
    (error 'icu-error
           :code code
           :message (format nil "~A: ~A" op (u-error-name code))))
  code)

;;; --- libraries ----------------------------------------------------------------

(define-foreign-library libicudata
  (:darwin (:or #.(format nil "libicudata.~D.dylib" +icu-soname-major+)
                "libicudata.dylib"
                "/opt/homebrew/opt/icu4c/lib/libicudata.dylib"
                "/usr/local/opt/icu4c/lib/libicudata.dylib"))
  (:unix (:or #.(format nil "libicudata.so.~D" +icu-soname-major+)
              "libicudata.so"))
  (:windows (:or #.(format nil "icudt~D.dll" +icu-soname-major+)
                 "icudt.dll"))
  (t (:default "libicudata")))

(define-foreign-library libicuuc
  (:darwin (:or #.(format nil "libicuuc.~D.dylib" +icu-soname-major+)
                "libicuuc.dylib"
                "/opt/homebrew/opt/icu4c/lib/libicuuc.dylib"
                "/usr/local/opt/icu4c/lib/libicuuc.dylib"))
  (:unix (:or #.(format nil "libicuuc.so.~D" +icu-soname-major+)
              "libicuuc.so"))
  (:windows (:or #.(format nil "icuuc~D.dll" +icu-soname-major+)
                 "icuuc.dll"))
  (t (:default "libicuuc")))

(define-foreign-library libicui18n
  (:darwin (:or #.(format nil "libicui18n.~D.dylib" +icu-soname-major+)
                "libicui18n.dylib"
                "/opt/homebrew/opt/icu4c/lib/libicui18n.dylib"
                "/usr/local/opt/icu4c/lib/libicui18n.dylib"))
  (:unix (:or #.(format nil "libicui18n.so.~D" +icu-soname-major+)
              "libicui18n.so"))
  (:windows (:or #.(format nil "icuin~D.dll" +icu-soname-major+)
                 "icuin.dll"))
  (t (:default "libicui18n")))

(defvar *icu-loaded* nil)

;;; %LOAD-MF2 is defined in ffi-mf2.lisp (serial later). Do not put an erroring
;;; stub here: ECL can compile LOAD-ICU's direct call into a fixed reference to
;;; that stub, so a later DEFUN in ffi-mf2 never takes effect.

(defun %host-os ()
  #+windows "windows"
  #+darwin "darwin"
  #+linux "linux"
  #-(or windows darwin linux) "unknown")

(defun %host-arch ()
  #+(or x86-64 x64) "amd64"
  #+(or arm64 aarch64) "arm64"
  #-(or x86-64 x64 arm64 aarch64) "unknown")

(defun %native-search-dirs ()
  "Overlay native/ (OCI) and lib/<os>-<arch>/ (local build). No LD_LIBRARY_PATH."
  (let ((dirs '()))
    (dolist (var '("CL_STACK_ICU_NATIVE" "CL_STACK_ICU_LIB"))
      (let ((v (uiop:getenv var)))
        (when (and v (plusp (length v)))
          (push v dirs))))
    (ignore-errors
      (let* ((sys (asdf:find-system :cl-stack-icu nil))
             (root (when sys (asdf:system-source-directory sys))))
        (when root
          (push (namestring (merge-pathnames "native/" root)) dirs)
          (push (namestring
                 (merge-pathnames
                  (format nil "lib/~A-~A/" (%host-os) (%host-arch))
                  root))
                dirs))))
    (nreverse dirs)))

(defun %lib-candidates (which)
  "Filenames to probe under a native dir for WHICH ∈ (:data :uc :i18n)."
  (ecase which
    (:data
     #+windows (list (format nil "icudt~D.dll" +icu-soname-major+) "icudt.dll")
     #+darwin (list (format nil "libicudata.~D.dylib" +icu-soname-major+) "libicudata.dylib")
     #+(and unix (not darwin)) (list (format nil "libicudata.so.~D" +icu-soname-major+) "libicudata.so")
     #-(or windows darwin unix) (list "libicudata.so"))
    (:uc
     #+windows (list (format nil "icuuc~D.dll" +icu-soname-major+) "icuuc.dll")
     #+darwin (list (format nil "libicuuc.~D.dylib" +icu-soname-major+) "libicuuc.dylib")
     #+(and unix (not darwin)) (list (format nil "libicuuc.so.~D" +icu-soname-major+) "libicuuc.so")
     #-(or windows darwin unix) (list "libicuuc.so"))
    (:i18n
     #+windows (list (format nil "icuin~D.dll" +icu-soname-major+) "icuin.dll")
     #+darwin (list (format nil "libicui18n.~D.dylib" +icu-soname-major+) "libicui18n.dylib")
     #+(and unix (not darwin)) (list (format nil "libicui18n.so.~D" +icu-soname-major+) "libicui18n.so")
     #-(or windows darwin unix) (list "libicui18n.so"))))

(defun %find-lib (dir which)
  (dolist (name (%lib-candidates which))
    (let ((p (merge-pathnames name (uiop:ensure-directory-pathname dir))))
      (when (probe-file p)
        (return (namestring (truename p)))))))

(defun %absolute-preload (dir)
  "Load data→uc→i18n by absolute path (cl-repository post-install policy)."
  (let ((data (%find-lib dir :data))
        (uc (%find-lib dir :uc))
        (i18n (%find-lib dir :i18n)))
    (when (and data uc i18n)
      (load-foreign-library data)
      (load-foreign-library uc)
      (load-foreign-library i18n)
      t)))

(defun load-icu ()
  "Load ICU shared libs (data → uc → i18n → mf2 shim). Idempotent; also run at ASDF load."
  (unless *icu-loaded*
    (let ((preloaded nil))
      (dolist (dir (%native-search-dirs))
        (when (and dir (uiop:directory-exists-p dir))
          (pushnew dir cffi:*foreign-library-directories* :test #'equal)
          (unless preloaded
            (setf preloaded (%absolute-preload dir)))))
      (unless preloaded
        (load-foreign-library 'libicudata)
        (load-foreign-library 'libicuuc)
        (load-foreign-library 'libicui18n)))
    (setf *icu-loaded* t))
  ;; Late-bind MF2: never (%load-mf2) — ECL may inline the pre-mf2 binding.
  (let ((sym (find-symbol "%LOAD-MF2" #.*package*)))
    (when (and sym (fboundp sym))
      (funcall (symbol-function sym))))
  t)

;;; --- version / errors ---------------------------------------------------------

(defcfun-icu ("u_getVersion" u-get-version) :void
  (version-array :pointer))

(defcfun-icu ("u_versionToString" u-version-to-string) :void
  (version-array :pointer)
  (version-string :pointer))

(defcfun-icu ("u_errorName" u-error-name) :string
  (code :int))

(defun icu-version-string ()
  "Return ICU version string (e.g. \"78.1\")."
  (with-foreign-objects ((ver :uint8 u-max-version-length)
                         (buf :char u-max-version-string-length))
    (u-get-version ver)
    (u-version-to-string ver buf)
    (foreign-string-to-lisp buf)))

;;; --- strings ------------------------------------------------------------------

(defcfun-icu ("u_strlen" u-strlen) :int32
  (s :pointer))

(defcfun-icu ("u_strToUTF8" u-str-to-utf8) :int32
  (dest :pointer)
  (dest-capacity :int32)
  (p-dest-length :pointer)
  (src :pointer)
  (src-length :int32)
  (p-error-code :pointer))

(defcfun-icu ("u_strFromUTF8" u-str-from-utf8) :pointer
  (dest :pointer)
  (dest-capacity :int32)
  (p-dest-length :pointer)
  (src :pointer)
  (src-length :int32)
  (p-error-code :pointer))

(defun u-chars-to-lisp (pointer uchar-count)
  "Convert ICU UChar* of UCHAR-COUNT code units to a Lisp string.
ICU lengths are in UChars; CFFI :utf-16 :count is octets — do not pass
UCHAR-COUNT directly to FOREIGN-STRING-TO-LISP."
  (when (or (null pointer) (null-pointer-p pointer) (minusp uchar-count))
    (return-from u-chars-to-lisp ""))
  (when (zerop uchar-count)
    (return-from u-chars-to-lisp ""))
  (with-foreign-objects ((err :int)
                         (needed :int32))
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    ;; Probe UTF-8 length.
    (u-str-to-utf8 (null-pointer) 0 needed pointer uchar-count err)
    (let ((cap (max 1 (+ (mem-ref needed :int32) 1))))
      (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
      (with-foreign-pointer (utf8 cap)
        (u-str-to-utf8 utf8 cap needed pointer uchar-count err)
        (check-icu (mem-ref err :int) "u-str-to-utf8")
        (foreign-string-to-lisp utf8 :count (mem-ref needed :int32))))))

;;; --- uchar --------------------------------------------------------------------

(defcfun-icu ("u_hasBinaryProperty" u-has-binary-property) u-bool
  (c u-char32)
  (which :int))

(defcfun-icu ("u_getIntPropertyValue" u-get-int-property-value) :int32
  (c u-char32)
  (which :int))

(defcfun-icu ("u_charType" u-char-type) :int8
  (c u-char32))

(defcfun-icu ("u_tolower" u-tolower) u-char32
  (c u-char32))

(defcfun-icu ("u_toupper" u-toupper) u-char32
  (c u-char32))

(defcfun-icu ("u_foldCase" u-fold-case) u-char32
  (c u-char32)
  (options :uint32))

;;; Portable aliases for grovelled fold/IDNA option constants.
(defparameter +u-fold-case-default+ u-fold-case-default)
(defparameter +u-fold-case-exclude-special-i+ u-fold-case-exclude-special-i)
(defparameter +uidna-default+ (foreign-enum-value 'uidna-option :default))
(defparameter +uidna-use-std3-rules+ (foreign-enum-value 'uidna-option :use-std3-rules))
(defparameter +uidna-check-bidi+ (foreign-enum-value 'uidna-option :check-bidi))
(defparameter +uidna-check-contextj+ (foreign-enum-value 'uidna-option :check-contextj))
(defparameter +uidna-check-contexto+ (foreign-enum-value 'uidna-option :check-contexto))
(defparameter +uidna-nontransitional-to-ascii+
  (foreign-enum-value 'uidna-option :nontransitional-to-ascii))
(defparameter +uidna-nontransitional-to-unicode+
  (foreign-enum-value 'uidna-option :nontransitional-to-unicode))

;;; --- Normalizer2 --------------------------------------------------------------

(defcfun-icu ("unorm2_getNFCInstance" unorm2-get-nfc-instance) :pointer
  (p-error-code :pointer))

(defcfun-icu ("unorm2_getNFDInstance" unorm2-get-nfd-instance) :pointer
  (p-error-code :pointer))

(defcfun-icu ("unorm2_getNFKCInstance" unorm2-get-nfkc-instance) :pointer
  (p-error-code :pointer))

(defcfun-icu ("unorm2_getNFKDInstance" unorm2-get-nfkd-instance) :pointer
  (p-error-code :pointer))

(defcfun-icu ("unorm2_getNFKCCasefoldInstance" unorm2-get-nfkc-casefold-instance) :pointer
  (p-error-code :pointer))

(defcfun-icu ("unorm2_normalize" unorm2-normalize) :int32
  (norm2 :pointer)
  (src :pointer)
  (length :int32)
  (dest :pointer)
  (capacity :int32)
  (p-error-code :pointer))

;;; --- BreakIterator ------------------------------------------------------------

(defcfun-icu ("ubrk_open" ubrk-open) :pointer
  (type :int)
  (locale :string)
  (text :pointer)
  (text-length :int32)
  (status :pointer))

(defcfun-icu ("ubrk_close" ubrk-close) :void
  (bi :pointer))

(defcfun-icu ("ubrk_first" ubrk-first) :int32
  (bi :pointer))

(defcfun-icu ("ubrk_next" ubrk-next) :int32
  (bi :pointer))

(defcfun-icu ("ubrk_setText" ubrk-set-text) :void
  (bi :pointer)
  (text :pointer)
  (text-length :int32)
  (status :pointer))

;;; --- IDNA / UTS#46 ------------------------------------------------------------

(defcfun-icu ("uidna_openUTS46" uidna-open-uts46) :pointer
  (options :uint32)
  (p-error-code :pointer))

(defcfun-icu ("uidna_close" uidna-close) :void
  (idna :pointer))

(defcfun-icu ("uidna_nameToASCII" uidna-name-to-ascii) :int32
  (idna :pointer)
  (name :pointer)
  (length :int32)
  (dest :pointer)
  (capacity :int32)
  (p-info :pointer)
  (p-error-code :pointer))

(defcfun-icu ("uidna_nameToUnicode" uidna-name-to-unicode) :int32
  (idna :pointer)
  (name :pointer)
  (length :int32)
  (dest :pointer)
  (capacity :int32)
  (p-info :pointer)
  (p-error-code :pointer))

;;; Auto-load on ASDF load — consumers must not call LOAD-ICU (policy: no extra load-*).
;;; Note: LOAD-ICU is defined above; %LOAD-MF2 lives in ffi-mf2.lisp which loads after.
;;; The actual auto-load call is at the end of ffi-mf2.lisp.