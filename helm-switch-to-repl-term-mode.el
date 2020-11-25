;;; helm-switch-to-repl-term-mode.el --- Helm action to switch directory in term-mode REPLs -*- lexical-binding: t; -*-

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
;; Helm "Switch-to-REPL" for `term-mode'.

;;; Code:
(declare-function term-char-mode "term.el")
(declare-function term-line-mode "term.el")
(declare-function term-send-input "term.el")
(declare-function term-next-prompt "term.el")
(declare-function term-process-mark "term.el")

(push 'term-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql term-mode)))
  (goto-char (point-max))
  (insert (helm-switch-to-repl--format-cd))
  (term-char-mode)
  (term-send-input))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql term-mode)))
  (ansi-term (getenv "SHELL")
             (helm-aif (and helm-current-prefix-arg
                            (prefix-numeric-value
                             helm-current-prefix-arg))
                 (format "*ansi-term<%s>*" it)))
  (term-line-mode))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql term-mode)))
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'term-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql term-mode)))
  (save-excursion
    (goto-char (term-process-mark))
    (not (looking-back "\\$ " (- (point) 2)))))

(provide 'helm-switch-to-repl-term-mode)
;;; helm-switch-to-repl-term-mode.el ends here
