;;; helm-switch-to-repl-sly-mrepl-mode.el --- Helm action to switch directory SLY REPLs -*- lexical-binding: t; -*-

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
;; Helm "Switch-to-REPL" for SLY.

;;; Code:
(require 'helm-switch-to-repl-shell-mode)

(declare-function sly-change-directory "sly.el")
(declare-function sly "sly.el")

(push 'sly-mrepl-mode helm-switch-to-repl-delayed-execution-modes)

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql sly-mrepl-mode)))
  (let ((directory helm-ff-default-directory))
    (sly-change-directory directory)
    ;; REVIEW: `sly-change-directory' does not change the
    ;; REPL's dir, do it here.
    (cd-absolute directory)))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql sly-repl-mode)))
  (sly))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t)
                                                        (_mode (eql sly-mrepl-mode)))
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'comint-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql sly-mrepl-mode)))
  (helm-switch-to-repl-shell-alive-p 'shell-mode))

(provide 'helm-switch-to-repl-sly-mrepl-mode)
;;; helm-switch-to-repl.el ends here
