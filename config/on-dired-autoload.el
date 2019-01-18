;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; on-dired-autoload.el
;;;;


(platform-supported-when 'windows-nt
  ;; on Windows: there are no builtin zip program
  ;; so try to use minzip in Emacs dep for Windows.
  ;; zip.bat works with `dired-do-compress-to' and `org-odt-export-to-odt'.
  (eval-when-compile
    
    (defun make-zip-bat (zip &rest ignore)
      "Make ZIP.bat in `exec-path' for minizip or 7za."
      (declare (indent 1))
      (when (stringp zip)
        (save-str-to-file
         (concat "@echo off\n"
                 (format "REM zip.bat for %s on Windows\n" zip)
                 "REM generated by More Reasonable Emacs "
                 (more-reasonable-emacs) "\n\n"
                 "REM local variable declaration\n\n"
                 "setlocal EnableDelayedExpansion\n"
                 "\n"
                 "set _OPT=%*\n"
                 "set _ZIP=\n"
                 "set _ARGV=\n"
                 "\n"
                 "REM parsing command line arguments\n\n"
                 ":getopt\n"
                 (cond ((string= "minizip" zip)
                        "if \"%1\"==\"-mX0\" set _OPT=%_OPT:-mX0=-0% & shift & goto :getopt\n")
                       ((string= "7za" zip)
                        (concat
                         "if \"%1\"==\"-mX0\" set _OPT=%_OPT:-mX0=-mx0% & shift & goto :getopt\n"
                         "if \"%1\"==\"-0\" set _OPT=%_OPT:-0=-mx0% & shift & goto :getopt\n"
                         "if \"%1\"==\"-9\" set _OPT=%_OPT:-9=-mx9% & shift & goto :getopt\n")))
                 "\n"
                 "REM ignore options\n"
                 (let ((options nil))
                   (dolist (x (cond ((string= "minizip" zip)
                                     (append '("-r" "--filesync" "-rmTq") ignore))
                                    ((string= "7za" zip)
                                     (append '("-r" "--filesync" "-rmTq"))))
                              options)
                     (setq options
                           (concat options
                                   (format "if \"%%1\"==\"%s\" set _OPT=%%_OPT:%s=%% & shift & goto :getopt\n" x x)))))
                 "\n"
                 "REM extract zip and argv\n"
                 "if not \"%1\"==\"\" (\n"
                 "  if \"%_ZIP%\"==\"\" (\n"
                 "    if \"%_ARGV%\"==\"\" (\n"
                 "      set _ZIP=%1\n"
                 "    )\n"
                 "  ) else (\n"
                 "    set _ARGV=%_ARGV% %1\n"
                 "  )\n"
                 "  set _OPT=!_OPT:%1=!\n"
                 "  shift\n"
                 "  goto :getopt\n"
                 ")\n\n"
                 (cond ((string= "7za" zip)
                        (concat "REM 7za call\n"
                                "7za a %_OPT% -tzip -- %_ZIP% %_ARGV%\n"
                                "if exist %_ZIP% (\n"
                                "  7za d %_OPT% -tzip -- %_ZIP% %_ZIP%\n"
                                ")\n"))
                       ((string= "minizip" zip)
                        (concat "REM minizip recursive call\n\n"
                                "call :loop %_ARGV%\n"
                                "goto :end\n"
                                "\n:zip\n"
                                "set _file=%1\n"
                                "set _file=%_file:./=%\n"
                                "if not \"%_file%\"==\"%_ZIP%\" (\n"
                                "  if exist %_ZIP% (\n"
                                "    minizip %_OPT% -a %_ZIP% %_file%\n"
                                "  ) else (\n"
                                "    minizip %_OPT% %_ZIP% %_file%\n"
                                "  )\n"
                                ")\n"
                                "goto :end\n"
                                "\n:loop\n"
                                "for %%i in (%*) do (\n"
                                "  if exist \"%%i/*\" (\n"
                                "    for %%f in (%%i/*) do (\n"
                                "      call :loop %%i/%%f\n"
                                "    )\n"
                                "    for /d %%d in (%%i/*) do (\n"
                                "      call :loop %%i/%%d\n"
                                "    )\n"
                                "  ) else (\n"
                                "    call :zip %%i\n"
                                "  )\n"
                                ")\n"
                                "\n:end\n"))))
         (v-home% ".exec/zip.bat"))))

    (unless (executable-find% "zip")
      ;; zip external program
      (cond ((executable-find% "7za") (make-zip-bat "7za"))
            ((executable-find% "minizip") (make-zip-bat "minizip"))))))


(platform-supported-when 'windows-nt

  (with-eval-after-load 'dired
    ;; prefer GNU find on Windows, such for `find-dired' or `find-name-dired'.
    (let ((find (executable-find%
                 "find"
                 (lambda (bin)
                   (let ((ver (shell-command* bin "--version")))
                     (when (zerop (car ver))
                       (string-match "^find (GNU findutils)"
                                     (cdr ver))))))))
      (when find
        (windows-nt-env-path+ (file-name-directory find))))))

 ;; end of `dired' setting


(platform-supported-when 'windows-nt

  (unless% (eq default-file-name-coding-system locale-coding-system)

    (defadvice insert-directory (before insert-directory-before compile)
      "`dired-find-file' should failed when using GNU's ls program on Windows.
       We try to encode multibyte directory name with
       `locale-coding-system' when the multibyte directory name
       encoded with non `locale-coding-system'."
      (when (multibyte-string-p (ad-get-arg 0))
        (ad-set-arg 0 (encode-coding-string (ad-get-arg 0)
                                            locale-coding-system))))

    (defadvice dired-shell-stuff-it (before dired-shell-stuff-before compile)
      "`dired-do-shell-command' or `dired-do-async-shell-command'
       should failed when open the files which does not been
       encoded with `locale-coding-system'."
      (ad-set-arg 1 (let ((arg1 (ad-get-arg 1))
                          (files nil))
                      (dolist (x arg1 files)
                        (if (multibyte-string-p x)
                            (add-to-list 'files
                                         (encode-coding-string
                                          x
                                          locale-coding-system)
                                         t #'string=)
                          (add-to-list 'files x t #'string=))))))

    (defadvice dired-shell-command (before dired-shell-command-before compile)
      "`dired-do-compress-to' should failed when
       `default-directory' or `dired-get-marked-files' does not
       encoded with `locale-coding-system'."
      (when (multibyte-string-p (ad-get-arg 0))
        (ad-set-arg 0 (encode-coding-string (ad-get-arg 0)
                                            locale-coding-system))))

    (defadvice dired-compress-file (before dired-compress-file-before compile)
      "`dired-compress-file' should failed when FILE arg does not
       encoded with `locale-coding-string'."
      (let ((arg0 (ad-get-arg 0)))
        (when (multibyte-string-p arg0)
          (ad-set-arg 0 (encode-coding-string arg0 locale-coding-system)))))

    ))


(platform-supported-unless 'gnu/linux

  (with-eval-after-load 'ido
    ;; see `ido-dired'
    (let ((ls (executable-find% "ls"
                                (lambda (ls)
                                  (let ((ver (shell-command* ls "--version")))
                                    (when (zerop (car ver))
                                      (string-match "^ls (GNU coreutils)"
                                                    (cdr ver))))))))
      (if ls
          (progn%
           ;; prefer GNU's ls (--dired option) on Windows or
           ;; Darwin. on Windows: `dired-mode' does not display
           ;; executable flag in file mode，see `dired-use-ls-dired'
           ;; for more defails
           (setq% ls-lisp-use-insert-directory-program t 'ls-lisp)
           (platform-supported-when 'windows-nt
             (unless% (eq default-file-name-coding-system locale-coding-system)
               (ad-activate #'insert-directory t))))
        (platform-supported-when 'darwin
          ;; on Drawin: the builtin ls does not support --dired option
          (setq% dired-use-ls-dired nil 'dired))))))



(with-eval-after-load 'dired-aux

  (if-fn% 'dired-do-compress-to 'dired-aux
          (when-var% dired-compress-files-alist 'dired-aux
            ;; `format-spec' may not autoload
            (require 'format-spec)
            ;; compress .7z file via [c] key
            (when% (and (executable-find% "7za")
                        (not (assoc** "\\.7z\\'" dired-compress-files-alist #'string=)))
              (push (cons "\\.7z\\'" "7za a -t7z %o %i")
                    dired-compress-files-alist)))

    ;; on ancient Emacs, `dired' can't recognize .zip archive. 
    ;; [! zip x.zip ?] compress marked files to x.zip，
    ;; see `dired-compress-file-suffixes'.
    (when% (and (executable-find% "zip")
                (executable-find% "unzip"))
      (unless (assoc** "\\.zip\\'" dired-compress-file-suffixes #'string=)
        (add-to-list 'dired-compress-file-suffixes
                     '("\\.zip\\'" ".zip" "unzip")))))

  (platform-supported-when 'windows-nt
    ;; error at `dired-internal-noselect' on Windows:
    ;; Reading directory: "ls --dired -al -- d:/abc/中文/" exited with status 2
    ;; https://lists.gnu.org/archive/html/emacs-devel/2016-01/msg00406.html
    ;; (setq file-name-coding-system locale-coding-system)
    (unless% (eq default-file-name-coding-system locale-coding-system)
      (ad-activate #'dired-shell-stuff-it t)
      (ad-activate #'dired-shell-command t))

    ;; [Z] to compress or uncompress .gz file
    (when% (or (executable-find% "gzip")
               (executable-find% "7za"))
      (when% (assoc** ":" dired-compress-file-suffixes #'string=)
        (setq dired-compress-file-suffixes
              (remove (assoc** ":" dired-compress-file-suffixes #'string=)
                      dired-compress-file-suffixes))
        (unless% (executable-find% "gzip")
          (setcdr (assoc** "\\.gz\\'" dired-compress-file-suffixes #'string=)
                  '("" "7za x -aoa %i"))))

      (when-fn% 'dired-compress-file 'dired-aux
        (ad-activate #'dired-compress-file t)))

    ;; [c] compress or uncompress .7z file
    (when% (executable-find% "7za")
      (if% (assoc** "\\.7z\\'" dired-compress-file-suffixes #'string=)
          (setcdr (assoc** "\\.7z\\'" dired-compress-file-suffixes #'string=)
                  '("" "7za x -aoa -o%o %i"))
        (put (list "\\.7z\\'" "" "7za x -aoa -o%o %i"))))))


(platform-supported-when 'windows-nt
  (unless% (eq default-file-name-coding-system locale-coding-system)

    (defadvice archive-summarize-files (before archive-summarize-files-before compile)
      "`archive-summarize-files' may not display file name in
       right coding system."
      (let ((arg0 (ad-get-arg 0))
            (files nil))
        (when (consp arg0)
          (ad-set-arg
           0
           (dolist (x arg0 files)
             (aset x
                   0
                   (decode-coding-string
                    (aref x 0)
                    locale-coding-system))
             (add-to-list 'files x t #'eq))))))


    (with-eval-after-load 'arc-mode
      (ad-activate #'archive-summarize-files t))))


;; ido-mode allows you to more easily navigate choices. For example,
;; when you want to switch buffers, ido presents you with a list
;; of buffers in the the mini-buffer. As you start to type a buffer's
;; name, ido will narrow down the list of buffers to match the text
;; you've typed in
;; http://www.emacswiki.org/emacs/InteractivelyDoThings
(ido-mode t)


 ;; end of file
