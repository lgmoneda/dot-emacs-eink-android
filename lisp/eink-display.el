;;; eink-display.el --- Monochrome display -*- lexical-binding: t; -*-

(setq inhibit-startup-screen t
      initial-scratch-message ""
      ring-bell-function #'ignore
      visible-bell nil
      scroll-conservatively 101
      scroll-preserve-screen-position t
      auto-window-vscroll nil
      mouse-wheel-progressive-speed nil
      use-dialog-box nil)
(dolist (mode '(tool-bar-mode scroll-bar-mode blink-cursor-mode))
  (when (fboundp mode) (funcall mode -1)))
;; Keep menus and touch input available for tablet use.
(setq-default cursor-type 'box
              line-spacing 0
              indicate-empty-lines nil)

(deftheme eink "Black and white, with no color-dependent syntax.")
(custom-theme-set-faces
 'eink
 '(default ((t (:foreground "black" :background "white" :height 160))))
 '(cursor ((t (:background "black"))))
 '(region ((t (:foreground "white" :background "black"))))
 '(highlight ((t (:foreground "white" :background "black"))))
 '(minibuffer-prompt ((t (:foreground "black" :weight bold))))
 '(mode-line ((t (:foreground "white" :background "black" :box nil))))
 '(mode-line-inactive ((t (:foreground "black" :background "white" :box t))))
 '(fringe ((t (:foreground "black" :background "white"))))
 '(link ((t (:foreground "black" :underline t))))
 '(shadow ((t (:foreground "black" :weight normal))))
 '(isearch ((t (:foreground "white" :background "black"))))
 '(lazy-highlight ((t (:foreground "black" :background "white" :underline t))))
 '(show-paren-match ((t (:foreground "black" :background "white" :weight bold :underline t)))))
(dolist (face '(font-lock-builtin-face font-lock-comment-face
                font-lock-comment-delimiter-face font-lock-constant-face
                font-lock-function-name-face font-lock-keyword-face
                font-lock-string-face font-lock-type-face
                font-lock-variable-name-face font-lock-warning-face))
  (custom-theme-set-faces
   'eink `(,face ((t (:foreground "black" :background unspecified))))))
;; Match faces must not supply colors: Vertico adds its selected-row face
;; underneath them. An unspecified underline color follows the text color.
(dolist (face '(orderless-match-face-0 orderless-match-face-1
                orderless-match-face-2 orderless-match-face-3
                completions-common-part))
  (custom-theme-set-faces
   'eink `(,face ((t (:inherit nil :foreground unspecified
                     :background unspecified :underline t))))))
(enable-theme 'eink)

(with-eval-after-load 'org
  (dolist (face '(org-level-1 org-level-2 org-level-3 org-level-4
                  org-level-5 org-level-6 org-level-7 org-level-8
                  org-todo org-done org-date org-special-keyword org-meta-line))
    (set-face-attribute face nil :foreground "black" :background 'unspecified))
  (set-face-attribute 'org-block nil :background 'unspecified))

(provide 'eink-display)
