;;; eink-research.el --- Lightweight bibliography and paper notes -*- lexical-binding: t; -*-

(require 'org)
(require 'org-id)
(require 'oc)
(require 'cl-lib)
(require 'browse-url)
(require 'eink-desktop-roam)

(declare-function citar-register-notes-source "citar" (name config))
(declare-function citar-open "citar" (citekeys))
(declare-function citar-select-ref "citar" (&rest args))
(declare-function citar-create-note "citar" (key &optional entry))
(declare-function citar-get-value "citar" (field key-or-entry))
(declare-function citar-file--parser-default "citar-file" (file-field))
(declare-function citar-file--parser-triplet "citar-file" (file-field))
(declare-function citar-file--get-notes "citar-file" (&optional keys))
(declare-function eink-roam-setup "eink-roam" (&optional allow-missing-index))

(defgroup eink-research nil "Read papers and cite them in BOOX notes." :group 'org)
(defcustom eink-research-directory "/storage/emulated/0/Documents/Research/"
  "Tablet copy of ~/Dropbox/Research/."
  :type 'directory)
(defcustom eink-research-bibliography-file
  (expand-file-name "library.bib" eink-research-directory)
  "Synced BibTeX bibliography."
  :type 'file)

(defvar org-roam-directory)
(defvar citar-bibliography)
(defvar citar-library-paths)
(defvar citar-library-paths-recursive)
(defvar citar-library-file-extensions)
(defvar citar-notes-paths)
(defvar citar-file-note-extensions)
(defvar citar-file-parser-functions)
(defvar citar-file-open-functions)
(defvar citar-indicators)
(defvar citar-notes-source)

(setq org-cite-global-bibliography (list eink-research-bibliography-file)
      org-cite-insert-processor 'citar
      org-cite-follow-processor 'citar
      ;; Default fontification avoids bibliography parsing on redisplay.
      org-cite-activate-processor nil)

(defun eink-research-setup ()
  "Load Citar on demand, without loading Org-roam or scanning desktop notes."
  (unless (file-readable-p eink-research-bibliography-file)
    (user-error "Sync your bibliography first: %s" eink-research-bibliography-file))
  (unless (require 'citar nil t)
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (require 'citar-org)
  (require 'citar-file)
  (setq citar-bibliography (list eink-research-bibliography-file)
        org-cite-global-bibliography citar-bibliography
        citar-library-paths (list (expand-file-name "Literature" eink-research-directory)
                                  eink-research-directory)
        citar-library-paths-recursive nil
        citar-library-file-extensions '("pdf" "epub" "html")
        citar-notes-paths (list org-roam-directory)
        citar-file-note-extensions '("org")
        citar-indicators nil
        citar-file-parser-functions '(eink-research--parse-file-field)
        citar-file-open-functions '(("pdf" . eink-research-open-paper)
                                     ("epub" . eink-research-open-paper)
                                     ("html" . eink-research-open-paper)
                                     (t . find-file)))
  (citar-register-notes-source
   'eink-research
   '(:name "Paper notes" :category eink-research-note
     :items eink-research--notes :hasitems eink-research--has-notes
     :open eink-research--open-note :create eink-research--create-note
     :transform eink-research--note-title))
  (setq citar-notes-source 'eink-research))

(defun eink-research--before-citation (&rest _)
  "Prepare citation insertion/following only when requested."
  (eink-research-setup))
(advice-add 'org-cite-insert :before #'eink-research--before-citation)
(advice-add 'org-cite-follow :before #'eink-research--before-citation)

(defun eink-research-open ()
  "Search the bibliography and choose a local paper, note, DOI, or URL."
  (interactive)
  (eink-research-setup)
  (call-interactively #'citar-open))

(defun eink-research-create-note ()
  "Choose a bibliography entry and create or resume its editable BOOX note.
A desktop note for the same paper remains available separately."
  (interactive)
  (eink-research-setup)
  (citar-create-note (citar-select-ref)))

(defun eink-research--parse-file-field (field)
  "Parse FIELD and translate Dropbox Research paths to this device."
  (delete-dups
   (mapcar
    (lambda (file)
      (if (string-match "Dropbox/Research/\\(.*\\)\\'" file)
          (expand-file-name (match-string 1 file) eink-research-directory)
        file))
    (append (citar-file--parser-default field) (citar-file--parser-triplet field)))))

(defun eink-research-open-paper (file)
  "Open local FILE in an external reader; Android chooses the application."
  (unless (file-readable-p file) (user-error "Paper is not synced locally: %s" file))
  (if (eq system-type 'android)
      ;; Android converts the file URI to a content URI with access permission.
      (browse-url-default-android-browser (browse-url-file-url file))
    (browse-url-of-file file)))

(defun eink-research--notes (&optional keys)
  "Map citation KEYS to BOOX note files and catalog desktop node IDs.
Only filenames in the small BOOX folder are listed; desktop contents are
never read.  Old catalogs also work for citekey-named file nodes."
  (let* ((citar-notes-paths (list org-roam-directory))
         (notes (citar-file--get-notes keys)))
    (desktop-roam--load t)
    (when desktop-roam--nodes
      (maphash
       (lambda (id entry)
         (let ((citekeys (copy-sequence (alist-get 'citekeys entry))))
           (when (= (alist-get 'level entry) 0)
             (push (file-name-base (alist-get 'file entry)) citekeys))
           (dolist (key (delete-dups citekeys))
             (when (or (null keys) (member key keys))
               (push (concat "id:" id) (gethash key notes))))))
       desktop-roam--nodes))
    notes))

(defun eink-research--has-notes ()
  "Return a predicate for notes available without a desktop-library scan."
  (let ((notes (eink-research--notes)))
    (lambda (key) (and (gethash key notes) t))))

(defun eink-research--note-title (note)
  "Display a readable label for NOTE, which is a local file or catalog ID."
  (if (string-prefix-p "id:" note)
      (let ((entry (and desktop-roam--nodes
                        (gethash (substring note 3) desktop-roam--nodes))))
        (format "Desktop: %s" (or (alist-get 'title entry) note)))
    (format "BOOX: %s" (file-name-base note))))

(defun eink-research--open-note (note)
  "Open NOTE, keeping desktop catalog notes read-only."
  (if (string-prefix-p "id:" note)
      (let ((marker (org-id-find (substring note 3) t)))
        (unless marker (user-error "Desktop note ID is not in the synced catalog"))
        (pop-to-buffer (marker-buffer marker))
        (goto-char marker)
        (org-fold-show-context 'link-search)
        (set-marker marker nil))
    (find-file note)))

(defun eink-research--create-note (key entry)
  "Create an editable BOOX literature note for citation KEY and ENTRY."
  (unless (and (stringp key) (not (string-empty-p key))
               (not (member key '("." "..")))
               (not (string-match-p "[/\\\\[:cntrl:]]" key)))
    (user-error "Citation key cannot be used as a note filename"))
  (make-directory org-roam-directory t)
  (eink-roam-setup t)
  (let ((file (expand-file-name (concat key ".org") org-roam-directory)))
    (find-file file)
    (unless (file-exists-p file)
      (unless (= (buffer-size) 0)
        (user-error "An unsaved note already exists for %s" key))
      (insert (format ":PROPERTIES:\n:ID: %s\n:ROAM_REFS: @%s\n:END:\n#+title: %s\n#+filetags: :bibliographical_notes:\n\n[cite:@%s]\n\n* Reading notes\n"
                      (org-id-new) key
                      (replace-regexp-in-string "[\n\r]+" " "
                                                (or (citar-get-value "title" entry) key))
                      key))
      (save-buffer))
    (goto-char (point-max))))

(define-key org-mode-map (kbd "C-c r") #'org-cite-insert)
(global-set-key (kbd "C-c n b") #'eink-research-open)

(provide 'eink-research)
;;; eink-research.el ends here
