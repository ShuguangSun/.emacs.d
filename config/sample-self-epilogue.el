;;;; -*- lexical-binding:t -*-
;;;;
;; sample-self-epilogue.el: specify the epilogue of yourself
;;   should be run on the end of Emacs init 
;;
;;;;



(message "#self epilogue ...")


;; (require 'financial)
;; (require 'shells)
;; (require 'eshells)
;; (require 'pythons)


(with-eval-after-load 'org
  ;; define key bindings after `org-mode' had been loaded
  (global-set-key (kbd "C-c o a") 'org-agenda)
  (global-set-key (kbd "C-c o c") 'org-capture))


(comment (setq% enable-local-variables :all files))
(comment (setq% compilation-scroll-output t compile))

(comment
 ;; using etags to view Emacs's source code: C and Elisp
 ;; support any platform
 (when (require 'tags)
   (version-supported-if
       <= 25.2
       (setq source-directory "/opt/open/emacs-25/")
     (setq source-directory "/opt/open/emacs-22/"))))

(comment
 ;; if current Emacs session support `semantic-mode'
 ;; using semantic to view and editing any supported code
 ;; correctly and more faster
 ;; `system-cc-include' support any platform
 (when-fn% semantic-mode nil
	 (add-hook
		'after-init-hook
		(lambda ()
			(semantic-mode t)
			(eval-when-compile (require 'semantic))
			(eval-when-compile (require 'cc))
			(semantic-reset-system-include 'c-mode)
			(global-semantic-idle-summary-mode)
			(dolist (x (system-cc-include t))
				(semantic-add-system-include x 'c-mode))
			(global-set-key (kbd "C-c , f") #'semantic-ia-fast-jump)
			(comment)
			(setq% semanticdb-project-roots
						 `("/opt/apps/c" ,source-directory) semantic))
		t)))


(comment
 ;; receive mail
 (require 'rmail)
 (setq rmail-primary-inbox-list '("<protocal://user:passwd@host>"))
 (setq% rmail-remote-password-required t rmail))

(comment
 ;; send mail
 (require 'sendmail)
 (setq send-mail-function 'smtpmail-send-it)
 (setq smtpmail-smtp-server "<smtp-server>")
 (setq smtpmail-smtp-server 587))
