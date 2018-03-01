;;;; -*- lexical-binding:t -*-
;;;;
;; autoloads
;;;;


(autoload 'system-cc-include
  (v-home* "config/" "cc.elc")
  "Returns a list of system include directories.")


(defun set-global-keys! ()
  
  ;; open file or url at point
  (safe-fn-when find-file-at-point
    (global-set-key (kbd "C-c b") 'find-file-at-point))

  (linum-mode-supported-p
   (global-set-key (kbd "C-c l") 'toggle-linum-mode))

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

  ;; bing dict
  (safe-fn-when bing-dict-brief
    (global-set-key (kbd "C-c d") 'bing-dict-brief))

  ;; `C-x r g' and `C-x r i' are all bound to insert-register
  ;; but `C-x r g' can do thing by one hand
  (global-set-key (kbd "C-x r g") 'string-insert-rectangle)

  ;; Key binding to use "hippie expand" for text autocompletion
  ;; http://www.emacswiki.org/emacs/HippieExpand
  (global-set-key (kbd "M-/") 'hippie-expand)

  )


(defun set-default-modes! ()
  ;; ido-mode allows you to more easily navigate choices. For example,
  ;; when you want to switch buffers, ido presents you with a list
  ;; of buffers in the the mini-buffer. As you start to type a buffer's
  ;; name, ido will narrow down the list of buffers to match the text
  ;; you've typed in
  ;; http://www.emacswiki.org/emacs/InteractivelyDoThings
  (ido-mode t)

  ;; enable save minibuffer history
  (version-supported-if
      <= 24
      (savehist-mode)
    (savehist-mode t))

  )


(add-hook 'after-init-hook #'set-default-modes! t)
(add-hook 'after-init-hook #'set-global-keys! t)

