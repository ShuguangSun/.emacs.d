;;;;
;; Clojure
;;;;


;; clojure mode hooks
(add-hook 'clojure-mode-hook
          (lambda ()
            (when (boundp 'inferior-lisp-program)
              (setq inferior-lisp-program "boot repl"))
            ;; enable paredit 
            (enable-paredit-mode)
            ;; enable camel case support for editing commands
            (subword-mode)
            ;; hilighting parentheses,brackets,and braces in minor mode
            (rainbow-delimiters-mode)
            ;; enable automatically adjust the identation of code
            (aggressive-indent-mode)))


;; use clojure mode for other extensions
(add-to-list 'auto-mode-alist '("\\.edn$" . clojure-mode))
(add-to-list 'auto-mode-alist '("\\.boot$" . clojure-mode))
(add-to-list 'magic-mode-alist '(".* boot" . clojure-mode))


;;;;
;; Cider
;;;;

;; provides minibuffer documentation for the code you're typing into the repl
(add-hook 'cider-mode-hook #'eldoc-mode)
(add-hook 'cider-repl-mode-hook #'eldoc-mode)

;; go right to the REPL buffer when it's finished connecting
(when (boundp 'cider-repl-pop-to-buffer-on-connect)
  (setq cider-repl-pop-to-buffer-on-connect t))

;; when there's a cider error, show its buffer and switch to it
(when (boundp 'cider-show-error-buffer)
  (setq cider-show-error-buffer t))
(when (boundp 'cider-auto-select-error-buffer)
  (setq cider-auto-select-error-buffer t))

;; where to store the cider history.
(when (boundp 'cider-repl-history-file)
  (setq cider-repl-history-file "~/.emacs.d/cider-history"))

;; wrap when navigating history.
(when (boundp 'cider-repl-wrap-history)
  (setq cider-repl-wrap-history t))

;; enable paredit for Cider
(add-hook 'cider-repl-mode-hook #'paredit-mode)


;; key bindings
;; these help me out with the way I usually develop web apps
(defun cider-start-http-server ()
  (interactive)
  (when (fboundp 'cider-load-current-buffer)
    (cider-load-current-buffer))
  (when (fboundp 'cider-current-ns)
    (let ((ns (cider-current-ns)))
      (when (fboundp 'cider-repl-set-ns)
        (cider-repl-set-ns ns))
      (when (fboundp 'cider-interactive-eval)
        (cider-interactive-eval
         (format "(println '(def server (%s/start))) (println 'server)" ns))
        (cider-interactive-eval
         (format "(def server (%s/start)) (println server)" ns))))))


(defun cider-refresh ()
  (interactive)
  (when (fboundp 'cider-interactive-eval)
    (cider-interactive-eval (format "(user/reset)"))))

(defun cider-user-ns ()
  (interactive)
  (when (fboundp 'cider-repl-set-ns)
    (cider-repl-set-ns "user")))

(eval-after-load 'cider
  '(progn
     (when (boundp 'clojure-mode-map)
       (define-key clojure-mode-map (kbd "C-c C-v") 'cider-start-http-server)
       (define-key clojure-mode-map (kbd "C-M-r") 'cider-refresh))
     (when (boundp 'cider-mode-map)
       (define-key cider-mode-map (kbd "C-c u") 'cider-user-ns))
     ;; enable Figwheel: cider-jack-in-clojurescript
     (setq cider-cljs-lein-repl
      "(do (require 'figwheel-sidecar.repl-api)
             (figwheel-sidecar.repl-api/start-figwheel!)
             (figwheel-sidecar.repl-api/cljs-repl))")))
