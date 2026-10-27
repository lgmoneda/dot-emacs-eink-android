;;; early-init.el --- Quiet startup for e-ink -*- lexical-binding: t; -*-

;; The Android app must already have access to the Termux environment.
(when (eq system-type 'android)
  (let ((termux-bin "/data/data/com.termux/files/usr/bin"))
    (setenv "PATH"
            (concat termux-bin ":" (getenv "PATH")))
    (add-to-list 'exec-path termux-bin)))

(setq package-enable-at-startup nil
      frame-inhibit-implied-resize t)
(add-to-list 'default-frame-alist '(background-color . "white"))
(add-to-list 'default-frame-alist '(foreground-color . "black"))
(add-to-list 'default-frame-alist '(cursor-color . "black"))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))
(add-to-list 'default-frame-alist '(menu-bar-lines . 0))

;;; early-init.el ends here
