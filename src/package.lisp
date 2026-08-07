(defpackage #:cl-stack-icu
  (:use #:cl #:cffi)
  (:export #:icu-version-string
           #:icu-error
           #:icu-error-code
           #:icu-error-message
           #:check-icu
           #:u-success-p
           #:u-failure-p
           ;; grovelled / wrapped entry points used by backends
           #:u-get-version
           #:u-version-to-string
           #:u-error-name
           #:u-strlen
           #:u-str-to-utf8
           #:u-str-from-utf8
           #:u-has-binary-property
           #:u-get-int-property-value
           #:u-char-type
           #:u-tolower
           #:u-toupper
           #:u-fold-case
           #:unorm2-get-nfc-instance
           #:unorm2-get-nfd-instance
           #:unorm2-get-nfkc-instance
           #:unorm2-get-nfkd-instance
           #:unorm2-get-nfkc-casefold-instance
           #:unorm2-normalize
           #:ubrk-open
           #:ubrk-close
           #:ubrk-first
           #:ubrk-next
           #:ubrk-set-text
           #:uidna-open-uts46
           #:uidna-close
           #:uidna-name-to-ascii
           #:uidna-name-to-unicode
           #:+icu-soname-major+
           #:+u-fold-case-default+
           #:+u-fold-case-exclude-special-i+
           #:+uidna-default+
           #:+uidna-use-std3-rules+
           #:+uidna-check-bidi+
           #:+uidna-check-contextj+
           #:+uidna-check-contexto+
           #:+uidna-nontransitional-to-ascii+
           #:+uidna-nontransitional-to-unicode+
           ;; internal (tests); libs load automatically on ASDF load
           #:*icu-loaded*))
(in-package #:cl-stack-icu)

;;; Must match ICU major in package :version / sonames (icudt78.dll, libicuuc.so.78, …).
(defconstant +icu-soname-major+ 78)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (when (uiop:getenv "HOMEBREW_PREFIX")
    (pushnew :homebrew *features*))
  (when (uiop:getenv "CL_STACK_ICU_INCLUDE")
    (pushnew :cl-stack-icu-include *features*)))
