;;;; -*- lexical-binding:t -*-
;;;;
;; More reasonable Emacs on MacOS, Windows and Linux
;; https://github.com/junjiemars/.emacs.d
;;;;
;; cc.el
;;;;


(platform-supported-when windows-nt
	
	(defun check-vcvarsall-bat ()
		(let* ((pfroot (windows-nt-posix-path (getenv "PROGRAMFILES")))
					 (vswhere (concat
										 pfroot
										 " (x86)/Microsoft Visual Studio/Installer/vswhere.exe")))
			(or (let* ((cmd (shell-command* (shell-quote-argument vswhere)
												"-nologo -latest -property installationPath"))
								 (vsroot (and (zerop (car cmd))
															(concat
															 (string-trim> (cdr cmd))
															 "/VC/Auxiliary/Build/vcvarsall.bat"))))
						(when (file-exists-p vsroot) vsroot))
					(let* ((mvs (car (directory-files
														(concat pfroot
																		" (x86)/Microsoft Visual Studio")
														t "[0-9]+" #'string-greaterp)))
								 (vsroot (concat
													mvs
													"/BuildTools/VC/Auxiliary/Build/vcvarsall.bat")))
						(when (file-exists-p vsroot)
							(windows-nt-posix-path vsroot)))))))


(platform-supported-when windows-nt
  
  (defun make-cc-env-bat ()
    (let ((vcvarsall (check-vcvarsall-bat))
          (arch (downcase (getenv "PROCESSOR_ARCHITECTURE")))
          (where (expand-file-name (v-home% "config/" ".cc-env.bat"))))
      (when vcvarsall
        (save-str-to-file 
         (concat
          "@echo off\n"
          "cd /d \"" (file-name-directory vcvarsall) "\"\n"
          "call vcvarsall.bat " arch "\n"
          "echo \"%INCLUDE%\"\n")
				 where)))))


(platform-supported-if windows-nt
		
    (defun check-cc-include ()
      (let ((cmd (shell-command* (make-cc-env-bat))))
        (when (zerop (car cmd))
					(var->paths
					 (car (nreverse 
								 (split-string* (cdr cmd) "\n" t "\"")))))))

  (defun check-cc-include ()
		(let ((cmd (shell-command* "echo '' | cc -v -E 2>&1 >/dev/null -")))
			(when (zerop (car cmd))
				(take-while
				 (lambda (p)
					 (string-match "End of search list." p))
				 (drop-while
					(lambda (p)
						(string-match "#include <...> search starts here:" p))
					(split-string* (cdr cmd) "\n" t "[ \t\n]")))))))


(defvar system-cc-include nil
  "The system include paths used by C compiler.

This should be set with `system-cc-include'")


(defun system-cc-include (&optional cached)
  "Returns a list of system include directories. 

Load `system-cc-include' from file when CACHED is t, 
otherwise check cc include on the fly."
  (let ((c (v-home% "config/" ".cc-inc.el")))
    (if (and cached (file-exists-p (concat c "c")))
        (progn
          (load (concat c "c"))
          system-cc-include)
      (let ((paths
             (platform-supported-if windows-nt
                 (check-cc-include)
               (platform-supported-if darwin
                   (mapcar (lambda (x)
                             (string-trim> x " (framework directory)"))
                           (check-cc-include))
                 (check-cc-include)))))
        (when (save-sexp-to-file
               `(setq system-cc-include ',paths) c)
          (byte-compile-file c))
        (setq system-cc-include paths)))))


(provide 'cc)
