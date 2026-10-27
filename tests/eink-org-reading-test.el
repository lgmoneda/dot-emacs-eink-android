;;; eink-org-reading-test.el --- Reading style behavior -*- lexical-binding: t; -*-
(require 'ert)
(require 'cl-lib)
(require 'eink-org-reading)
(defvar desktop-roam-directory nil)

(ert-deftest eink-org-reading-keeps-note-text-and-suppresses-startup-previews ()
  (let* ((file (make-temp-file "eink-reading-" nil ".org"))
         (content "#+title: A reading note\n#+STARTUP: linkpreviews inlineimages latexpreview\n\n* Heading\nBody with *bold* and /italic/.\n** Child\nMore text\n"))
    (unwind-protect
        (progn
          (with-temp-file file (insert content))
          (cl-letf (((symbol-function 'org-display-inline-images)
                     (lambda (&rest _) (ert-fail "Automatic inline images")))
                    ((symbol-function 'org-link-preview)
                     (lambda (&rest _) (ert-fail "Automatic link previews")))
                    ((symbol-function 'org-latex-preview)
                     (lambda (&rest _) (ert-fail "Automatic LaTeX preview"))))
            (with-current-buffer (find-file-noselect file)
              (should org-indent-mode)
              (should visual-line-mode)
              (should org-hide-emphasis-markers)
              (should (equal org-ellipsis " ▼"))
              (should (equal content (buffer-substring-no-properties (point-min) (point-max))))
              (should-not (buffer-modified-p))
              (let ((count (length face-remapping-alist)))
                (eink-org-reading-setup)
                (should (= count (length face-remapping-alist)))))))
      (when-let* ((buffer (get-file-buffer file))) (kill-buffer buffer))
      (delete-file file))))

(ert-deftest eink-org-reading-remaps-desktop-image-paths-without-rewriting ()
  (let* ((desktop-roam-directory (make-temp-file "reading-library-" t))
         (file (expand-file-name "resources/portrait.png" desktop-roam-directory)))
    (unwind-protect
        (progn
          (make-directory (file-name-directory file) t)
          (with-temp-file file (insert "placeholder"))
          (should (file-equal-p
                   (eink-org-reading--image-file
                    "../../../../../Dropbox/Agenda/roam/resources/portrait.png") file))
          (should-not (eink-org-reading--image-file "/ssh:host:/remote.png"))
          (should-not (eink-org-reading--image-file
                       "../../Dropbox/Agenda/roam/../../outside.png")))
      (delete-directory desktop-roam-directory t))))

(ert-deftest eink-org-reading-internal-parsers-skip-decoration ()
  (with-temp-buffer
    (let ((org-inhibit-startup t)) (org-mode))
    (should-not eink-org-reading--faces)
    (should-not (bound-and-true-p org-modern-mode))))


(ert-deftest eink-org-reading-image-previews-are-bounded-and-display-only ()
  (let* ((root (make-temp-file "reading-images-" t))
         (eink-org-image-limit 2)
         (eink-org-image-max-bytes 1024)
         (created 0))
    (unwind-protect
        (with-temp-buffer
          (setq default-directory (file-name-as-directory root))
          (dolist (name '("a.png" "b.png" "c.png"))
            (with-temp-file (expand-file-name name root) (insert "image")))
          (insert "* Pictures\n[[file:a.png]]\n[[file:b.png]]\n[[file:c.png]]\n")
          (org-mode)
          (let ((original (buffer-string)))
            (cl-letf (((symbol-function 'display-images-p) (lambda (&rest _) t))
                      ((symbol-function 'create-image)
                       (lambda (&rest _) (cl-incf created) '(image :type png :file "fake")))
                      ((symbol-function 'image-flush) #'ignore)
                      ((symbol-function 'window-body-width) (lambda (&rest _) 800)))
              (goto-char (point-min))
              (org-fold-show-subtree)
              (eink-org-show-images t)
              (should (= created 2))
              (should (= (length eink-org-reading--images) 2))
              (should (equal original (buffer-string)))
              (setq eink-org-image-max-bytes 1)
              (goto-char (point-min))
              (eink-org-show-images t)
              (should (= created 2))
              (should-not eink-org-reading--images))))
      (delete-directory root t))))
