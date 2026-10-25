;;; eink-agent.el --- On-demand Codex sessions -*- lexical-binding: t; -*-

;; Use the Android-built Codex, rather than the adapter's desktop binary.
;; Respect an explicit device override. local.el can also override this later.
(when (and (eq system-type 'android) (not (getenv "CODEX_PATH")))
  (setenv "CODEX_PATH" "/data/data/com.termux/files/usr/bin/codex"))

(defun eink-agent-data-directory (subdir)
  "Keep agent SUBDIR data in private state, separated by working directory."
  (expand-file-name
   subdir
   (expand-file-name
    (concat "agent-shell/" (secure-hash 'sha256 (expand-file-name default-directory)) "/")
    eink-state-directory)))

;; These take effect when agent-shell is first loaded; no agent starts at login.
(setq agent-shell-header-style 'text
      agent-shell-show-busy-indicator nil
      agent-shell-show-config-icons nil
      agent-shell-highlight-blocks nil
      agent-shell-dot-subdir-function #'eink-agent-data-directory)

(defun eink-codex ()
  "Start a Codex agent-shell in the current directory."
  (interactive)
  (unless (locate-library "agent-shell")
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (unless (executable-find "codex-acp")
    (user-error "Install @agentclientprotocol/codex-acp in Termux first"))
  (let ((codex (or (getenv "CODEX_PATH") "codex")))
    (unless (executable-find codex)
      (user-error "Codex executable not found: %s" codex)))
  (require 'agent-shell)
  (call-interactively #'agent-shell-openai-start-codex))

(global-set-key (kbd "C-c e") #'eink-codex)

(provide 'eink-agent)
;;; eink-agent.el ends here
