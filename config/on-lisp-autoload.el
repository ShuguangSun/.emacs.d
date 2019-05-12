;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; on-lisp-autoload.el
;;;;


(with-eval-after-load 'lisp-mode
  (safe-local-variable* 'Syntax)
  (safe-local-variable* 'Base)
  (safe-local-variable* 'Package))


(defun set-basic-lisp-mode! ()
  (setq indent-tabs-mode nil))


(if-version%
    <= 25.0
    (with-eval-after-load 'elisp-mode
      (add-hook 'emacs-lisp-mode-hook #'eldoc-mode))
  (with-eval-after-load 'lisp-mode
    (add-hook 'emacs-lisp-mode-hook #'eldoc-mode)))


(when-package%
  
  (defun set-featured-lisp-mode! ()
    "Set Lisp basic minor modes."
    (cond ((or (string= "*scratch*" (buffer-name))
               (string= "*ielm*" (buffer-name))))
          (t (if-feature-allowed% paredit
               ;; structured editing of s-expression data
               (enable-paredit-mode))

             (if-feature-allowed% rainbow-delimiters
               ;; hilighting parentheses,brackets,and braces in minor mode
               (rainbow-delimiters-mode))

             (if-feature-allowed% aggressive-indent
               ;; aggressive indent
               (aggressive-indent-mode))))))


(when-package%
  (if-feature-paredit%
    
    (defun enable-paredit-mode-in-minibuffer! ()
      (platform-supported-if 'gnu/linux
          (when (eq 'eval-expression this-command)
            (enable-paredit-mode))
        (enable-paredit-mode)))))


(with-eval-after-load 'lisp-mode
  (add-hook 'lisp-mode-hook #'set-basic-lisp-mode!)
  (add-hook 'emacs-lisp-mode-hook #'set-basic-lisp-mode!)
  (when-package%
    (add-hook 'lisp-mode-hook #'set-featured-lisp-mode!)
    (add-hook 'emacs-lisp-mode-hook #'set-featured-lisp-mode!)))


(with-eval-after-load 'scheme
  (add-hook 'scheme-mode-hook #'set-basic-lisp-mode!)    
  (when-package%
    (add-hook 'scheme-mode-hook #'set-featured-lisp-mode!)))


(when-package%
  (if-feature-allowed% paredit

    (platform-supported-if
        ;; enable `paredit' in `minibuffer'
        'gnu/linux
        (add-hook 'minibuffer-setup-hook
                  #'enable-paredit-mode-in-minibuffer! t)
      (add-hook 'eval-expression-minibuffer-setup-hook
                #'enable-paredit-mode-in-minibuffer! t))

    (with-eval-after-load 'paredit
      (when-var% paredit-mode-map 'paredit
        ;; define `paredit' keymap
        ;; On Windows C-) is not work
        ;; fix inconsistent `C-)' and `C-c )' behavior:#9
        ;; On Terminal mode, Ctrl+Shift combination can't send to Emacs
        (define-key% paredit-mode-map
          (kbd "C-c )") #'paredit-forward-slurp-sexp)
        (define-key% paredit-mode-map
          (kbd "C-c (") #'paredit-backward-slurp-sexp)
        (define-key% paredit-mode-map
          (kbd "C-c }") #'paredit-forward-barf-sexp)
        (define-key% paredit-mode-map
          (kbd "C-c {") #'paredit-backward-barf-sexp)
        (define-key% paredit-mode-map
          (kbd "C-c ?") #'paredit-convolute-sexp)
        (when-fn% 'xref-find-references 'xref
          ;; default `paredit-convolute-sexp' keybinding `M-?' conflicts with
          ;; `xref-find-references'
          (define-key paredit-mode-map
            (kbd "M-?") #'xref-find-references))))))


 ;; end of feature: paredit


;; fix: no TAB completion in minibuffer on ancient Emacs.
(unless-var% completion-at-point-functions 'minibuffer
  (if-key% minibuffer-local-map
      (kbd "TAB")
      (lambda (def) (eq def #'self-insert-command))
      (progn%
       (defun minibuffer-tab-completion! ()
         "TAB as completion key in minibuffer."
         ;; `lisp-complete-symbol' is an obsolete since Emacs24.4
         (define-key minibuffer-local-map (kbd "TAB")
           (if-fn% 'completion-at-point 'minibuffer
                   #'completion-at-point
             #'lisp-complete-symbol)))

       (add-hook 'minibuffer-setup-hook #'minibuffer-tab-completion! t))))


(defun set-ielm-mode! ()
  (lexical-supported-when
    (setq lexical-binding t)))

(with-eval-after-load 'ielm
  (add-hook 'ielm-mode-hook #'set-basic-lisp-mode! t)
  (add-hook 'ielm-mode-hook #'eldoc-mode t)
  (add-hook 'ielm-mode-hook #'set-ielm-mode!))


;; end of file
