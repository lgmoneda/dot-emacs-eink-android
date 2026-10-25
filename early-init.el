;;; early-init.el --- Quiet startup for e-ink -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil
      frame-inhibit-implied-resize t)
(add-to-list 'default-frame-alist '(background-color . "white"))
(add-to-list 'default-frame-alist '(foreground-color . "black"))
(add-to-list 'default-frame-alist '(cursor-color . "black"))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))

;;; early-init.el ends here
