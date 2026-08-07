(in-package #:cl-stack-icu)

;;; MessageFormat 2 via native/mf2 C++ shim (not MF1/umsg).

(define-foreign-library libcl-stack-icu-mf2
  (:darwin (:or "libcl_stack_icu_mf2.dylib"
                "/opt/homebrew/lib/libcl_stack_icu_mf2.dylib"))
  (:unix (:or "libcl_stack_icu_mf2.so"))
  (:windows (:or "cl_stack_icu_mf2.dll"))
  (t (:default "libcl_stack_icu_mf2")))

(defun %mf2-lib-candidates ()
  #+windows '("cl_stack_icu_mf2.dll")
  #+darwin '("libcl_stack_icu_mf2.dylib")
  #+(and unix (not darwin)) '("libcl_stack_icu_mf2.so")
  #-(or windows darwin unix) '("libcl_stack_icu_mf2.so"))

(defun %find-mf2-lib (dir)
  (dolist (name (%mf2-lib-candidates))
    (let ((p (merge-pathnames name (uiop:ensure-directory-pathname dir))))
      (when (probe-file p)
        (return (namestring (truename p)))))))

(defun %load-mf2 ()
  (when (foreign-library-loaded-p 'libcl-stack-icu-mf2)
    (return-from %load-mf2 t))
  (let ((preloaded nil))
    (dolist (dir (%native-search-dirs))
      (when (and dir (uiop:directory-exists-p dir))
        (pushnew dir cffi:*foreign-library-directories* :test #'equal)
        (unless preloaded
          (let ((p (%find-mf2-lib dir)))
            (when p
              (load-foreign-library p)
              (setf preloaded t))))))
    (unless preloaded
      (load-foreign-library 'libcl-stack-icu-mf2)))
  t)

;;; Shim symbols are unversioned (our C ABI).

(defcfun ("cl_stack_icu_mf2_open" mf2-open) :pointer
  (locale-bcp47 :string)
  (pattern-utf8 :pointer)
  (pattern-len :int32)
  (err :pointer))

(defcfun ("cl_stack_icu_mf2_close" mf2-close) :void
  (fmt :pointer))

(defcfun ("cl_stack_icu_mf2_args_open" mf2-args-open) :pointer)

(defcfun ("cl_stack_icu_mf2_args_close" mf2-args-close) :void
  (args :pointer))

(defcfun ("cl_stack_icu_mf2_args_set_string" mf2-args-set-string) :void
  (args :pointer)
  (name :string)
  (utf8 :pointer)
  (len :int32)
  (err :pointer))

(defcfun ("cl_stack_icu_mf2_args_set_double" mf2-args-set-double) :void
  (args :pointer)
  (name :string)
  (value :double)
  (err :pointer))

(defcfun ("cl_stack_icu_mf2_args_set_int64" mf2-args-set-int64) :void
  (args :pointer)
  (name :string)
  (value :int64)
  (err :pointer))

(defcfun ("cl_stack_icu_mf2_format" mf2-format) :int32
  (fmt :pointer)
  (args :pointer)
  (dest :pointer)
  (dest-capacity :int32)
  (err :pointer))

(defun mf2-format-message (pattern args &key (locale "en") (max-bytes 4096))
  "Format MF2 PATTERN (UTF-8 string) with ARGS alist ((name . value)…).
VALUE is string, double-float, or integer. Returns UTF-8 Lisp string."
  (%load-mf2)
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (with-foreign-string (pat pattern)
      (let ((fmt (mf2-open locale pat (length pattern) err)))
        (check-icu (mem-ref err :int) "mf2-open")
        (unwind-protect
             (let ((a (mf2-args-open)))
               (unless a (error 'icu-error :code -1 :message "mf2-args-open failed"))
               (unwind-protect
                    (progn
                      (dolist (pair args)
                        (destructuring-bind (name . value) pair
                          (setf (mem-ref err :int)
                                (foreign-enum-value 'u-error-code :zero-error))
                          (let ((n (if (stringp name) name (string-downcase (string name)))))
                            (etypecase value
                              (string
                               (with-foreign-string (v value)
                                 (mf2-args-set-string a n v (length value) err)))
                              (float
                               (mf2-args-set-double a n (float value 1d0) err))
                              (integer
                               (mf2-args-set-int64 a n value err))))
                          (check-icu (mem-ref err :int) "mf2-args-set")))
                      (setf (mem-ref err :int)
                            (foreign-enum-value 'u-error-code :zero-error))
                      (with-foreign-pointer (buf max-bytes)
                        (let ((n (mf2-format fmt a buf max-bytes err)))
                          (when (= (mem-ref err :int)
                                   (foreign-enum-value 'u-error-code :buffer-overflow-error))
                            (let ((need (+ n 1)))
                              (with-foreign-pointer (buf2 need)
                                (setf (mem-ref err :int)
                                      (foreign-enum-value 'u-error-code :zero-error))
                                (setf n (mf2-format fmt a buf2 need err))
                                (check-icu (mem-ref err :int) "mf2-format")
                                (return-from mf2-format-message
                                  (foreign-string-to-lisp buf2 :count n)))))
                          (check-icu (mem-ref err :int) "mf2-format")
                          (foreign-string-to-lisp buf :count n))))
                 (mf2-args-close a)))
          (mf2-close fmt))))))

;;; Auto-load on ASDF load — consumers must not call LOAD-ICU (policy: no extra load-*).
(eval-when (:load-toplevel :execute)
  (load-icu))
