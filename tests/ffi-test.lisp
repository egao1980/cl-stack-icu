(in-package #:cl-stack-icu/tests)

(deftest auto-loaded-on-system-load
  (ok *icu-loaded*)
  (let ((v (icu-version-string)))
    (ok (stringp v))
    (ok (search "78." v) (format nil "expected ICU 78.x, got ~S" v))))

(deftest grovel-major-matches-soname
  (ok (= u-icu-version-major-num +icu-soname-major+)))

(deftest zero-error-is-success
  (ok (u-success-p (foreign-enum-value 'u-error-code :zero-error)))
  (ok (u-failure-p (foreign-enum-value 'u-error-code :illegal-argument-error))))

(deftest uchar-basics
  (ok (plusp (u-has-binary-property
              #x0041
              (foreign-enum-value 'u-property :alphabetic))))
  (ok (zerop (u-has-binary-property
              #x0030
              (foreign-enum-value 'u-property :alphabetic))))
  (ok (= (u-tolower #x0041) #x0061))
  (ok (= (u-toupper #x0061) #x0041))
  (ok (= (u-char-type #x0041)
         (foreign-enum-value 'u-char-category :uppercase-letter))))

(deftest nfc-instance
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (let ((nfc (unorm2-get-nfc-instance err)))
      (ok (u-success-p (mem-ref err :int)))
      (ok (not (null-pointer-p nfc))))))

(deftest locale-default
  (ok (stringp (uloc-get-default)))
  (ok (plusp (uloc-count-available))))

(deftest collation-utf8
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (let ((coll (ucol-open "en" err)))
      (ok (u-success-p (mem-ref err :int)))
      (ok (not (null-pointer-p coll)))
      (unwind-protect
           (with-foreign-strings ((a "a") (b "b"))
             (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
             (let ((r (ucol-strcoll-utf8 coll a -1 b -1 err)))
               (ok (u-success-p (mem-ref err :int)))
               (ok (= r (foreign-enum-value 'u-collation-result :less)))))
        (ucol-close coll)))))

(deftest number-format-decimal
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (let ((fmt (unum-open (foreign-enum-value 'u-number-format-style :decimal)
                          (null-pointer) 0 "en_US" (null-pointer) err)))
      (ok (u-success-p (mem-ref err :int)))
      (ok (not (null-pointer-p fmt)))
      (unwind-protect
           (with-foreign-pointer (buf 64)
             (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
             (let ((n (unum-format-double fmt 1234.5d0 buf 64 (null-pointer) err)))
               (ok (u-success-p (mem-ref err :int)))
               (ok (plusp n))
               (let ((s (foreign-string-to-lisp buf :count n :encoding :utf-16)))
                 (ok (search "1" s)))))
        (unum-close fmt)))))

(deftest date-format-short
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (let* ((style (foreign-enum-value 'u-date-format-style :short))
           (fmt (udat-open style style "en_US" (null-pointer) -1 (null-pointer) 0 err)))
      (ok (u-success-p (mem-ref err :int)))
      (ok (not (null-pointer-p fmt)))
      (unwind-protect
           (with-foreign-pointer (buf 64)
             (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
             ;; UDate epoch ms: 0 = 1970-01-01 UTC
             (let ((n (udat-format fmt 0d0 buf 64 (null-pointer) err)))
               (ok (u-success-p (mem-ref err :int)))
               (ok (plusp n))))
        (udat-close fmt)))))

(deftest plural-cardinal
  (with-foreign-object (err :int)
    (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
    (let ((pr (uplrules-open-for-type
               "en"
               (foreign-enum-value 'u-plural-type :cardinal)
               err)))
      (ok (u-success-p (mem-ref err :int)))
      (ok (not (null-pointer-p pr)))
      (unwind-protect
           (with-foreign-pointer (buf 32)
             (setf (mem-ref err :int) (foreign-enum-value 'u-error-code :zero-error))
             (let ((n (uplrules-select pr 1d0 buf 32 err)))
               (ok (u-success-p (mem-ref err :int)))
               (ok (plusp n))
               (ok (string= "one" (foreign-string-to-lisp buf :count n :encoding :utf-16)))))
        (uplrules-close pr)))))

(deftest mf2-hello
  (let ((out (mf2-format-message "Hello {$name}!" '(("name" . "Ada")) :locale "en")))
    (ok (search "Ada" out))
    (ok (search "Hello" out))))
