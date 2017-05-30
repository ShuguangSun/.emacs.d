;;
;; TAGS defintion and make
;;



;; Versionized TAGS directories, use `visit-tag-table' to visit
(defvar vdir-tags (expand-file-name (make-vdir ".tags/")))
(setq tags-table-list (list vdir-tags))


(defun dir-files-iter (dir ff df fn)
  (dolist (f (file-name-all-completions "" dir))
    (unless (member f '("./" "../"))
      (let ((full-name (expand-file-name f dir)))
        (if (directory-name-p f)
            (when (and df (funcall df f)
                       (dir-files-iter full-name ff df fn)))
          (when (and ff (funcall ff f)
                     (funcall fn full-name))))))))

(defun make-emacs-tags (&optional emacs-src)
  (let ((lisp-ff (lambda (f) (string-match "\.el$" f)))
        (lisp-df (lambda (d) (not (or (string-match "^\\\..*/" d)
                                      (string-match "elpa/" d)
                                      (string-match "theme/" d)
                                      (string-match "g_.*/" d)
                                      (string-match "t_.*/" d)))))
        (fn (lambda (f) (message "%s" f))))
    (dir-files-iter emacs-home lisp-ff lisp-df fn)))


(defmacro append-etags-paths (paths)
  `(when ,paths
     (let ((s (concat (format " -path \"%s\"" (car ,paths)))))
       (dolist (p (cdr, paths))
         (setq s (concat s (format " -o -path \"%s\"" p))))
       s)))

(defmacro append-etags-names (names)
  `(when ,names
     (let ((s (concat (format " -name \"%s\"" (car ,names)))))
       (dolist (n (cdr ,names))
         (setq s (concat s (format " -o -name \"%s\"" n))))
       s)))

(defmacro build-etags-lisp-command (find xargs dir tags &optional paths names)
  `(let ((f "%s %s %s %s | %s etags -o %s -a "))
     (format f
             ,find
             ,dir
             (if ,paths ,paths "")
             (if ,names ,names "")
             ,xargs
             ,tags)))

(defmacro build-etags-c-command (find xargs dir tags &optional names)
  `(let ((f "%s %s -type f \\\( %s \\\) | %s etags -o %s -a"))
     (format f
             ,find
             ,dir
             (if ,names ,names "")
             ,xargs
             ,tags)))


(defun make-emacs-etags (&optional emacs-src emacs-lisp)
  "Make tags of `emacs-home' via etags."
  (let ((tags (concat vdir-tags "TAGS"))
        (find-bin (platform-supported-if windows-nt "/usr/bin/find" "find"))
        (xargs-bin (platform-supported-if windows-nt "/usr/bin/xargs" "xargs")))
    (when (file-exists-p tags) (delete-file tags))
    (safe-do-when set-windows-nt-shell (set-windows-nt-shell))
    (shell-command
     (build-etags-lisp-command
      find-bin
      xargs-bin
      emacs-home
      tags
      (format
       "\\\( %s \\\) -prune "
       (append-etags-paths '("*/.git" "*/elpa" "*/g_*" "*/t_*")))
      (format
       "-o \\\( %s \\\)"
       (append-etags-names '("*.el")))))
    (when (and emacs-src (file-exists-p emacs-src))
      (shell-command
       (message "%s"
                (build-etags-c-command
                 find-bin
                 xargs-bin
                 emacs-src
                 tags
                 (append-etags-names '("*.c" "*.h"))))))
    (when (and emacs-lisp (file-exists-p emacs-lisp))
      (shell-command
       (build-etags-lisp-command
        find-bin
        xargs-bin
        emacs-lisp
        tags
        nil
        (append-etags-names '("*.el")))))))
