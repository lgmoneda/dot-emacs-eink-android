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

;; Desktop behavior without its work credentials, extensions, or styling.
(setq agent-shell-file-completion-enabled t
      agent-shell-show-welcome-message nil
      agent-shell-context-sources nil
      agent-shell-dot-subdir-function #'eink-agent-data-directory)

(with-eval-after-load 'agent-shell
  (setq agent-shell-openai-default-model-id "gpt-6.1-sol"
        agent-shell-openai-default-session-mode-id "agent-full-access"
        agent-shell-openai-authentication
        (agent-shell-openai-make-authentication :login t)
        agent-shell-agent-configs
        (list (agent-shell-openai-make-codex-config))
        agent-shell-openai-codex-environment
        (agent-shell-make-environment-variables :inherit-env t))
  (define-key agent-shell-mode-map (kbd "C-<tab>") #'eink-next-window))

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

;; Match the desktop prefix and its core context/composition commands.
(define-prefix-command 'eink-agent-map)
(global-set-key (kbd "C-c a") #'eink-agent-map)
(define-key eink-agent-map (kbd "a") #'eink-codex)
(dolist (binding '(("f" . agent-shell-send-current-file)
                   ("l" . agent-shell-send-dwim)
                   ("d" . agent-shell-send-dwim)
                   ("r" . agent-shell-send-region)
                   ("o" . agent-shell-send-other-file)
                   ("c" . agent-shell-prompt-compose)
                   ("q" . agent-shell-prompt-queue)
                   ("s" . agent-shell-send-screenshot)
                   ("i" . agent-shell-send-clipboard-image)))
  (autoload (cdr binding) "agent-shell" nil t)
  (define-key eink-agent-map (kbd (car binding)) (cdr binding)))

(provide 'eink-agent)
;;; eink-agent.el ends here
