;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; gambit-mode.el --- Run Gambit in an Emacs buffer
;;;;

;;;;
;; Redefined target:
;; 1. a derived scheme mode, works on Windows, Darwin and Linux.
;; 2. lexical scoped.
;;;;

(require 'cmuscheme)

(defgroup gambit nil
  "Run a gambit process in a buffer."
  :group 'scheme)

(defcustom% gambit-program-name "gsc-script -:d1- -i"
  "Program invoked by the `run-gambit' command."
  :type 'string
  :group 'gambit)

(defcustom% gambit-mode-hook nil
  "Hook for customizing `inferior-scheme-gambit-mode'."
  :type 'hook
  :group 'gambit)

(defvar *gambit-buffer* nil
  "The current gambit process buffer.")

(define-derived-mode gambit-repl-mode comint-mode "REPL"
  "Major mode for interacting with a gambit process.

The following commands are available:
\\{gambit-mode-map}

A gambit process can be fired up with M-x `run-gambit'.

Customization: Entry to this mode runs the hooks on
`comint-mode-hook' and `gambit-mode-hook' (in that order).

You can send text to the gambib process from other buffers
containing Scheme source.
 `switch-to-scheme' switches the current buffer to the gambit process buffer.
 `scheme-send-definition' sends the current definition to the gambit process.
 `scheme-compile-definition' compiles the current definition.
 `scheme-send-region' sends the current region to the gambit process.
 `scheme-compile-region' compiles the current region.

 `scheme-send-definition-and-go',
 `scheme-compile-definition-and-go', 

  `scheme-send-region-and-go', and `scheme-compile-region-and-go'
     switch to the gambit process buffer after sending their text.
     For information on running multiple processes in multiple
     buffers, see documentation for variable `scheme-buffer'.

Commands:
Return after the end of the process' output sends the
  text from the end of process to point.
Return before the end of the process' output copies the sexp
  ending at point to the end of the process' output, and sends
  it.
Delete converts tabs to spaces as it moves back.
Tab indents for Scheme; with argument, shifts rest of expression
    rigidly with the current line.

C-M-q does Tab on each line starting within following expression.
Paragraphs are separated only by blank lines.  Semicolons start
comments.  If you accidentally suspend your process, use
\\[comint-continue-subjob] to continue it."
  (setq comint-prompt-regexp "^[^>\n]*>+ *")
  (setq comint-prompt-read-only t)
  (scheme-mode-variables)
  (setq comint-input-filter #'scheme-input-filter)
  (setq comint-get-old-input #'scheme-get-old-input))


(defun run-gambit (cmd)
  "Run an inferior Scheme process, input and output via buffer `*gambit*'.

If there is a process already running in `*scheme*', switch to
that buffer.  With argument, allows you to edit the command
line (default is value of `scheme-program-name').

Run the hook `gambit-mode-hook' after the `comint-mode-hook'."
  (interactive (list (if current-prefix-arg
			                   (read-string "Run Gambit: " gambit-program-name)
			                 gambit-program-name)))
  (when (not (comint-check-proc "*gambit*"))
    (let ((cmdlist (split-string* cmd "\\s-+" t)))
      (set-buffer (apply 'make-comint "gambit"
                         (car cmdlist)
                         nil ;; no start file, gsi default init: ~/gambini
                         (cdr cmdlist)))
	    (gambit-repl-mode)))
  (setq gambit-program-name cmd)
  (setq *gambit-buffer* "*gambit*")
  (setq mode-line-process '(":%s"))
  (switch-to-buffer "*gambit*"))


(defun gambit-start-repl-process ()
  "Start an Gambit process.

Return the process started. Since this command is run implicitly,
always ask the user for the command to run."
  (save-window-excursion
    (run-gambit (read-string "Run Gambit: " gambit-program-name))))

(defun gambit-proc ()
  "Return the current Scheme process, starting one if necessary.
See variable `*gambit-buffer*'."
  (unless (and *gambit-buffer*
               (get-buffer *gambit-buffer*)
               (comint-check-proc *gambit-buffer*))
    (gambit-start-repl-process))
  (or (get-buffer-process *gambit-buffer*)
      (error "No current process.  See variable `*gambit-buffer*'")))

(defun gambit-switch-to-repl (eob-p)
  "Switch to the `*gambit-buffer*'.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and *gambit-buffer* (get-buffer *gambit-buffer*))
          (gambit-start-repl-process))
      (pop-to-buffer *gambit-buffer*)
    (error "No current process buffer.  See variable `*gambit-buffer*'"))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defun gambit-compile-file (file-name)
  "Compile a Scheme file FILE-NAME in `*gambit-buffer*'."
  (interactive (comint-get-source
                "Compile Scheme file: "
                scheme-prev-l/c-dir/file
                scheme-source-modes
                nil)) 
  (comint-check-source file-name)
  (setq scheme-prev-l/c-dir/file (cons (file-name-directory file-name)
                                       (file-name-nondirectory file-name)))
  (comint-send-string (gambit-proc)
                      (concat "(compile-file \"" file-name "\")\n"))
  (gambit-switch-to-repl t))

(defun gambit-load-file (file-name)
  "Load a Scheme file FILE-NAME into `*gambit-buffer**'."
  (interactive (comint-get-source
                "Load Scheme file: "
                scheme-prev-l/c-dir/file
                scheme-source-modes t)) ;; t because `load'
  ;; needs an exact name
  ;; Check to see if buffer needs saved
  (comint-check-source file-name) 
  (setq scheme-prev-l/c-dir/file (cons (file-name-directory file-name)
				                               (file-name-nondirectory file-name)))
  (comint-send-string (gambit-proc)
                      (concat "(load \"" file-name "\"\)\n"))
  (gambit-switch-to-repl t))

(defun gambit-send-region (start end)
  "Send the current region to `*gambit-buffer*'"
  (interactive "r")
  (comint-send-region (gambit-proc) start end)
  (comint-send-string (gambit-proc) "\n")
  (gambit-switch-to-repl t))

(defun gambit-send-last-sexp ()
  "Send the previous sexp to `*gambit-buffer*'."
  (interactive)
  (gambit-send-region (save-excursion (backward-sexp) (point)) (point)))

(defun gambit-send-definition ()
  "Send the current definition to `*gambit-buffer*'."
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (gambit-send-region (point) end))))

(defvar gambit-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\M-\C-x" #'gambit-send-definition)
    (define-key m "\C-x\C-e" #'gambit-send-last-sexp)
    (define-key m "\C-c\C-l" #'gambit-load-file)
    (define-key m "\C-c\C-k" #'gambit-compile-file)
    (scheme-mode-commands m)
    m))

(make-variable-buffer-local
 (defvar gambit-mode-string nil
   "Modeline indicator for `gambit-mode'."))

(defun gambit-mode--lighter ()
  (or gambit-mode-string
      (format " %s" (or "Gambit" "G"))))

(define-minor-mode gambit-mode
  "Toggle Gambit's mode.

With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode.

When Gambit mode is enabled, a host of nice utilities for
interacting with the Gambit REPL is at your disposal.
\\{gambit-mode-map}"
  :init-value nil
  :lighter (:eval (gambit-mode--lighter))
  :group 'gambit-mode
  :keymap gambit-mode-map)


(provide 'gambit-mode)

;; end of file