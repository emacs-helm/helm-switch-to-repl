;;; helm-switch-to-repl.el --- Helm action to switch directory in REPLs -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Pierre Neidhardt

;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-switch-to-repl
;; Version: 0.0.0
;; Package-Requires: ((emacs "26.1") (helm "3"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>

;;; Commentary:
;;
;; Helm "Switch-to-REPL" offers the `helm-switch-to-repl' action, a generalized
;; and extensible version of `helm-ff-switch-to-shell'.  It can be added to
;; `helm-find-files' and other `helm-type-file' sources such as `helm-locate'.
;;
;; Call `helm-switch-to-repl-setup' to install the action and bind it to "M-e".
;;
;; Extending support to more REPLs is easy, it's just about adding a couple of
;; specialized methods.  Look at the implementation of for `shell-mode' for an
;; example.

;;; Code:
(require 'helm)
(require 'helm-files)
(require 'helm-mode)
(require 'cl-generic)

;; Forward declarations to silence compiler warnings.
(defvar term-char-mode-point-at-process-mark)
(defvar term-char-mode-buffer-read-only)

(defgroup helm-switch-to-repl nil
  "Emacs Helm actions to switch to REPL from `helm-find-files' and
other `helm-type-file' sources."
  :group 'helm)

(defcustom helm-switch-to-repl-delayed-execution-modes '()
  "REPL modes running a separate process must be added to this list.
Example to include: `shell-mode' and `term-mode'.
Conversely, Eshell need not be included."
  :type 'list
  :group 'helm-swith-to-repl)

(cl-defgeneric helm-switch-to-repl-cd-repl (_mode)
  "Change current REPL directory to `helm-ff-default-directory'."
  nil)

(cl-defgeneric helm-switch-to-repl-new-repl (_mode)
  "Spawn new REPL in given mode."
  nil)

(cl-defgeneric helm-switch-to-repl-interactive-buffer-p (_buffer _mode)

  "Return non-nil if buffer is a REPL in the given mode."
  nil)

(cl-defgeneric helm-switch-to-repl-shell-alive-p (_mode)
  "Return non-nil when a process is running inside buffer in given mode.")

(defun helm-switch-to-repl--format-cd ()
  "Return a command string to switch directly in shells."
  (format "cd %s"
          (shell-quote-argument
           (or (file-remote-p
                helm-ff-default-directory 'localname)
               helm-ff-default-directory))))

(defun helm-switch-to-repl--has-next-prompt? (next-prompt-fn)
  "Return non-nil if current buffer has at least one prompt.
NEXT-PROMPT-FN is used to find the prompt."
  (save-excursion
    (goto-char (point-min))
    (funcall next-prompt-fn 1)
    (null (eql (point) (point-min)))))

(defun helm-switch-to-repl (candidate)
  "Like `helm-ff-switch-to-shell' but supports more modes.
CANDIDATE's directory is used outside of `helm-find-files'."
  ;; `helm-ff-default-directory' is only set in `helm-find-files'.
  ;; For other `helm-type-file', use the candidate directory.
  (let ((helm-ff-default-directory (or helm-ff-default-directory
                                       (if (file-directory-p candidate)
                                           candidate
                                         (file-name-directory candidate))))
        ;; Reproduce the Emacs-25 behavior to be able to edit and send
        ;; command in term buffer.
        term-char-mode-buffer-read-only ; Emacs-25 behavior.
        term-char-mode-point-at-process-mark ; Emacs-25 behavior.
        (bufs (cl-loop for b in (mapcar 'buffer-name (buffer-list))
                       when (helm-switch-to-repl-interactive-buffer-p
                             b (with-current-buffer b major-mode))
                       collect b)))
    ;; Jump to a shell buffer or open a new session.
    (helm-aif (and (not helm-current-prefix-arg)
                   (if (cdr bufs)
                       (helm-comp-read "Switch to shell buffer: " bufs
                                       :must-match t)
                     (car bufs)))
        ;; Display in same window by default to preserve the
        ;; historical behaviour
        (pop-to-buffer it '(display-buffer-same-window))
      (helm-switch-to-repl-new-repl helm-ff-preferred-shell-mode))
    ;; Now cd into directory.
    (helm-aif (and (memq major-mode helm-switch-to-repl-delayed-execution-modes)
                   (get-buffer-process (current-buffer)))
        (accept-process-output it 0.1))
    (unless (helm-switch-to-repl-shell-alive-p major-mode)
      (helm-switch-to-repl-cd-repl major-mode))))

(defun helm-run-switch-to-repl ()
  "Run switch to REPL action from `helm-source-find-files' or `helm-type-file' sources."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-switch-to-repl)))
(put 'helm-run-switch-to-repl 'helm-only t)

;;;###autoload
(defun helm-switch-to-repl-setup ()
  "Install `helm-switch-to-repl' actions.
It adds it to `helm-find-files' and other `helm-type-file' sources such as
`helm-locate'."
  (interactive)
  ;; `helm-type-file':
  (add-to-list 'helm-type-file-actions
               '("Switch to REPL `M-e'" . helm-switch-to-repl)
               :append)
  (define-key helm-generic-files-map (kbd "M-e") 'helm-run-switch-to-repl)

  ;; helm-source-find-files:
  (add-to-list 'helm-find-files-actions
               '("Switch to REPL `M-e'" . helm-switch-to-repl)
               :append)
  (define-key helm-find-files-map (kbd "M-e") 'helm-run-switch-to-repl)
  ;; Remove binding from "Switch to Eshell" action name:
  (let ((eshell-action (assoc "Switch to Eshell `M-e'"
                              helm-find-files-actions)))
    (when eshell-action
      (setcar eshell-action "Switch to shell"))))

(provide 'helm-switch-to-repl)

(require 'helm-switch-to-repl-eshell-mode)
(require 'helm-switch-to-repl-shell-mode)
(require 'helm-switch-to-repl-sly-mrepl-mode)
(require 'helm-switch-to-repl-term-mode)
;;; helm-switch-to-repl.el ends here
