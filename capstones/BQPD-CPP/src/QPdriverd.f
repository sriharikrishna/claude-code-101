christen this file      ddd.f
cut here >>>>>>>>>>>>>>>>>>>>

c  This file drives the bqpd code with data supplied from a file.
c  This file should be used in conjunction with denseA.f and denseL.f
c  The data file (e.g. avgas.d) should contain the following:
c       n,m
c       number of nonzero elements (ng) in upper triangle of Hessian matrix G
c       estimate of x
c       vector c
c       successive columns of the matrix A
c               (coefficient vectors of general constraints)
c       vector of n+m lower bounds
c       vector of n+m upper bounds
c       elements of upper triangle of G, each in form  i, j, G_ij
c       mode of operation (0,1 or 2: see parameter mode in bqpd.f)
c       estimate of n active constraints (if mode=2)

c       If ng = 0, program assumes that the Hessian matrix G is a tridiagonal
c       Toeplitz matrix and asks for the diagonal and offdiagonal value.
c       Statements to scale the problem can be obtained by removing the
c       initial 'c' around  line 111. If menu=2 scaling is used, a vector
c       containg the typical magnitudes (>0) of the x variables must be given.

      program driver
      implicit double precision (a-h,o-z)
c     parameter (nmax=3000,mmax=150,nmmax=nmax+mmax,mlp=20,
c    *   m1max=150,kmax=2000,mxg=10000)
c     parameter (nmax=1000,mmax=1000,nmmax=nmax+mmax,mlp=20,
c    *   m1max=500,kmax=50,mxg=10000)
c     parameter (nmax=1775,mmax=821,nmmax=nmax+mmax,mlp=20,
c    *   m1max=821,kmax=0,mxg=0)
c     parameter (nmax=3652,mmax=1441,nmmax=nmax+mmax,mlp=40,
c    *   m1max=1441,kmax=0,mxg=0)
      parameter (nmax=3652,mmax=1441,nmmax=nmax+mmax,mlp=40,
     *   m1max=1441,kmax=1400,mxg=10000)

      double precision a(nmax*(mmax+1)),x(nmax),bl(nmmax),bu(nmmax),
     *  g(nmax),r(nmmax),w(nmmax),e(nmmax),alp(mlp),
     *  ws(mxg+kmax*(kmax+9)/2+nmmax+nmax+m1max*(m1max+1)+3*nmax+m1max)
      integer ls(nmmax),la(1),
     *  lws(1+2*mxg +kmax +nmax+m1max+nmmax),lp(mlp),info(1)

      common/noutc/nout
      common/epsc/eps,tol,emin
      common/iprintc/iprint
      common/wsc/kk,ll,kkk,lll,mxws,mxlws
      common/mxm1c/mxm1
      character *24 problem
      character *56 filename

c      external abort,ieee_handler
c      integer i,ieee_handler,peq
      data x/nmax*0.D0/
c      i=ieee_handler('set','division',abort)
c      i=ieee_handler('set','overflow',abort)
c      i=ieee_handler('set','invalid',abort)
c     character*16 out
c     ii=ieee_flags('get','exception','common',out)
c     if(out.eq.'overflow'.or.out.eq.'invalid'.or.
c    *  out.eq.'division')then
c       print *,'out =',out
c       stop
c     endif

c  storage in ws and lws for denseL.f
      mxws=2+mxg  +kmax*(kmax+9)/2+nmmax+nmax
     *   +m1max*(m1max+1)/2+3*nmax+m1max
      mxlws=1+2*mxg +kmax +nmax+m1max+nmmax
      mxm1=m1max

c  10 write(6,*)'specify problem, and nout (>1, 6=tty)'
c     read(5,*)problem,nout
   10 write(6,*)'specify problem, nout (>1, 6=tty), iprint, mode'
      read(5,*)problem,nout,iprint,mode
      if(nout.eq.1)goto10
      i=index(problem,' ')-1
      nin=1

c dense format
      filename=problem(:i)//'.d'
      open(unit=1,file=filename)
      read(nin,*)n,m,ng
      read(nin,*)(x(i),i=1,n)
      la(1)=n
      read(nin,*)(a(i),i=1,n*(m+1))

      read(nin,*)(bl(i),i=1,n),(bl(n+i),i=1,m)
      read(nin,*)(bu(i),i=1,n),(bu(n+i),i=1,m)
      ll=1+2*ng
      lws(1)=ng
      kmx=kmax
      if(ng.eq.0)then
        kk=2
        write(6,*)
     *    'input Hessian matrix parameters (tridiagonal Toeplitz)'
        read(5,*)ws(1),ws(2)
        if(ws(1).eq.0.D0.and.ws(2).eq.0.D0)kmx=0
      else
        kk=ng
        read(nin,*)(lws(i+1),lws(ng+i+1),ws(i),i=1,ng)
      endif
      read(nin,*)mde
      nk=n
      if(mode.eq.2)then
        read(nin,*)nk
        read(nin,*)(ls(i),i=1,nk)
      endif

      fmin=-1.D10
c     call cscale(n,m,a,la,x,bl,bu,e,1,ifail)
c     read(nin,*)(e(i),i=1,n)
c     call cscale(n,m,a,la,x,bl,bu,e,2,ifail)
      emin=0.D0
      kmx=min(n,kmx)
   30 continue
      k=n-nk
      call bqpd(n,m,k,kmx,a,la,x,bl,bu,f,fmin,g,r,w,e,ls,
     *  alp,lp,mlp,peq,ws,lws,mode,ifail,info,iprint,nout)
      write(nout,*)'Objective = ',f,'   k =',k
      write(nout,*)'ifail = ',ifail,'   Number of pivots = ',info(1)
      if(n.gt.40)stop
      nk=n-k
      write(nout,*)'x = ',(x(i),i=1,n)
      write(nout,*)'active constraints =',(ls(i),i=1,nk)
      write(nout,*)'Lagrange multipliers =',(r(abs(ls(i))),i=1,nk)
      stop
      end

      subroutine gdotx(n,x,ws,lws,v)
      implicit double precision (a-h,o-z)
      dimension x(*),ws(*),lws(0:*),v(*)
      common/noutc/nout
      if(lws(0).eq.0)then
        a=ws(1)
        b=ws(2)
        v(1)=a*x(1)+b*x(2)
        do 1 i=2,n-1
    1   v(i)=a*x(i)+b*(x(i-1)+x(i+1))
        v(n)=b*x(n-1)+a*x(n)
      else
        do i=1,n
          v(i)=0.D0
        enddo
        ng=lws(0)
        do ij=1,ng
          i=lws(ij)
          j=lws(ng+ij)
          v(i)=v(i)+ws(ij)*x(j)
          if(i.ne.j)v(j)=v(j)+ws(ij)*x(i)
        enddo
c       print *,'v =',(v(i),i=1,n)
      endif
      return
      end
