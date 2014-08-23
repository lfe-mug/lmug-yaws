;;;; An lmug adapter that uses the YAWS embedded web server.
;;;;
;;;; Adapters are used to convert lmud handlers into running web servers.
;;;; For more information, see the lmug spec:
;;;;    https://github.com/lfex/lmug/blob/master/doc/SPEC.md
(defmodule lmug-yaws
  (import
    (from proplists
      (delete 2)
      (get_value 2)
      (is_defined 2)))
  (export all))

(defun host->listen (host)
  (let ((`#(ok ,listen) (inet:getaddr host 'inet)))
    listen))

(defun add-listen (options)
  (++ options
      `(#(listen ,(host->listen (get_value 'host options))))))

(defun add-defaults (options)
  (add-default 'docroot "/tmp"
    (add-default 'host "127.0.0.1"
      (add-default 'port 1206 options))))

(defun add-default (key val options)
  (cond
    ((is_defined key options)
      options)
    ('true
      (++ options `(#(,key ,val))))))

(defun fixup-options (options)
  "Let's remove the options that YAWS doesn't expect.

  We should have already used these deleted options in other functions, so
  they can be removed now without impact."
  (delete 'docroot
    (delete 'host
      (add-listen options))))

(defun run-yaws (handler raw-options)
  (let ((options (add-defaults raw-options)))
    (yaws:start_embedded
      (get_value 'docroot options)
      (fixup-options options))))

(defun stop-yaws ())
