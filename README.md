# lmug-yaws

[![][lmug-logo]][lmug-logo-large]

[lmug-logo]: resources/images/lmug-yaws.png
[lmug-logo-large]: resources/images/lmug-yaws-large.png

*An lmug adapter that uses the YAWS embedded web server*


## Introduction

This is a module for running a
[YAWS](http://yaws.hyber.org/) embedded server as an
[lmug adapter](https://github.com/lfex/lmug/blob/master/doc/SPEC.md#adapters).


## Installation

Just add it to your ``rebar.config`` deps:

```erlang
    {deps, [
        ...
        {lmug-yaws, ".*", {git, "git@github.com:lfex/lmug-yaws.git", "master"}}
      ]}.
```

And then do the usual:

```bash
    $ rebar get-deps
    $ rebar compile
```


## Usage

NOTE: the example below does not yet work; this lmud adapter is a work in
progress.

### Hello World

```cl
> (slurp "src/lmug-yaws.lfe")
#(ok lmug-yaws)
> (defun handler (request)
    (make-response
      status 200
      headers '(#(content_type "text/plain"))
      body "Hello World"))
handler
> (run-yaws #'handler/1)
#(ok <0.55.0>)
```

To check your new hanlder:

```bash
$ curl -D- -X GET http://localhost:1206/
HTTP/1.1 200 OK
Server: inets/5.10.2
Date: Thu, 28 Aug 2014 20:30:52 GMT
Content-Length: 11
Content-Type: text/plain

Hello World
```

If you want to run on a non-default port (or pass other options) or if you
are using with other projects, please use the adapter module directly. For
example:

```cl
(lmug-yaws-adapter:run #'handler/1 '(#(port 8000)))
#(ok <0.54.0>)
```
