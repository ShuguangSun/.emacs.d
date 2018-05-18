;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; autoload.el
;;;;


;; set-global-key!

(defun set-global-key! ()
  
  ;; open file or url at point
  (when-fn% find-file-at-point ffap
    (global-set-key (kbd "C-c b") #'find-file-at-point))

	
  ;; Shows a list of buffers
  (global-set-key (kbd "C-x C-b") #'ibuffer)

  ;; interactive search key bindings.
  ;; by default, C-s runs isearch-forward, so this swaps the bindings.
  (global-set-key (kbd "C-s") 'isearch-forward-regexp)
  (global-set-key (kbd "C-r") 'isearch-backward-regexp)
  (global-set-key (kbd "C-M-s") 'isearch-forward)
  (global-set-key (kbd "C-M-r") 'isearch-backward)

  ;; Interactive query replace key bindings.
  (global-set-key (kbd "M-%") 'query-replace-regexp)
  (global-set-key (kbd "C-M-%") 'query-replace-regexp)

  ;; toggle comment key strike
  (global-set-key (kbd "C-c ;") 'toggle-comment)

  ;; `C-x r g' and `C-x r i' are all bound to insert-register
  ;; but `C-x r g' can do thing by one hand
  (global-set-key (kbd "C-x r g") 'string-insert-rectangle)

  ;; Key binding to use "hippie expand" for text autocompletion
  ;; http://www.emacswiki.org/emacs/HippieExpand
  (global-set-key (kbd "M-/") 'hippie-expand)


	(feature-bing-dict-supported-p
		(package-spec-:allowed-p

			;; `bing-dict'
			(global-set-key (kbd "C-c d") 'bing-dict-brief)))

	
  )

 ;; end of set-global-key!

;; set-flavor-mode!

(defun set-flavor-mode! ()


  ;; don't use hard tabs
  (setq indent-tabs-mode nil)

  ;; disable electric indent mode
  (setq% electric-indent-mode nil electric)

	
  ;; default tab-width
  (setq-default tab-width 2)


	(compile! v-dir
		(compile-unit (emacs-home* "config/on-compile-autoload.el"))
		(compile-unit (emacs-home* "config/on-dired-autoload.el"))
		(compile-unit (emacs-home* "config/on-edit-autoload.el"))
		(compile-unit (emacs-home* "config/on-lisp-autoload.el"))
		(feature-linum-supported-p
			(compile-unit (emacs-home* "config/on-linum-autoload.el")))
		)

	
	(with-eval-after-load 'sh-script
		(add-hook 'sh-mode-hook #'set-sh-mode!))

	(with-eval-after-load 'grep
		(define-key* grep-mode-map (kbd "g") #'recompile grep)
		(define-key* grep-mode-map (kbd "q") #'quit-window grep))


  )

 ;; end of set-flavor-mode!


;; after-init
(add-hook 'after-init-hook #'set-flavor-mode! t)
(add-hook 'after-init-hook #'set-global-key! t)

;; autoload declarations
(autoload 'system-cc-include
	(v-home% "config/" "cc.elc")
	"Return a list of system include directories.")

(autoload 'use-cc
	(v-home% "config/" "cc.elc")
	"Use `semantic-mode' in`c-mode'")
