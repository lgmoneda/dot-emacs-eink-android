;;; eink-productivity.el --- Small desktop package subset -*- lexical-binding: t; -*-

;; Missing packages are skipped so a fresh offline launch remains usable.
(use-package vertico
  :if (locate-library "vertico")
  :init (setq vertico-count 8 vertico-resize nil vertico-cycle t)
  :config
  (vertico-mode 1)
  (require 'vertico-directory)
  (define-key vertico-map (kbd "RET") #'vertico-directory-enter)
  (define-key vertico-map (kbd "DEL") #'vertico-directory-delete-char)
  (define-key vertico-map (kbd "M-DEL") #'vertico-directory-delete-word)
  (add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)
  (set-face-attribute 'vertico-current nil :foreground "white" :background "black"))

(use-package orderless
  :if (locate-library "orderless")
  :demand t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))
        orderless-matching-styles '(orderless-literal orderless-regexp orderless-initialism)
        completion-ignore-case t
        read-buffer-completion-ignore-case t
        read-file-name-completion-ignore-case t))

(use-package marginalia
  :if (locate-library "marginalia")
  :demand t
  :bind (:map minibuffer-local-map ("M-A" . marginalia-cycle))
  :config (marginalia-mode 1))

(use-package consult
  :if (locate-library "consult")
  :init (setq consult-preview-key "M-." consult-narrow-key "<")
  :bind (("C-x b" . consult-buffer)
         ("C-x 4 b" . consult-buffer-other-window)
         ("C-x r b" . consult-bookmark)
         ("C-x p b" . consult-project-buffer)
         ("M-y" . consult-yank-pop)
         ("C-c h" . consult-history)
         ("M-g g" . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g o" . consult-outline)
         ("M-g i" . consult-imenu)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s r" . consult-ripgrep)
         ("M-s g" . consult-grep)
         ("M-s d" . consult-find)
         ("M-s e" . consult-isearch-history)
         :map minibuffer-local-map
         ("M-r" . consult-history)))

(use-package embark
  :if (locate-library "embark")
  :bind (("C-." . embark-act) ("C-;" . embark-dwim) ("C-h B" . embark-bindings)))
(use-package avy
  :if (locate-library "avy")
  :bind (("C-:" . avy-goto-char-timer) ("M-z" . avy-goto-char)
         ("M-s s" . avy-goto-char) ("C-?" . avy-goto-line))
  :config
  (dolist (face '(avy-lead-face avy-lead-face-0 avy-lead-face-1 avy-lead-face-2))
    (set-face-attribute face nil :foreground "white" :background "black" :weight 'bold)))
(use-package expand-region
  :if (locate-library "expand-region")
  :bind (("C-+" . er/expand-region) ("C-=" . er/mark-word)))
(use-package multiple-cursors
  :if (locate-library "multiple-cursors")
  :bind (("C->" . mc/mark-next-like-this) ("C-<" . mc/mark-previous-like-this)
         ("C-c C->" . mc/mark-all-like-this) ("C-x , m" . mc/edit-lines)
         ("C-x , n" . mc/edit-ends-of-lines))
  :config
  (setq mc/list-file (expand-file-name "mc-lists.el" eink-state-directory))
  (add-to-list 'mc/cmds-to-run-for-all 'org-self-insert-command)
  (setq mc/cmds-to-run-once (delq 'org-self-insert-command mc/cmds-to-run-once)))
(use-package goto-chg
  :if (locate-library "goto-chg")
  :bind (("M-[" . goto-last-change) ("M-]" . goto-last-change-reverse)))
(use-package ace-window
  :if (locate-library "ace-window")
  :bind ("M-s w" . ace-window)
  :init (setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :config (set-face-attribute 'aw-leading-char-face nil
                             :foreground "black" :background "white" :weight 'bold))
(use-package default-text-scale
  :if (locate-library "default-text-scale")
  :bind (("C-M-=" . default-text-scale-increase)
         ("C-M--" . default-text-scale-decrease)))

(provide 'eink-productivity)
