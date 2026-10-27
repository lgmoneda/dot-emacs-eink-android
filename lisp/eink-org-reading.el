;;; eink-org-reading.el --- Desktop-style Org for a monochrome tablet -*- lexical-binding: t; -*-

(require 'org)
(require 'org-indent)
(require 'face-remap)
(require 'cl-lib)
(declare-function org-modern-mode "org-modern" (&optional arg))

(defgroup eink-org-reading nil "Readable Org buffers on the tablet." :group 'org)
(defcustom eink-org-reading-fonts '("Iosevka BOOX" "Iosevka")
  "Preferred reading fonts.  Keep the device font if none is installed."
  :type '(repeat string))
(defcustom eink-org-reading-line-spacing 0.12
  "Extra line spacing in Org buffers, as a fraction of the default height."
  :type 'number)
(defcustom eink-org-image-max-width 750
  "Maximum preview width in pixels, also bounded by the current window."
  :type 'integer)
(defcustom eink-org-image-max-bytes (* 8 1024 1024)
  "Skip image files larger than this many bytes."
  :type 'integer)
(defcustom eink-org-image-limit 2
  "Maximum number of image previews shown by one command."
  :type 'integer)
(defvar eink-config-directory)
(defvar desktop-roam-directory)
(defvar eink-org-reading--visiting nil)
(defvar-local eink-org-reading--faces nil)
(defvar-local eink-org-reading--images nil)

(defun eink-org-reading--faces ()
  "Apply the desktop's type hierarchy without changing other buffers."
  (mapc #'face-remap-remove-relative eink-org-reading--faces)
  (setq eink-org-reading--faces nil)
  (let ((font (and (display-graphic-p)
                   (cl-find-if (lambda (family) (find-font (font-spec :family family)))
                               eink-org-reading-fonts))))
    (when font
      (push (face-remap-add-relative 'default :family font) eink-org-reading--faces)
      (push (face-remap-add-relative 'fixed-pitch :family font) eink-org-reading--faces))
    (dolist (spec '((org-document-title :height 1.8 :weight semi-bold)
                    (org-document-info :height 0.95)
                    (org-meta-line :height 0.9)
                    (org-document-info-keyword :height 0.9)
                    (org-property-value :height 0.9)
                    (org-block-begin-line :height 0.9 :overline t)
                    (org-block-end-line :height 0.9)
                    (org-ellipsis :underline nil :box nil)
                    (org-hide :foreground "white" :background "white")
                    (org-indent :foreground "white" :background "white")
                    (org-link :foreground "black" :underline t)
                    (org-drawer :height 0.9)
                    (org-quote :slant italic)
                    (org-code :weight semi-bold)
                    (org-verbatim :weight semi-bold)))
      (let ((attributes (copy-sequence (cdr spec))))
        (unless (plist-member attributes :foreground)
          (setq attributes (plist-put attributes :foreground "black")))
        (unless (plist-member attributes :background)
          (setq attributes (plist-put attributes :background 'unspecified)))
        (push (apply #'face-remap-add-relative (car spec) attributes)
              eink-org-reading--faces)))
    (dotimes (level 8)
      (push (face-remap-add-relative (intern (format "org-level-%d" (1+ level)))
                                    :foreground "black" :weight 'normal :height 1.0)
            eink-org-reading--faces))))

(defun eink-org-reading--modern ()
  "Enable only the useful monochrome parts of Org-modern, when installed."
  (when (require 'org-modern nil t)
    (setq-local org-modern-star 'replace
                org-modern-replace-stars '("◉" "○" "◈" "◇" "✳")
                org-modern-keyword nil org-modern-block-name nil
                org-modern-block-fringe nil org-modern-table nil
                org-modern-timestamp nil org-modern-priority nil
                org-modern-progress nil org-modern-horizontal-rule nil
                org-modern-todo nil org-modern-tag t
                org-modern-tag-faces '((t :foreground "black" :background "white" :weight normal))
                org-modern-label-border 1)
    (org-modern-mode 1)
    (push (face-remap-add-relative 'org-modern-label
                                   :foreground "black" :background "white"
                                   :box '(:line-width 1 :color "black"))
          eink-org-reading--faces)))

(defun eink-org-reading-setup ()
  "Style Org buffers without launching image previews or external processes."
  ;; Internal Org/Org-roam parsing buffers deliberately inhibit startup.
  (unless (and org-inhibit-startup (not eink-org-reading--visiting))
    (setq-local global-hl-line-mode nil
                line-spacing eink-org-reading-line-spacing
                org-hide-emphasis-markers t org-hide-leading-stars t
                org-ellipsis " ▼" org-cycle-separator-lines 0
                org-pretty-entities t org-fontify-quote-and-verse-blocks t
                org-src-fontify-natively t org-tags-column 0
                prettify-symbols-unprettify-at-point 'right-edge
                prettify-symbols-alist
                '(("#+TITLE:" . " ") ("#+title:" . " ")
                  ("#+subtitle:" . " ") ("#+author:" . "–")
                  ("#+AUTHOR:" . "–") ("#+Authors:" . "–")
                  ("#+filetags:" . "#") ("#+FILETAGS:" . "#")
                  ("#+STARTUP:" . "»") ("#+startup:" . "»")
                  (":PROPERTIES:" . "↩") (":properties:" . "↩")
                  ("#+begin_src" . "λ") ("#+end_src" . "src")
                  ("#+RESULTS:" . "»") ("#+results:" . "»")))
    (when (bound-and-true-p hl-line-mode) (hl-line-mode -1))
    (visual-line-mode 1)
    (org-indent-mode 1)
    (prettify-symbols-mode 1)
    (eink-org-reading--faces)
    (eink-org-reading--modern)
    (add-hook 'kill-buffer-hook #'eink-org-hide-images nil t)))

(defun eink-org-reading--startup (original &rest args)
  "Keep desktop STARTUP keywords from launching image/LaTeX work on visiting.
Restore outline folding ourselves; keywords in the note are not rewritten."
  (if (or org-inhibit-startup (not buffer-file-name))
      (apply original args)
    (let ((org-inhibit-startup t)
          (eink-org-reading--visiting t))
      (prog1 (apply original args)
        (org-cycle-set-startup-visibility)))))

(defun eink-org-hide-images ()
  "Remove this buffer's bounded image previews and release their image cache."
  (interactive)
  (dolist (overlay eink-org-reading--images)
    (when (and (overlayp overlay) (overlay-buffer overlay))
      (when (fboundp 'image-flush) (image-flush (overlay-get overlay 'display)))
      (delete-overlay overlay)))
  (setq eink-org-reading--images nil))

(defun eink-org-reading--image-file (path)
  "Resolve image PATH, including old links back into Dropbox's desktop roam."
  (let* ((path (org-link-unescape path))
         (local (and (not (file-remote-p path))
                     (expand-file-name path default-directory))))
    (cond
     ((and local (file-readable-p local)) local)
     ((and (bound-and-true-p desktop-roam-directory)
           (string-match "Dropbox/Agenda/roam/\\(.*\\)\\'" path))
      (let ((candidate (expand-file-name (match-string 1 path) desktop-roam-directory)))
        (when (and (file-in-directory-p candidate desktop-roam-directory)
                   (file-readable-p candidate)) candidate))))))

(defun eink-org-show-images (&optional subtree)
  "Show up to `eink-org-image-limit' images from the visible window.
With prefix SUBTREE, use the current subtree instead.  Only expanded text
is considered.  No remote images are fetched and source links stay intact."
  (interactive "P")
  (unless (derived-mode-p 'org-mode) (user-error "Open an Org note first"))
  (unless (display-images-p) (user-error "This Emacs display cannot show images"))
  (eink-org-hide-images)
  (let* ((range (if subtree
                    (save-excursion
                      (org-back-to-heading t)
                      (cons (point) (save-excursion (org-end-of-subtree t t))))
                  (cons (window-start) (window-end nil t))))
         (width (min eink-org-image-max-width
                     (floor (* 0.85 (window-body-width nil t)))))
         (count 0) (skipped 0))
    (save-excursion
      (goto-char (car range))
      (while (and (< count eink-org-image-limit)
                  (re-search-forward org-link-bracket-re (cdr range) t))
        (let* ((beg (match-beginning 0)) (end (match-end 0))
               (element (save-excursion (goto-char beg) (org-element-context)))
               (path (org-element-property :path element)))
          (when (and (eq (org-element-type element) 'link)
                     (equal (org-element-property :type element) "file")
                     path (not (invisible-p beg))
                     (string-match-p "\\.\\(?:png\\|jpe?g\\|webp\\|gif\\)\\'" (downcase path)))
            (let* ((file (eink-org-reading--image-file path))
                   (size (and file (file-attribute-size (file-attributes file)))))
              (if (or (not size) (> size eink-org-image-max-bytes))
                  (cl-incf skipped)
                (condition-case nil
                    (let* ((image (create-image file nil nil :max-width width
                                                :max-height width :scale 1.0))
                           (overlay (and image (make-overlay beg end))))
                      (when overlay
                        (overlay-put overlay 'display image)
                        (overlay-put overlay 'before-string
                                     (propertize " " 'display
                                                 `(space :align-to
                                                         (- center (0.5 . ,image)))))
                        (overlay-put overlay 'modification-hooks
                                     (list (lambda (ov &rest _) (delete-overlay ov))))
                        (push overlay eink-org-reading--images)
                        (cl-incf count)))
                  (error (cl-incf skipped)))))))))
    (if (and (= count 0) (= skipped 0))
        (message "No visible image links; expand the heading or image drawer, then retry")
      (message "%d image(s) shown; %d missing, oversized, or unsupported. C-c v h hides them"
               count skipped))))

(defun eink-install-reading-fonts ()
  "Copy the bundled compact Iosevka fonts to native Android Emacs's ~/fonts/."
  (interactive)
  (unless (eq system-type 'android)
    (user-error "This installer is for native Android Emacs; install the TTFs with your OS"))
  (let ((source (expand-file-name "fonts/" eink-config-directory))
        (target (expand-file-name "~/fonts/")))
    (unless (file-directory-p source)
      (user-error "Copy the repository fonts/ folder alongside init.el first"))
    (make-directory target t)
    (dolist (name '("IosevkaBOOX-Regular.ttf" "IosevkaBOOX-Italic.ttf"
                    "IosevkaBOOX-Semibold.ttf" "IosevkaBOOX-SemiboldItalic.ttf" "OFL.txt"))
      (copy-file (expand-file-name name source) (expand-file-name name target) t))
    (message "Reading fonts installed. Restart Emacs to discover them")))

(setq org-startup-folded t
      org-startup-with-inline-images nil org-startup-with-latex-preview nil)
(add-hook 'org-mode-hook #'eink-org-reading-setup)
(advice-add 'org-mode :around #'eink-org-reading--startup)
(define-key org-mode-map (kbd "C-c v i") #'eink-org-show-images)
(define-key org-mode-map (kbd "C-c v h") #'eink-org-hide-images)

(provide 'eink-org-reading)
;;; eink-org-reading.el ends here
