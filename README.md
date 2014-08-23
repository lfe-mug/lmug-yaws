# lmug-yaws

*An lmug adapter that uses the YAWS embedded web server*

<img src="resources/images/lmugyaws-small-grey.png" />


## Introduction

This is a module for running a YAWS embedded server as an
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

