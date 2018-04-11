;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;;;;


(defmacro comment (&rest body)
  "Ignores body, yields nil."
  nil)


(defvar loading-start-time
  (current-time)
  "The start time at loading init.el")


(defvar emacs-home
  (if (boundp 'user-emacs-directory)
      user-emacs-directory
    "~/.emacs.d/")
  "The user's emacs home directory")


(defmacro emacs-home* (&rest subdirs)
  "Return path of SUBDIRS under `emacs-home'."
  (declare (indent 0))
  `(concat ,emacs-home ,@subdirs))


(defvar v-dir
  (concat (if (display-graphic-p) "g_" "t_")
          emacs-version)
  "Versioned dir based on [g]rahpic/[t]erminal mode and Emacs's version")


(defmacro v-home* (subdir &optional file)
  "Return versioned path of SUBDIR/FILE under `emacs-home'."
  `(concat ,emacs-home ,subdir ,v-dir "/" ,file))


(defmacro v-home% (subdir &optional file)
  "Return versioned path of SUBDIR/FILE under `emacs-home' at compile-time."
  (let ((_vfile_ (v-home* subdir file)))
    `,_vfile_))


(defmacro v-home! (subdir &optional file)
  "Make the versioned path of SUBDIR/FILE under `emacs-home' and return it."
  (let ((_vdir_ (v-home* subdir))
        (_vfile_ (v-home* subdir file)))
    (unless (file-exists-p _vdir_)
      (make-directory _vdir_ t))
    `,_vfile_))


(defmacro file-name-base* (file)
  "Return base name of FILE with no directory, no extension."
  `(file-name-sans-extension (file-name-nondirectory ,file)))


(defmacro v-path! (file dir &optional extension)
  "Return versioned DIR base on existing FILE's directory and return it."
  `(when (and ,dir (file-exists-p ,file))
     (let ((v (concat (file-name-directory ,file) ,dir "/")))
       (unless (file-exists-p v) (make-directory v t))
       (concat v (if (and ,extension (file-name-extension ,file))
                     (concat (file-name-base* ,file) "." ,extension)
                   (file-name-nondirectory ,file))))))





(defmacro compile-and-load-file* (vdir file &optional only-compile)
  "Compile FILE and save the compiled one in VDIR then load it.

If ONLY-COMPILE is t then do not load FILE."
  (let ((c (make-symbol "-compiled:0-"))
        (s (make-symbol "-source:0-")))
    `(when (and (stringp ,file) (file-exists-p ,file))
       (let ((,c (v-path! ,file ,vdir "elc")))
         (when (or (not (file-exists-p ,c))
                   (file-newer-than-file-p ,file ,c))
           (let ((,s (v-path! ,file ,vdir)))
             (copy-file ,file ,s t)
             (byte-compile-file ,s)))
         (or ,only-compile
             (load ,c))))))


(defmacro clean-compiled-files ()
  "Clean all compiled files."
  `(dolist (d (list ,(v-home* "config/")
                    ,(v-home* "private/")))
     (dolist (f (directory-files d nil "\\.elc?$"))
       (message "#Clean compiled file: %s" f)
       (delete-file (concat d f)))))




(defmacro progn% (&rest body)
  "Return an `progn'ed form if BODY has more than one sexp.

Else return BODY sexp."
  (if (cdr body) `(progn ,@body) (car body)))


(defmacro version-supported* (cond version)
  "Return t if (COND VERSION EMACS-VERSION) yields non-nil, else nil.

COND should be quoted, such as (version-supported* '<= 24)"
  `(funcall ,cond
            (truncate (* 10 ,version))
            (+ (* 10 emacs-major-version) emacs-minor-version)))


(defmacro version-supported-p (cond version)
  "Returns t if (COND VERSION `emacs-version') yields non-nil, else nil.

It resemble `version-supported*' but it has constant runtime."
  (let ((x (version-supported* `,cond `,version)))
    x))


(defmacro version-supported-if (cond version then &rest else)
  "If (COND VERSION `emacs-version') yields non-nil, do THEN, else do ELSE...

Returns the value of THEN or the value of the last of the ELSE’s.
THEN must be one expression, but ELSE... can be zero or more expressions.
If (COND VERSION EMACS-VERSION) yields nil, and there are no ELSE’s, the value is nil. "
  (declare (indent 3))
  (if (version-supported* `,cond `,version)
      `,then
    `(progn% ,@else)))


(defmacro version-supported-when (cond version &rest body)
  "If (COND VERSION `emacs-version') yields non-nil, do BODY, else return nil.

When (COND VERSION `emacs-version') yields non-nil, eval BODY forms 
sequentially and return value of last one, or nil if there are none."
  (declare (indent 2))
  `(version-supported-if ,cond ,version (progn% ,@body)))


(defmacro package-supported-p (&rest body)
  "Run BODY code if current `emacs-version' supports package."
  (declare (indent 0))
  `(version-supported-when <= 24.1 ,@body))





;; Load strap
(compile-and-load-file*
 v-dir
 (emacs-home* "config/strap.el"))


(package-supported-p
  (setq package-enable-at-startup nil)
  (comment (package-initialize)))


;; After loaded ...

(let ((elapsed
       (float-time
        (time-subtract (current-time) loading-start-time))))
  (message "#Loading init.el ... done (%.3fs)" elapsed))



;; ^ End of init.el
