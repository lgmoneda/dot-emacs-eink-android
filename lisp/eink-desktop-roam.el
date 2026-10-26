;;; eink-desktop-roam.el --- Read desktop notes without indexing -*- lexical-binding: t; -*-

(require 'org)
(require 'org-id)
(require 'json)
(require 'cl-lib)

(defgroup eink-desktop-roam nil "Read the synced desktop note library." :group 'org)
(defcustom desktop-roam-directory (expand-file-name "roam" org-directory)
  "Tablet copy of the desktop roam folder, separate from Org-roam's index."
  :type 'directory)
(defcustom desktop-roam-catalog-file
  (expand-file-name "desktop-org-roam-catalog/catalog.json" org-directory)
  "Desktop-generated catalog.  Reading it never scans the note library."
  :type 'file)
(defcustom desktop-roam-read-only t
  "Open desktop-library notes read-only.  Use BOOX notes for writing."
  :type 'boolean)

(defvar desktop-roam--stamp nil)
(defvar desktop-roam--nodes nil)
(defvar desktop-roam--candidates nil)

(defun desktop-roam--load (&optional optional)
  "Load the catalog when changed.  Missing catalogs are allowed if OPTIONAL."
  (let ((attributes (file-attributes desktop-roam-catalog-file)))
    (if (not attributes)
        (progn
          (setq desktop-roam--stamp nil desktop-roam--nodes nil
                desktop-roam--candidates nil)
          (unless optional
            (user-error "Sync the desktop catalog first: %s" desktop-roam-catalog-file)))
      (let ((stamp (list desktop-roam-catalog-file desktop-roam-directory
                         (file-attribute-modification-time attributes)
                         (file-attribute-size attributes))))
        (unless (equal stamp desktop-roam--stamp)
          (let* ((data (with-temp-buffer
                         (insert-file-contents desktop-roam-catalog-file)
                         (json-parse-buffer :object-type 'alist :array-type 'list)))
                 (nodes (make-hash-table :test #'equal))
                 (labels (make-hash-table :test #'equal))
                 (candidates nil))
            (unless (equal (alist-get 'version data) 1)
              (user-error "Unsupported desktop catalog version"))
            (dolist (entry (alist-get 'nodes data))
              (let ((id (alist-get 'id entry)) (title (alist-get 'title entry))
                    (file (alist-get 'file entry)) (level (alist-get 'level entry))
                    (aliases (alist-get 'aliases entry))
                    (citekeys (alist-get 'citekeys entry)))
                (unless (and (stringp id) (not (string-empty-p id))
                             (stringp title) (stringp file)
                             (not (file-name-absolute-p file))
                             (not (member ".." (split-string file "/")))
                             (string-suffix-p ".org" file)
                             (integerp level) (>= level 0)
                             (listp aliases) (cl-every #'stringp aliases)
                             (listp citekeys) (cl-every #'stringp citekeys)
                             (not (gethash id nodes)))
                  (user-error "Invalid desktop catalog entry"))
                (puthash id entry nodes)
                (dolist (name (delete-dups (cons title (copy-sequence aliases))))
                  (let* ((base (format "%s  [%s]" name file))
                         (label base)
                         (number 1))
                    (while (gethash label labels)
                      (setq number (1+ number)
                            label (format "%s (%d)" base number)))
                    (puthash label t labels)
                    (push (cons label entry) candidates)))))
            ;; Replace the cached data only after validating the entire export.
            (setq desktop-roam--nodes nodes
                  desktop-roam--candidates (nreverse candidates)
                  desktop-roam--stamp stamp)))))))

(defun desktop-roam-reload-catalog ()
  "Reload the synced catalog without scanning any note files."
  (interactive)
  (setq desktop-roam--stamp nil)
  (desktop-roam--load)
  (message "Loaded %d desktop nodes" (hash-table-count desktop-roam--nodes)))

(defun desktop-roam--read (&optional files-only)
  "Choose a desktop node, or a file-level node if FILES-ONLY."
  (desktop-roam--load)
  (let* ((candidates (if files-only
                         (cl-remove-if-not
                          (lambda (candidate) (= (alist-get 'level (cdr candidate)) 0))
                          desktop-roam--candidates)
                       desktop-roam--candidates)))
    (unless candidates (user-error "No matching notes in the desktop catalog"))
    (cdr (assoc (completing-read "Desktop note: " candidates nil t)
                candidates))))

(defun desktop-roam--file (entry)
  "Resolve ENTRY to an existing local Org file inside the desktop library."
  (let ((file (expand-file-name (alist-get 'file entry) desktop-roam-directory)))
    (unless (file-in-directory-p file desktop-roam-directory)
      (user-error "Catalog path is outside the desktop library: %s" file))
    (unless (file-readable-p file)
      (user-error "Desktop note is not synced locally: %s" file))
    file))

(defun desktop-roam--find (entry &optional markerp)
  "Find ENTRY's ID in its one local file, returning an Org ID location."
  (let* ((file (desktop-roam--file entry))
         (buffer (find-file-noselect file)))
    (with-current-buffer buffer
      (when desktop-roam-read-only (read-only-mode 1)))
    (or (org-id-find-id-in-file (alist-get 'id entry) file markerp)
        (user-error "ID missing from synced note; refresh notes and catalog: %s" file))))

(defun desktop-roam-open-node ()
  "Search desktop titles and aliases, then open the matching node read-only."
  (interactive)
  (let ((marker (desktop-roam--find (desktop-roam--read) t)))
    (pop-to-buffer (marker-buffer marker))
    (goto-char marker)
    (org-fold-show-context 'link-search)
    (set-marker marker nil)))

(defun desktop-roam-open-file ()
  "Search file-level desktop titles and open the selected file read-only."
  (interactive)
  (find-file (desktop-roam--file (desktop-roam--read t)))
  (when desktop-roam-read-only (read-only-mode 1)))

(defun desktop-roam-insert-link ()
  "Insert a standard ID link to a desktop title or alias, without indexing."
  (interactive)
  (unless (derived-mode-p 'org-mode) (user-error "Use this command in an Org buffer"))
  (barf-if-buffer-read-only)
  (let ((entry (desktop-roam--read)))
    (insert (org-link-make-string (concat "id:" (alist-get 'id entry))
                                  (alist-get 'title entry)))))

(defun desktop-roam--id-find (original id &optional markerp)
  "Resolve catalog IDs before ORIGINAL, even before Org-roam is loaded."
  (desktop-roam--load t)
  (let ((entry (and desktop-roam--nodes
                    (gethash (format "%s" id) desktop-roam--nodes))))
    (if entry (desktop-roam--find entry markerp)
      (funcall original id markerp))))

;; Run outside Org-roam's depth-0 advice, so desktop links never query its DB.
(advice-add 'org-id-find :around #'desktop-roam--id-find '((depth . -100)))
(global-set-key (kbd "C-c d f") #'desktop-roam-open-node)
(global-set-key (kbd "C-c d i") #'desktop-roam-insert-link)

(provide 'eink-desktop-roam)
;;; eink-desktop-roam.el ends here
