;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; on-enc-autoload.el
;;;;


(defconst +encode-output-buffer-name+
  "*encode-output*"
  "Encode output buffer name")

(defconst +decode-output-buffer-name+
  "*decode-output*"
  "Decode output buffer name")


(eval-when-compile

  (defmacro _enc_with_output_buffer_ (buffer &rest body)
    (declare (indent 0))
    `(with-current-buffer (switch-to-buffer-other-window ,buffer)
       (delete-region (point-min) (point-max))
       ,@body)))


;; Encode/Decode URL

(defun encode-url ()
  "Encode region via URL encoded."
  (interactive)
  (let ((s (string-trim>< (region-extract-str t))))
    (_enc_with_output_buffer_ +encode-output-buffer-name+
                              (insert (url-hexify-string s)))))

(defun decode-url ()
  "Decode region via URL decoded."
  (interactive)
  (let ((s (string-trim>< (region-extract-str t))))
    (_enc_with_output_buffer_ +decode-output-buffer-name+
                              (insert (decode-coding-string
                                       (url-unhex-string s)
                                       'utf-8)))))


 ;; end of URL


;; Encode/Decode base64


(defun encode-base64 ()
  "Encode region via base64 encoded."
  (interactive)
  (let ((s (string-trim>< (region-extract-str t))))
    (_enc_with_output_buffer_ +encode-output-buffer-name+
                              (insert (base64-encode-string
                                       (if (multibyte-string-p s)
                                           (encode-coding-string s 'utf-8)
                                         s)
                                       t)))))

(defun decode-base64 ()
  "Decode region base64 decoded."
  (interactive)
  (let ((s (string-trim>< (region-extract-str t))))
    (_enc_with_output_buffer_ +decode-output-buffer-name+
                              (insert (decode-coding-string
                                       (base64-decode-string s) 'utf-8)))))


 ;; end of base64


;; Encode/Decode IP address

(defmacro ipv4->int (s &optional small-endian)
  "Encode IPv4 address to int."
  (let ((ss (gensym*)))
    `(let ((,ss (and (stringp ,s)
                     (split-string* ,s "\\." t))))
       (when (and (consp ,ss) (= 4 (length ,ss)))
         (if ,small-endian
             (logior
              (lsh (string-to-number (nth 0 ,ss)) 24)
              (lsh (string-to-number (nth 1 ,ss)) 16)
              (lsh (string-to-number (nth 2 ,ss)) 8)
              (logand (string-to-number (nth 3 ,ss)) #xff))
           (logior
            (logand (string-to-number (nth 0 ,ss)) #xff)
            (lsh (string-to-number (nth 1 ,ss)) 8)
            (lsh (string-to-number (nth 2 ,ss)) 16)
            (lsh (string-to-number (nth 3 ,ss)) 24)))))))


(defmacro int->ipv4 (n &optional small-endian)
  "Decode IPv4 address to string."
  `(when (integerp ,n)
     (if ,small-endian
         (format "%s.%s.%s.%s"
                 (lsh (logand ,n #xff000000) -24)
                 (lsh (logand ,n #x00ff0000) -16)
                 (lsh (logand ,n #x0000ff00) -8)
                 (logand ,n #xff))
       (format "%s.%s.%s.%s"
               (logand ,n #xff)
               (lsh (logand ,n #x0000ff00) -8)
               (lsh (logand ,n #x00ff0000) -16)
               (lsh (logand ,n #xff000000) -24)))))


(defun encode-ipv4 (&optional arg endian)
  "Encode IPv4 address in region to int.

If ARG is non nil then output to `+encode-output-buffer-name+'.
If ENDIAN is t then decode in small endian."
  (interactive (list (if current-prefix-arg t nil)
                     (read-string "endian: " (if (= 108 (byteorder))
                                                 "small"
                                               "big"))))
  (let* ((n (ipv4->int (string-trim>< (region-extract-str t))
                       (string= "small" endian)))
         (out (and (integerp n)
                   (format "%d (#o%o, #x%x)" n n n))))
    (if arg
        (_enc_with_output_buffer_ +encode-output-buffer-name+
                                  (insert out))
      (message "%s" out))))


(defun decode-ipv4 (&optional arg endian)
  "Decode IPv4 address region to string.

If ARG is non nil then output to `+decode-output-buffer-name+'.
If ENDIAN is t then decode in small endian."
  (interactive (list (if current-prefix-arg t nil)
                     (read-string "endian: " (if (= 108 (byteorder))
                                                 "small"
                                               "big"))))
  (let* ((s (string-trim>< (region-extract-str t)))
         (out (int->ipv4 (cond ((string-match "^[#0][xX]" s)
                                (string-to-number (substring s 2) 16))
                               ((string-match "^[#0][oO]" s)
                                (string-to-number (substring s 2) 8))
                               (t (string-to-number s)))
                         (string= "small" endian))))
    (if arg
        (_enc_with_output_buffer_ +decode-output-buffer-name+
                                  (insert out))
      (message "%s" out))))


;; Roman/Chinese number to Arabic number

(defun roman->arabic (n acc)
  "Translate a roman number N into arabic number."
  (cond ((null n) acc)
        ((stringp n) (cond ((string= "M" n) 1000)
                           ((string= "D" n) 500)
                           ((string= "C" n) 100)
                           ((string= "L" n) 50)
                           ((string= "X" n) 10)
                           ((string= "V" n) 5)
                           ((string= "I" n) 1)))
        ((let ((u1 (roman->arabic (car n) 0) )
               (u2 (roman->arabic (cadr n) 0)))
           (< u1 u2))
         (roman->arabic (cddr n)
                        (+ acc (- (roman->arabic (cadr n) 0)
                                  (roman->arabic (car n) 0)))))
        (t (roman->arabic (cdr n)
                          (+ acc (roman->arabic (car n) 0))))))


(defun decode-roman-number (&optional arg)
  "Decode roman number into decimal number."
  (interactive "P")
  (let* ((ss (split-string* (region-extract-str t) "" t))
         (n (roman->arabic ss 0))
         (out (format "%d (#o%o, #x%x)" n n n)))
    (if arg
        (_enc_with_output_buffer_ +decode-output-buffer-name+
                                  (insert out))
      (message "%s" out))))


(defun chinese->arabic (n acc)
  "Translate a chinese number N into arabic number."
  (cond ((null n) acc)
        ((stringp n) (cond ((or (string= "亿" n)
                                (string= "億" n))
                            100000000)
                           ((or (string= "万" n)
                                (string= "萬" n))
                            10000)
                           ((string= "仟" n) 1000)
                           ((string= "佰" n) 100)
                           ((string= "拾" n) 10)
                           ((string= "玖" n) 9)
                           ((string= "捌" n) 8)
                           ((string= "柒" n) 7)
                           ((or (string= "陆" n)
                                (string= "陸" n))
                            6)
                           ((string= "伍" n) 5)
                           ((string= "肆" n) 4)
                           ((string= "叁" n) 3)
                           ((string= "贰" n) 2)
                           ((string= "壹" n) 1)
                           ((string= "零" n) 0)))
        ((let ((u (chinese->arabic (car n) 0))
               (u1 (chinese->arabic (cadr n) 0)))
           (and (< u 10) (> u 0)
                (< u1 10000) (>= u1 10)))
         (chinese->arabic (cddr n)
                          (+ acc (* (chinese->arabic (car n) 0)
                                    (chinese->arabic (cadr n) 0)))))
        ((let ((u (chinese->arabic (car n) 0)))
           (>= u 10000))
         (let ((u (chinese->arabic (car n) 0)))
           (chinese->arabic (cdr n)
                            (cond ((> acc 10000)
                                   (let ((b (* (/ acc (* u 1000))
                                               (* u 1000))))
                                     (+ b (* (- acc b) u))))
                                  (t (* acc u))))))
        (t (chinese->arabic (cdr n)
                            (+ acc (chinese->arabic (car n) 0))))))


(defun decode-chinese-number (&optional arg)
  "Decode chinese number to decimal number."
  (interactive "P")
  (let* ((ss (split-string* (region-extract-str t) "" t))
         (n (chinese->arabic ss 0))
         (out (format "%d (#o%o, #x%x)" n n n)))
    (if arg
        (_enc_with_output_buffer_ +decode-output-buffer-name+
                                  (insert out))
      (message "%s" out))))


 ;; end of Roman/Chinese number



;; end of file
