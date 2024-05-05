---
title: 'Prefix date in properties when using ox-hugo and emacs'
date: 2024-05-04T00:46:27-04:00
categories: [emacs]
draft: false
---


If you're using `ox-hugo` and want to have it generate markdown files with the date prefixing the markdown title you can use this snippet to do it on save with `org-hugo-auto-export-mode` turned on.

```elisp
(defun ox-date-slug-prop ()
  (interactive)
  (let ((dt (format-time-string "%Y-%m-%d" (apply #'encode-time (org-parse-time-string (org-entry-get (point) "EXPORT_DATE")))))
        (slug (org-hugo-slug (org-get-heading :no-tags :no-todo))))
    (org-set-property "EXPORT_FILE_NAME" (format "%s-%s" dt slug))))

(defun my-setup-hugo-auto-export ()
  "Set up an advice to call `my-ox-date-slug-before-save' before `org-hugo-auto-export'."
  (advice-add 'org-hugo-export-wim-to-md :before #'ox-date-slug-prop))

(my-setup-hugo-auto-export)
```
