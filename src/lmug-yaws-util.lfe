(defmodule lmug-yaws-util
  (export all))

(defun get-lmug-yaws-version ()
  (lutil:get-app-src-version "src/lmug-yaws.app.src"))

(defun get-version ()
  (++ (lutil:get-version)
      `(#(lmug-yaws ,(get-lmug-yaws-version)))))
