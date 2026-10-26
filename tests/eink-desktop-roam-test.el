;;; eink-desktop-roam-test.el --- Catalog navigation tests -*- lexical-binding: t; -*-
(require 'ert)
(require 'cl-lib)
(setq org-directory temporary-file-directory)
(require 'eink-desktop-roam)

(ert-deftest desktop-roam-catalog-navigation ()
  (let* ((root (make-temp-file "desktop-catalog-test-" t))
         (desktop-roam-directory (expand-file-name "roam" root))
         (desktop-roam-catalog-file (expand-file-name "catalog.json" root))
         (desktop-roam--stamp nil) (desktop-roam--nodes nil)
         (desktop-roam--candidates nil)
         (file (expand-file-name "nested/note.org" desktop-roam-directory))
         (entries '(((id . "file-id") (title . "Shared title")
                     (aliases . ["Other title"]) (file . "nested/note.org") (level . 0))
                    ((id . "heading-id") (title . "Shared title")
                     (aliases . []) (file . "nested/note.org") (level . 1)))))
    (unwind-protect
        (progn
          (make-directory (file-name-directory file) t)
          (with-temp-file file
            (insert ":PROPERTIES:\n:ID: file-id\n:END:\n#+title: Shared title\n\nExtra text shifts positions.\n* Heading\n:PROPERTIES:\n:ID: heading-id\n:END:\nContent\n"))
          (with-temp-file desktop-roam-catalog-file
            (insert (json-encode `((version . 1) (nodes . ,(vconcat entries))))))
          (desktop-roam--load)
          (should (= 2 (hash-table-count desktop-roam--nodes)))
          (should (= 3 (length desktop-roam--candidates)))
          ;; No database access or recursive file scan, including ordinary ID links.
          (cl-letf (((symbol-function 'org-roam-db-query)
                     (lambda (&rest _) (ert-fail "Queried Org-roam")))
                    ((symbol-function 'directory-files-recursively)
                     (lambda (&rest _) (ert-fail "Scanned library"))))
            (let ((marker (org-id-find "heading-id" t)))
              (should (markerp marker))
              (with-current-buffer (marker-buffer marker)
                (should buffer-read-only)
                (goto-char marker)
                (should (looking-at "\\* Heading")))
              (set-marker marker nil))
            ;; The advice must also precede Org-roam when it is loaded later.
            (let ((fallback (lambda (&rest _) (ert-fail "Org-roam advice ran"))))
              (unwind-protect
                  (progn (advice-add 'org-id-find :before-until fallback)
                         (should (consp (org-id-find "file-id"))))
                (advice-remove 'org-id-find fallback)))
            (cl-letf (((symbol-function 'desktop-roam--read)
                       (lambda (&rest _) (cadr entries))))
              (with-temp-buffer
                (org-mode)
                (desktop-roam-insert-link)
                (should (equal (buffer-string) "[[id:heading-id][Shared title]]")))))
          ;; Unknown IDs still delegate to normal Org handling.
          (should (eq (desktop-roam--id-find (lambda (&rest _) 'delegated)
                                             "boox-id") 'delegated))
          (when-let* ((buffer (get-file-buffer file))) (kill-buffer buffer))
          (delete-file file)
          (should-error (org-id-find "file-id") :type 'user-error))
      (when-let* ((buffer (get-file-buffer file))) (kill-buffer buffer))
      (delete-directory root t))))

(ert-deftest desktop-roam-rejects-traversal ()
  (let* ((root (make-temp-file "catalog-invalid-" t))
         (desktop-roam-catalog-file (expand-file-name "catalog.json" root))
         (desktop-roam--stamp nil) (desktop-roam--nodes nil))
    (unwind-protect
        (progn
          (with-temp-file desktop-roam-catalog-file
            (insert "{\"version\":1,\"nodes\":[{\"id\":\"bad\",\"title\":\"Bad\",\"file\":\"../outside.org\",\"level\":0,\"aliases\":[]}]}"))
          (should-error (desktop-roam--load) :type 'user-error)
          (should-not desktop-roam--nodes))
      (delete-directory root t))))
