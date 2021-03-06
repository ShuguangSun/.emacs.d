;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; on-term-autoload.el
;;;;


(defun term-unify-shell-prompt ()
  "Unify the shell prompt in `term'."
  (interactive)
  (let ((proc (get-buffer-process (current-buffer))))
    (unless proc
      (error "Current buffer has no process"))
    (let ((zsh (or (and (*self-env-spec* :get :shell :allowed)
                        (*self-env-spec* :get :shell :prompt :zsh))
                   "%n@%m:%~ %# "))
          (oth (or (and (*self-env-spec* :get :shell :allowed)
                        (*self-env-spec* :get :shell :prompt :bash))
                   "\\u@\\h:\\w\\$ ")))
      (process-send-string proc
                           (concat "case \"`basename $SHELL`\" in\n"
                                   "  zsh)\n"
                                   (format "    export PS1='%s'\n" zsh)
                                   "export PROMPT_COMMAND=''\n"
                                   "    ;;\n"
                                   "  *)\n"
                                   (format "    export PS1='%s'\n" oth)
                                   "export PROMPT_COMMAND=''\n"
                                   "    ;;\n"
                                   "esac\n")))))


(with-eval-after-load 'term
  (define-key% term-mode-map (kbd "C-c t p") #'term-unify-shell-prompt))


;; end of file
