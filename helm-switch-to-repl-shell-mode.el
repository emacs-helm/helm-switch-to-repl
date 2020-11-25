;;; helm-switch-to-repl-shell-mode.el --- Helm action to switch directory in shell-mode REPLs -*- lexical-binding: t; -*-

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
;; Helm "Switch-to-REPL" for `shell-mode'.

;;; Code:
(require 'helm-switch-to-repl)

(push 'shell-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql shell-mode)))
  (goto-char (point-max))
  (comint-delete-input)
  (insert (helm-switch-to-repl--format-cd))
  (comint-send-input))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql shell-mode)))
  (shell (helm-aif (and helm-current-prefix-arg
                        (prefix-numeric-value
                         helm-current-prefix-arg))
             (format "*shell<%s>*" it))))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql shell-mode)))
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'comint-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql shell-mode)))
  (save-excursion
    (comint-goto-process-mark)
    (or (null comint-last-prompt)
        (not (eql (point)
                  (marker-position (cdr comint-last-prompt)))))))

(provide 'helm-switch-to-repl-shell-mode)
;;; helm-switch-to-repl.el ends here
