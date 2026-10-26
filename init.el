;;; init.el --- Small Android e-ink configuration -*- lexical-binding: t; -*-

(when (version< emacs-version "29.1")
  (error "This configuration requires Emacs 29.1 or newer"))

(defconst eink-config-directory
  (file-name-directory (or load-file-name buffer-file-name)))
(defconst eink-state-directory
  (expand-file-name "var/" user-emacs-directory))
(make-directory eink-state-directory t)
(add-to-list 'load-path (expand-file-name "lisp/" eink-config-directory))

(require 'package)
(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))
(package-initialize)
(require 'use-package)
(setq use-package-always-ensure nil)

(defconst eink-packages
  '(vertico orderless consult marginalia embark avy expand-region
    multiple-cursors goto-chg ace-window default-text-scale agent-shell org-super-agenda
    org-roam)
  "Small desktop editing subset, installed only on explicit request.")

(defun eink-install-packages ()
  "Install missing editor packages. Requires internet; then restart Emacs."
  (interactive)
  (package-refresh-contents)
  (dolist (package eink-packages)
    (unless (package-installed-p package)
      (package-install package)))
  (message "Editor packages installed. Restart Emacs."))

(require 'eink-display)
(require 'eink-editor)
(require 'eink-productivity)
(require 'eink-agent)
(require 'eink-org)
(require 'eink-roam)
(require 'eink-desktop-roam)

;; Private device paths and preferences belong in these ignored files.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t 'nomessage)
(load (expand-file-name "local.el" user-emacs-directory) t 'nomessage)

;;; init.el ends here
