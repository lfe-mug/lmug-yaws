(defmodule lmug-yaws-util
  (export all))

(include-lib "yaws/include/yaws_api.hrl")
(include-lib "lmug/include/request.lfe")
(include-lib "lmug/include/response.lfe")

(defun get-lmug-yaws-version ()
  (lutil:get-app-src-version "src/lmug-yaws.app.src"))

(defun get-version ()
  (++ (lutil:get-version)
      `(#(lmug-yaws ,(get-lmug-yaws-version)))))

(defun get-hostname
  ((`#(init_data ,_ ,hostname))
    hostname))

(defun yaws->lmug-headers (data)
  `(#(connection ,(headers-connection data))
    #(accept ,(headers-accept data))
    #(host ,(headers-host data))
    #(if_modified_since ,(headers-if_modified_since data))
    #(if_match ,(headers-if_match data))
    #(if_none_match ,(headers-if_none_match data))
    #(if_range ,(headers-if_range data))
    #(if_unmodified_since ,(headers-if_unmodified_since data))
    #(range ,(headers-range data))
    #(referer ,(headers-referer data))
    #(user_agent ,(headers-user_agent data))
    #(accept_ranges ,(headers-accept_ranges data))
    #(cookie ,(headers-cookie data))
    #(keep_alive ,(headers-keep_alive data))
    #(location ,(headers-location data))
    #(content_length ,(headers-content_length data))
    #(content_type ,(headers-content_type data))
    #(content_encoding ,(headers-content_encoding data))
    #(authorization ,(headers-authorization data))
    #(transfer_encoding ,(headers-transfer_encoding data))
    #(x_forwarded_for ,(headers-x_forwarded_for data))))

(defun yaws-special-headers ()
  '(connection
    server
    location
    cache_control
    expires
    date
    allow
    last_modified
    etag
    set_cookie
    content_range
    content_type
    content_encoding
    content_length
    transfer_encoding
    www_authenticate
    vary))

(defun parse-body
  (('undefined)
    '"")
  ((data) (when (is_binary data))
    (binary_to_list data)))

(defun yaws->lmug-request (data)
  "Convert a YAWS arg record to an lmug request record.

  Every web server that gets an lmug adapter needs to implement a function
  like this one which will transform that server's request data into the
  request data needed by lmug, in the record structure required by lmug (and
  defined in the lmug Spec)."
  (let* ((headers (yaws->lmug-headers (arg-headers data)))
         (`(,host ,port) (lmug-util:get-host-data
                           (proplists:get_value 'host headers)))
         (request (arg-req data))
         (remote-addr-tuple (element 1 (arg-client_ip_port data)))
         (uri (element 2 (http_request-path request)))
         (body (parse-body (arg-clidata data))))
    (make-request
      server-port host
      server-name port
      remote-addr (lutil-type:tuple->host remote-addr-tuple)
      uri uri
      path (arg-server_path data)
      query-params (lmug-util:parse-query-string uri)
      scheme 'unknown-scheme
      request-method (lmug-util:normalize-http-verb
                       (http_request-method request))
      content-type 'unknown-content-type
      content-length (length body)
      headers headers
      body body
      orig data)))

(defun capitalize-string
  (((cons first-letter remaining))
    (++ (string:to_upper `(,first-letter)) remaining)))

(defun header->string
  ((header) (when (is_atom header))
    (atom_to_list header))
  ((header) (when (is_list header))
    header))

(defun capitalize-header (header-key)
  (let* ((header-string (header->string header-key))
         (parts (re:split header-string "[-_]" '(#(return list)))))
    (string:join (lists:map #'capitalize-string/1 parts) "-")))

(defun make-header
  ((`#(,key ,val))
    (if (lists:member key (yaws-special-headers))
      `#(header #(,key ,val))
      `#(header #(,(capitalize-header key) ,val)))))

(defun check-yaws-headers (headers)
  (lists:map
    (match-lambda
      ((`#(,header undefined))
        'false)
      ((x)
        (make-header x)))
    headers))

(defun make-yaws-headers (headers)
  ; (lfe_io:format "headers: ~n~p~n" (list headers))
  (lists:filter
    #'lutil:check/1
    (check-yaws-headers headers)))

(defun get-response (lmug-request-data)
  "Given an lmug request, create an lmug response record."
  ; (lfe_io:format "lmug-request-data: ~n~p~n" (list lmug-request-data))
  (if (not (is-request lmug-request-data))
    (error "The data passed was not a request record.")
    (make-response
      status 200
      headers '(#(content_type "text/plain")
                #(lmug_x_info "default generated response"))
      body (lists:flatten
             (io_lib:format "Request data: ~n~p"
                            (list lmug-request-data))))))

(defun lmug->yaws-response (lmug-response-data)
  "Converts an lmug response recurd to a YAWS response data structure."
  ; (lfe_io:format "lmug-response-data: ~n~p~n" (list lmug-response-data))
  (if (not (is-response lmug-response-data))
    (error "The data passed was not a response record.")
    (let* ((body (response-body lmug-response-data))
           (raw-headers (response-headers lmug-response-data))
           (headers
             (make-yaws-headers raw-headers)))
      ; (lfe_io:format "headers: ~n~p~n" (list headers))
      ; (lfe_io:format "body: ~n~p~n" (list body))
      `(#(status ,(response-status lmug-response-data))
        ,@headers
        #(content ,(proplists:get_value 'content_type raw-headers)
                  ,body)))))
