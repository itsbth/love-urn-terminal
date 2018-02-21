(define *pty-lib* (require :lpty))

(define *pty-funcs* 
  '(endproc
    expect
    flush
    getenviron
    geterrfd
    getflags
    hasproc
    new
    read
    readline
    readok
    send
    sendok
    setenviron
    setflag
    startproc
    ttyname))

,@(map (lambda (sy) `(define ,sy (.> *pty-lib* ,(symbol->string sy)))) *pty-funcs*)
