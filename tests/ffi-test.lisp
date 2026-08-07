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
