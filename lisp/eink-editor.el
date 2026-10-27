;;; eink-editor.el --- Familiar editing without background work -*- lexical-binding: t; -*-

(prefer-coding-system 'utf-8-unix)
(setq-default fill-column 80 indent-tabs-mode nil truncate-lines nil)
(setq require-final-newline t
      set-mark-command-repeat-pop t
      save-interprogram-paste-before-kill t
      history-length 200
      savehist-file (expand-file-name "history" eink-state-directory)
      save-place-file (expand-file-name "places" eink-state-directory)
      backup-directory-alist `(("." . ,(expand-file-name "backups/" eink-state-directory)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" eink-state-directory) t))
      backup-by-copying t
      version-control t
      kept-new-versions 3
      kept-old-versions 1
      delete-old-versions t)
(make-directory (expand-file-name "backups/" eink-state-directory) t)
(make-directory (expand-file-name "auto-save/" eink-state-directory) t)
(savehist-mode 1)
(save-place-mode 1)
(delete-selection-mode 1)
(transient-mark-mode 1)
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)
(add-hook 'text-mode-hook #'visual-line-mode)

(defun eink-copy-word ()
  "Copy the word at point."
  (interactive)
  (if-let* ((word (thing-at-point 'word t)))
      (kill-new word)
    (user-error "No word at point")))
(defun eink-copy-line ()
  "Copy the current line without its newline."
  (interactive)
  (kill-ring-save (line-beginning-position) (line-end-position)))
(defun eink-newline ()
  "Insert an indented newline at the end of the current line."
  (interactive) (end-of-line) (newline-and-indent))
(defun eink-split-below ()
  "Split below and select the new window."
  (interactive) (select-window (split-window-below)))
(defun eink-split-right ()
  "Split right and select the new window."
  (interactive) (select-window (split-window-right)))
(defun eink-previous-window ()
  "Select the previous window."
  (interactive) (other-window -1))
(defun eink-next-window ()
  "Select the next window."
  (interactive) (other-window 1))
(defun eink-scratch ()
  "Switch to the scratch buffer."
  (interactive) (switch-to-buffer (get-buffer-create "*scratch*")))
(defun eink-open-init ()
  "Open this configuration's init file."
  (interactive) (find-file (expand-file-name "init.el" eink-config-directory)))

(defun pull-eink-repo ()
  "Pull configuration updates asynchronously and show Git output.
Use a fast-forward pull in `eink-config-directory'. Restart Emacs after
a successful update to load the new configuration."
  (interactive)
  (require 'compile)
  (let ((default-directory (file-name-as-directory eink-config-directory))
        (git (executable-find "git"))
        (buffer (get-buffer "*eink-repo-update*")))
    (unless git
      (user-error "Git is unavailable; install it in Termux with pkg install git"))
    (unless (file-exists-p (expand-file-name ".git" default-directory))
      (user-error "Config directory is not a Git checkout: %s" default-directory))
    (when (and buffer (process-live-p (get-buffer-process buffer)))
      (user-error "A configuration update is already running"))
    (compilation-start
     (concat (shell-quote-argument git) " pull --ff-only")
     'compilation-mode (lambda (_) "*eink-repo-update*"))))

(dolist (binding '(("s-k" . kill-current-buffer) ("C-c w" . eink-copy-word) ("C-c l" . eink-copy-line)
                   ("C-c s" . eink-scratch) ("<C-return>" . eink-newline)
                   ("C-x 2" . eink-split-below) ("C-x 3" . eink-split-right)
                   ("C-<tab>" . eink-next-window) ("C-S-<tab>" . eink-previous-window)
                   ("C-8" . switch-to-prev-buffer) ("C-9" . switch-to-next-buffer)
                   ("C-7" . bury-buffer) ("C-0" . other-frame)
                   ("C-*" . isearch-forward-symbol-at-point) ("<f6>" . eink-open-init)))
  (global-set-key (kbd (car binding)) (cdr binding)))

(provide 'eink-editor)
