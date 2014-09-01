;;;; An lmug adapter that uses the YAWS embedded web server.
;;;;
;;;; Adapters are used to convert lmud handlers into running web servers.
;;;; For more information, see the lmug spec:
;;;;    https://github.com/lfex/lmug/blob/master/doc/SPEC.md
(defmodule lmug-yaws-adapter
  (export all))

(include-lib "deps/lmug/include/response.lfe")

(defun setup ()
  (lutil-file:mkdirs (lmug-yaws-options:log-dir))
  (lutil-file:mkdirs (lmug-yaws-options:http-dir)))

(defun get-handler-server ()
  (whereis (lmug:handler-name)))

(defun get-default-handler ()
  "Given an lmug request record, return a default response."
  (lambda (x) (lmug-yaws-util:get-response x)))

(defun run-yaws ()
  "Run with the default handler and options."
  (run-yaws (get-default-handler) '()))

(defun run-yaws (handler)
  "Run with the default options but a specific handler."
  (run-yaws handler '()))

(defun run-yaws
  "Given a handler which maps request records to response records, pass the
  response data off to OTP httpd so that it may generate the HTTP server
  response.

  This function starts up the handler-loop, passing it the handler function.
  The spawned handler loop PID is then registered for use with later calls."
  ((handler custom-options) (when (is_function handler))
    (io:format "Doing setup ... ")
    (setup)
    (io:format "Done.~n")
    (let ((options (lmug-yaws-options:fixup custom-options))
          (pid (spawn 'barista 'handler-loop `(,handler))))
      (io:format "Registering handler-managing process ...~n")
      (register (lmug:handler-name) pid)
      (io:format "Registered handler-managing process.~n")
      (io:format "Starting YAWS umbedded server ...~n")
      (yaws:start_embedded
        (proplists:get_value 'docroot options)
        (proplists:delete 'docroot options))
      (io:format "Started YAWS.~n"))))

(defun stop-yaws ()
  (io:format "Stopping YAWS umbedded server ...~n")
  (yaws:stop)
  (io:format "Stopped YAWS umbedded server.~n")
  (io:format "Stopping handler-managing process ... ")
  (erlang:exit (get-handler-server) 'ok)
  (io:format "Done.~n")
  'ok)

(defun out (yaws-arg-data)
  "This is the function that our embedded YAWS server is configured to call on
  every request. In order for this to work, the embedded YAWS server needs to
  be configured with #(modules (... <module name>)). See get-defaults/0 in
  lmug-yaws-options.lfe.

  Note that, in order to call the handler here, we need to set up a 'handler
  server' when we call the 'run' function. This will allow us to call the
  configured handler later (i.e., here in the 'out' function).

  This function does the following, when it is called (on each HTTP request):

   * looks up the PID for the handler loop
   * calls the middleware function that converts the YAWS out/1 arg data
     to lmug request data
   * sends a message to the handler loop with converted request data
   * sets up a listener that will be called by the handler loop
   * waits to reveive data from the handler loop (the data which will have been
     produced by the handler function passed to run-yaws/0, 1, or 2)
   * converts the passed lmug request data to the format expected by YAWS
  "
  (!
    (get-handler-server)
    (tuple (self) (lmug-yaws-util:yaws->lmug-request yaws-arg-data)))
  (receive
    ((tuple 'handler-output data) (lmug-yaws-util:lmug->yaws-response data))))
