;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; on-dired-autoload.el
;;;;


(if-fn% dired-do-compress-to dired-aux
				(when-var% dired-compress-files-alist dired-aux
									 (with-eval-after-load 'dired-aux
										 ;; `format-spec' may not autoload
										 (require 'format-spec)))
	(when-var% dired-compress-file-suffixes dired-aux
						 ;; on ancent Emacs, `dired' can't recognize .zip archive.
						 ;; [Z] key should be recognize .zip extension and uncompress a .zip archive.
						 ;; [! zip x.zip ?] compress marked files to x.zip
						 ;; see `dired-compress-file-suffixes'.
						 (with-eval-after-load 'dired-aux
							 (when (and (executable-find% "zip")
													(executable-find% "unzip"))
								 (unless (assoc** "\\.zip\\'" dired-compress-file-suffixes #'string=)
									 (add-to-list 'dired-compress-file-suffixes
																'("\\.zip\\'" ".zip" "unzip")))))))


(platform-supported-when windows-nt

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


(platform-supported-unless gnu/linux

	(platform-supported-when windows-nt
		(defadvice insert-directory (before insert-directory-before compile)
			"`dired-find-file' should failed when using GNU's ls program on Windows.
We try to encode multibyte directory name with `locale-coding-system' 
when the multibyte directory name encoded with non `locale-coding-system'."
			(when (multibyte-string-p (ad-get-arg 0))
				(ad-set-arg 0 (encode-coding-string (ad-get-arg 0)
																						locale-coding-system)))))


	(with-eval-after-load 'ido
		;; see `ido-dired'
		(let ((ls (executable-find% "ls"
																(lambda (ls)
																	(let ((ver (shell-command* ls "--version")))
																		(when (zerop (car ver))
																			(string-match "^ls (GNU coreutils)"
																										(cdr ver))))))))
			(if ls
					;; prefer GNU's ls on Windows or Darwin
					;; on Windows: `dired-mode' does not display executable flag in file mode
					;; see `dired-use-ls-dired' for more defails
					(progn%
					 ;; error at `dired-internal-noselect' on Windows:
					 ;; Reading directory: "ls --dired -al -- d:/abc/中文/" exited with status 2
					 ;; https://lists.gnu.org/archive/html/emacs-devel/2016-01/msg00406.html
					 ;; (setq file-name-coding-system locale-coding-system)
					 (setq% ls-lisp-use-insert-directory-program t ls-lisp)
					 (platform-supported-when windows-nt
						 (unless (eq default-file-name-coding-system locale-coding-system)
							 (ad-activate #'insert-directory t))))

				(platform-supported-when darwin
					;; on Drawin: ls does not support --dired option
					(setq% dired-use-ls-dired nil dired))))))


;; ido-mode allows you to more easily navigate choices. For example,
;; when you want to switch buffers, ido presents you with a list
;; of buffers in the the mini-buffer. As you start to type a buffer's
;; name, ido will narrow down the list of buffers to match the text
;; you've typed in
;; http://www.emacswiki.org/emacs/InteractivelyDoThings
(ido-mode t)


 ;; end of `ido-dired' setting
