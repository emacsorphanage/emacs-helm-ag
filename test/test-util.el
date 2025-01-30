;;; test-util.el --- test helm-ag utility functions

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ert)
(require 'helm-ag)
(require 'cl-lib)

(ert-deftest parse-query ()
  "Parsing input which may contains option"
  (let ((got (helm-ag--parse-query "foo bar")))
    (should (equal got '("foo bar"))))

  (let ((got (helm-ag--parse-query "--nogroup --column foo bar")))
    (should (equal got '("--nogroup" "--column" "foo bar"))))

  (let ((got (helm-ag--parse-query "--column helm-ag ()")))
    (should (equal got '("--column" "helm-ag ()"))))

  (let ((got (helm-ag--parse-query "hello -a -b")))
    (should (equal got '("-a" "-b" "hello"))))

  (let ((got (helm-ag--parse-query "foo bar -g=*.el -g=!test")))
    (should (equal got '("-g=*.el" "-g=!test" "foo bar"))))
  )

(ert-deftest construct-command ()
  "helm-ag--construct--command"
  (let ((helm-ag-base-command "ag --nocolor --nogroup")
        (helm-ag--last-query "pattern"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--nocolor" "--nogroup" "pattern")))
      (should (equal got expected)))))

(ert-deftest construct-command-this-file ()
  "helm-ag--construct--command for this file"
  (let ((helm-ag-base-command "ag --nocolor --nogroup")
        (helm-ag--last-query "pattern"))
    (let ((got (helm-ag--construct-command "foo.el"))
          (expected '("ag" "--nocolor" "--nogroup" "pattern" "foo.el")))
      (should (equal got expected)))))

(ert-deftest construct-command-with-options ()
  "helm-ag--construct--command with options"
  (let ((helm-ag-base-command "ag --nocolor --nogroup")
        (helm-ag-command-option "--all-text --hidden -D")
        (helm-ag--last-query "pattern"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--nocolor" "--nogroup" "--all-text" "--hidden" "-D"
                      "pattern")))
      (should (equal got expected)))))

(ert-deftest construct-command-with-options-in-input ()
  "helm-ag--construct--command with options in input"
  (let ((helm-ag-base-command "ag --nocolor --nogroup")
        (helm-ag-command-option "--all-text --hidden -D")
        (helm-ag--last-query "-G\\.md$ foo bar"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--nocolor" "--nogroup" "--all-text" "--hidden" "-D"
                      "-G\\.md$" "foo bar")))
      (should (equal got expected))))

  (let ((helm-ag-base-command "ag")
        (helm-ag-command-option "")
        (helm-ag--last-query "-- --count"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--" "--count")))
      (should (equal got expected))))

  (let ((helm-ag-base-command "ag")
        (helm-ag-command-option "")
        (helm-ag--last-query "helm-ag"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "helm-ag")))
      (should (equal got expected))))

  (let ((helm-ag-base-command "ag")
        (helm-ag-command-option "")
        (helm-ag--last-query "--count -G.md$ -- --count foo bar"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--count" "-G.md$" "--" "--count foo bar")))
      (should (equal got expected)))))

(ert-deftest construct-command-with-ignore-patterns ()
  "helm-ag--construct--command with ignore options"
  (let ((helm-ag-base-command "ag --nocolor --nogroup")
        (helm-ag-ignore-patterns '("*.md" "*.el"))
        (helm-ag--last-query "foo"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("ag" "--nocolor" "--nogroup" "--ignore=*.md" "--ignore=*.el" "foo")))
      (should (equal got expected)))))

(ert-deftest construct-command-in-do-ag ()
  "helm-ag--construct-command used in helm-do-ag"
  (let* ((helm-ag-base-command "ag --nocolor --nogroup")
         (helm-ag--last-query "somepattern")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "somepattern")))
    (should (equal got expected)))

  (let* ((helm-ag--command-features '())  ;; unknown pattern
         (helm-ag--last-query "pat1 pat2")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "pat1 pat2")))
    (should (equal got expected)))

  (let* ((helm-ag--command-features '(fixed))
         (helm-ag--last-query "pat1 pat2")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "pat1 pat2")))
    (should (equal got expected)))

  (let* ((helm-ag--command-features '(re2))
         (helm-ag--last-query "pat1 pat2")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "pat1.*pat2")))
    (should (equal got expected)))

  (let* ((helm-ag--command-features '(pcre))
         (helm-ag--last-query "pat1 pat2")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "(?=.*pat1.*)(?=.*pat2.*)")))
    (should (equal got expected)))

  (let* ((helm-ag-command-option "--ignore-case --all-text")
         (helm-ag--last-query "somepattern")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "--ignore-case" "--all-text"
                     "somepattern")))
    (should (equal got expected)))

  (let* ((helm-ag-ignore-patterns '("apple" "orange"))
         (helm-ag--last-query "somepattern")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "--ignore=apple" "--ignore=orange"
                     "somepattern")))
    (should (equal got expected))))

(ert-deftest construct-command-with-extra-option-in-do-ag ()
  "helm-ag--construct-command with extra options used in helm-do-ag"
  (let* ((helm-ag-base-command "ag --nocolor --nogroup")
         (helm-ag--extra-options "-G\\.md$")
         (helm-ag--last-query "somepattern")
         (got (helm-ag--construct-command))
         (expected '("ag" "--nocolor" "--nogroup" "-G\\.md$" "somepattern")))
    (should (equal got expected))))

(ert-deftest construct-command-for-rg ()
  "helm-ag--construct-command for rg base command"
  (let* ((helm-ag-base-command "rg --no-heading")
         (helm-ag--last-query "somepattern")
         (got (helm-ag--construct-command))
         (expected '("rg" "--no-heading" "somepattern")))
    (should (equal got expected))))

(ert-deftest construct-command-with-options-for-rg ()
  "helm-ag--construct--command with options for rg base command"
  (let ((helm-ag-base-command "rg --no-heading")
        (helm-ag-command-option "--max-depth=5 -P")
        (helm-ag--last-query "pattern"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("rg" "--no-heading" "--max-depth=5" "-P"
                      "pattern")))
      (should (equal got expected)))))

(ert-deftest construct-command-with-ignore-options-for-rg ()
  "helm-ag--construct--command with options for rg base command"
  (let ((helm-ag-base-command "rg --no-heading")
        (helm-ag-command-option "--max-depth=5 -P")
        (helm-ag--last-query "pattern"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("rg" "--no-heading" "--max-depth=5" "-P"
                      "pattern")))
      (should (equal got expected)))))

(ert-deftest construct-command-with-ignore-options-for-rg ()
  "helm-ag--construct--command with ignore options for rg base command"
  (let ((helm-ag-base-command "rg --no-heading")
        (helm-ag-ignore-patterns '("*.md" "*.el"))
        (helm-ag--last-query "foo"))
    (let ((got (helm-ag--construct-command nil))
          (expected '("rg" "--no-heading" "--glob=!*.md" "--glob=!*.el" "foo")))
      (should (equal got expected)))))

(ert-deftest validate-regexp-with-valid-regexp ()
  (should (helm-ag--validate-regexp "[a-z]\\([[:word:]]\\)")))

(ert-deftest validate-regexp-with-invalid-regexp ()
  (should-not (helm-ag--validate-regexp "\\(")))

(ert-deftest transform-for-this-file ()
  "helm-ag--candidate-transform-for-this-file"
  (let ((helm-ag--last-command `("ag" "--nogroup"))
        (helm-ag--search-this-file-p t)
        (helm-ag--last-query "hoge"))
    (should (helm-ag--candidate-transform-for-this-file "10:hoge"))
    (should-not (helm-ag--candidate-transform-for-this-file ":hoge"))))

(ert-deftest transform-for-files ()
  "helm-ag--candidate-transform-for-files"
  (let ((helm-ag--last-command `("ag" "--nogroup"))
        (helm-ag--last-query "hoge"))
    (should (helm-ag--candidate-transform-for-files "10:5:hoge"))
    (should-not (helm-ag--candidate-transform-for-files "10:hoge"))))

(ert-deftest convert-to-emacs-lisp-regexp ()
  "Simple convertion from PCRE to Emacs lisp regexp"
  (let ((got (helm-ag--convert-to-elisp-regexp "(foo|bar)")))
    (should (string= got "\\(foo\\|bar\\)")))
  (let ((got (helm-ag--convert-to-elisp-regexp "foo{1,2}")))
    (should (string= got "foo\\{1,2\\}")))

  (let ((got (helm-ag--convert-to-elisp-regexp "\\(foo\\|bar\\)")))
    (should (string= got "(foo|bar)")))

  (let ((got (helm-ag--convert-to-elisp-regexp "foo\\{1,2\\}")))
    (should (string= got "foo{1,2}")))

  (let ((got (helm-ag--convert-to-elisp-regexp "\\\\(foo\\\\|bar\\\\)")))
    (should (string= got "\\\\(foo\\\\|bar\\\\)")))

  (let ((got (helm-ag--convert-to-elisp-regexp "\\S\\s\\S")))
    (should (string= got "\\S-\\s-\\S-")))

  (let ((got (helm-ag--convert-to-elisp-regexp "\\\\S\\\\s")))
    (should (string= got "\\\\S\\\\s"))))

(ert-deftest emacs-lisp-regexp-to-pcre ()
  "Simple convertion from Emacs lisp regexp to PCRE"
  (let ((got (helm-ag--elisp-regexp-to-pcre "\\(foo\\|bar\\)")))
    (should (string= got "(foo|bar)")))
  (let ((got (helm-ag--elisp-regexp-to-pcre "foo\\{1,2\\}")))
    (should (string= got "foo{1,2}")))

  (let ((got (helm-ag--elisp-regexp-to-pcre "(foo|bar)")))
    (should (string= got "\\(foo\\|bar\\)")))

  (let ((got (helm-ag--elisp-regexp-to-pcre "foo{1,2}")))
    (should (string= got "foo\\{1,2\\}")))

  (let ((got (helm-ag--elisp-regexp-to-pcre "\\\\(foo\\\\|bar\\\\)")))
    (should (string= got "\\\\(foo\\\\|bar\\\\)"))))

(ert-deftest judge-ignore-case ()
  "Judge ignore case searching or not "
  (should (helm-ag--ignore-case-p nil "aa"))
  (should (not (helm-ag--ignore-case-p nil "AA")))
  (should (helm-ag--ignore-case-p '("-i") "AA"))
  (should (helm-ag--ignore-case-p '("--ignore-case") "Apple"))
  (should (not (helm-ag--ignore-case-p '("-s") "apple")))
  (should (not (helm-ag--ignore-case-p '("--case-sensitive") "apple"))))

(ert-deftest split-string ()
  "Own split-string function for handling escaped space"
  (should (equal (helm-ag--split-string "aa") '("aa")))
  (should (equal (helm-ag--split-string "  aa") '("aa")))
  (should (equal (helm-ag--split-string "aa bb cc") '("aa" "bb" "cc")))
  (should (equal (helm-ag--split-string "aa       bb         cc") '("aa" "bb" "cc")))
  (should (equal (helm-ag--split-string "aa\\ bb cc") '("aa bb" "cc")))
  (should (equal (helm-ag--split-string "aa\\\\ bb cc") '("aa\\\\" "bb" "cc"))))

(ert-deftest join-pattern ()
  "Convert pattern like normal helm command in helm-do-ag"
  (let ((helm-ag--command-features '()))  ;; unknown pattern
    (should (equal (helm-ag--join-patterns "foo") "foo"))
    (should (equal (helm-ag--join-patterns "foo bar") "foo bar")))

  (let ((helm-ag--command-features '(fixed)))
    (should (equal (helm-ag--join-patterns "foo") "foo"))
    (should (equal (helm-ag--join-patterns "foo bar") "foo bar")))

  (let ((helm-ag--command-features '(re2)))
    (should (equal (helm-ag--join-patterns "foo") "foo"))
    (should (equal (helm-ag--join-patterns "foo bar") "foo.*bar")))

  (let ((helm-ag--command-features '(pcre)))
    (should (equal (helm-ag--join-patterns "foo") "foo"))
    (should (equal (helm-ag--join-patterns "!") "!"))
    (should (equal (helm-ag--join-patterns "!foo") "^(?!.*foo).+$"))

    (should (equal (helm-ag--join-patterns "foo bar") "(?=.*foo.*)(?=.*bar.*)"))
    (should (equal (helm-ag--join-patterns "foo !") "(?=.*foo.*)(?=.*!.*)"))
    (should (equal (helm-ag--join-patterns "foo !bar") "(?=.*foo.*)(?=^(?!.*bar).+$)"))))

(ert-deftest search-this-file-p ()
  (cl-letf (((symbol-function 'helm-get-current-source)
             (lambda () 'helm-source-ag))
            ((symbol-function 'helm-attr)
             (lambda (attr &optional source compute)
               t)))
    (should (helm-ag--search-this-file-p)))

  (cl-letf (((symbol-function 'helm-get-current-source)
             (lambda () 'helm-source-do-ag))
            ((symbol-function 'helm-attr)
             (lambda (attr &optional source compute)
               t)))
    (let ((helm-ag--default-target '("a.txt" "b.txt")))
      (should-not (helm-ag--search-this-file-p)))

    (let ((helm-ag--default-target (list default-directory)))
      (should-not (helm-ag--search-this-file-p)))

    (let ((helm-ag--default-target '("a.txt")))
      (should (helm-ag--search-this-file-p)))))

(ert-deftest visited-buffers ()
  "Remove buffers which are matched against helm-ag-ignore-buffer-patterns"
  (cl-letf (((symbol-function 'buffer-list)
             (lambda () '("aa.txt" "bb.md" "cc.el")))
            ((symbol-function 'buffer-file-name)
             (lambda (b) b))
            ((symbol-function 'buffer-name)
             (lambda (b) b)))
    (let* ((helm-ag-ignore-buffer-patterns nil)
           (got (helm-ag--file-visited-buffers)))
      (should (equal got '("aa.txt" "bb.md" "cc.el"))))

    (let* ((helm-ag-ignore-buffer-patterns '("\\.md\\'" "\\`cc"))
           (got (helm-ag--file-visited-buffers)))
      (should (equal got '("aa.txt"))))))

(ert-deftest set-command-features ()
  "Set search command features to `helm-ag--command-features'"

  ;; ack
  (dolist (expected '(("-Q" . fixed)
                      ("--literal" . fixed)
                      ("-Quiet" . pcre)))
    (let ((helm-ag-base-command (concat "ack " (car expected))))
      (helm-ag--set-command-features)
      (should (memq (cdr expected) helm-ag--command-features))))

  ;; ag
  (dolist (expected '(("-Q" . fixed)
                      ("--literal" . fixed)
                      ("-F" . fixed)
                      ("--fixed-strings" . fixed)
                      ("-False" . pcre)))
    (let ((helm-ag-base-command (concat "ag " (car expected))))
      (helm-ag--set-command-features)
      (should (memq (cdr expected) helm-ag--command-features))))

  ;; pt
  (dolist (expected '(("-e" . re2)
                      ("--eee" . fixed)))
    (let ((helm-ag-base-command (concat "pt " (car expected))))
      (helm-ag--set-command-features)
      (should (memq (cdr expected) helm-ag--command-features))))

  ;; rg
  (dolist (expected '(("-F" . fixed)
                      ("--fixed-strings" . fixed)
                      ("--fixed-stringssss" . re2)))
    (let ((helm-ag-base-command (concat "rg " (car expected))))
      (helm-ag--set-command-features)
      (should (memq (cdr expected) helm-ag--command-features)))))

;;; test-util.el ends here
