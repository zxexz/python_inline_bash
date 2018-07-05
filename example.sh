
#! /bin/bash

TMPLOC=/tmp
RD=$TMPLOC/readylock.$$
RQ=$TMPLOC/request_fifo.$$
RS=$TMPLOC/result_file.$$

start_cmdserver() {
mkfifo $RQ
(
cat << EOF | /usr/bin/env python3 -
from os import unlink
from os.path import exists
from pathlib import Path
from sys import stderr
_RD = '$RD'
_RQ = '$RQ'
_RS = '$RS'
_op = print
def print(*args, file=_RS):
    with open(file, 'w+') as f:
        _op(*args, file=f)
_t = lambda *x: [None if exists(y) else Path(y).touch() for y in x]
_u = lambda *x: [unlink(y) if exists(y) else None for y in x]
_u(_RS, _RD)
while 1:
    with open(_RQ) as RQF:
        _u(_RS, _RD)
        _d = RQF.read()
        try:
            out = eval(_d)
            if out:
                print(out)
        except Exception as f:
            try:
                exec(_d)
            except Exception as e:
                _op('ERROR:', e, '\nERROR:', f, file=stderr)
        _t(_RS, _RD)
EOF
) &
}
run_cmd() {
        echo $@ > $RQ
        while [ ! -f $RD ]; do
                :
        done
        rm $RD
        cat $RS
}
kill_cmdserver () {
        echo "exit()" > $RQ
        rm -f $RS $RQ $RD || true
}
body () {
        run_cmd "HELLO='hello'"
        run_cmd "WORLD='world'"
        run_cmd "print(HELLO.upper(),WORLD.upper(),'!')"
        run_cmd 'print("I am running in a bash script PID '$$'")'
}
start_cmdserver
body
kill_cmdserver
