christen this file bqpd.f
cut here >>>>>>>>>>>>>>>>

c  Copyright, University of Dundee (R.Fletcher), June 1996
c  Current version dated  12/09/08

      subroutine bqpd(n,m,k,kmax,a,la,x,bl,bu,f,fmin,g,r,w,e,ls,
     *  alp,lp,mlp,peq,ws,lws,m0de,ifail,info,iprint,nout)
      implicit double precision (a-h,r-z), integer (i-q)

c  This routine finds a KT point for the bounded QP problem

c       minimize    f(x) = ct.x + xt.G.x/2

c       subject to  l <= [I : A]t.x <= u                  (t = transpose)

c  where x and c are n-vectors, G is a symmetric n*n matrix, and A is an
c  n*m matrix. If G is also positive semi-definite then the KT point is a
c  global solution, else usually a local solution. The method may also be
c  used efficiently to solve an LP problem (G=0). A recursive form of an
c  active set method is used, using Wolfe's method to resolve degeneracy.
c  Matrix information is made available and processed by calls to external
c  subroutines. Details of these are given in an auxiliary file named either
c  'denseL.f' or 'sparseL.f'.

c  parameter list  (variables in a line starting with C must be set on entry)
c  **************

C  n     number of variables
C  m     number of general constraints (columns of A)
c  k     dimension of the 'reduced space' obtained by eliminating the active
c        constraints (only to be set if mode>=2). The number of constraints in
c        the active set is n-k
C  kmax  maximum value of k (set kmax=0 iff the problem is an LP problem)
C  a(*)  storage of reals associated with c and A. This storage may be provided
C        in either dense or sparse format. Refer to either denseA.f or sparseA.f
C        for information on how to set a(*) and la(*).
C  la(*) storage of integers associated with c and A
C  x(n)  contains the vector of variables. Initially an estimate of the solution
C        must be set, replaced by the solution (if it exists) on exit.
C  bl(n+m)  vector of lower bounds for variables and general constraints
C  bu(n+m)  vector of upper bounds (use numbers less than about 1.e30, and
C        where possible supply realistic bounds on the x variables)
c  f     returns the value of f(x) when x is a feasible solution
c        Otherwise f stores the sum of constraint infeasibilities
C  fmin  set a strict lower bound on f(x) (used to identify an unbounded QP)
c  g(n)  returns the gradient vector of f(x) when x is feasible
c  r(n+m) workspace: stores residual vectors at different levels
c        The sign convention is such that residuals are nonnegative at
c        a solution (except for multipliers of equality constraints)
c  w(n+m) workspace: stores denominators for ratio tests
c  e(n+m) stores steepest-edge normalization coefficients: if mode>2 then
c        information in this vector from a previous call should not be changed.
c        (In mode = 3 or 5 these values provide approximate coefficients)
c  ls(n+m) stores indices of the active constraints in locations 1:n-k and of
c        the inactive constraints in locations n-k+1:n+m. The simple bounds
c        on the variables are indexed by 1:n and the general constraints by
c        n+1:n+m. The sign of ls(j) indicates whether the lower bound (+) or
c        the upper bound (-) of constraint ls(j) is currently significant.
c        Within the set of active constraints, locations 1:peq store the
c        indices of active equality constraints, and indices peq+1:lp(1)-1
c        are indices of any pseudo-bounds (active constraints which are not
c        at their bound). If mode>=2, the first n-k elements of ls must be set
c        on entry
c  alp(mlp) workspace associated with recursion
c  lp(mlp)  list of pointers to recursion information in ls
C  mlp   maximum number of levels of recursion allowed (typically mlp=20 would
c        usually be adequate but mlp=m is an upper bound
c  peq   pointer to the end of equality constraint indices in ls
c  ws(*) real workspace for gdotx (see below), bqpd and denseL.f (or sparseL.f).
c          bqpd requires kmax*(kmax+9)/2+2*n+m locations. Refer to denseL.f
c          (or sparseL.f) for the number of real locations required by these
c          routines. Set the total number in mxws (see "Common" below).
c  lws(*) integer workspace for gdotx, bqpd and denseL.f (or sparseL.f). bqpd
c          requires kmax locations. Refer to denseL.f (or sparseL.f) for the
c          number of integer locations required by these routines and set the
c          total number in mxlws (see "Common" below).
c        The storage maps for ws and lws are set by the routine stmap below
C  m0de  mode of operation (larger numbers imply extra information):
C          0 = cold start (no other information available, takes simple
C                bounds for the initial active set)
C          1 = as 0 but includes all equality constraints in initial active set
C          2 = user sets n-k active constraint indices in ls(j), j=1,..,n-k.
c                For a general constraint the sign of ls(j) indicates which
c                bound to use. For a simple bound the current value of x is used
C          3 = takes active set and other information from a previous call.
C                Steepest edge weights are approximated using previous values.
C          4 = as 3 but it is also assumed that A (but not G) is unchanged so
C                that factors of the basis matrix stored in ws and lws are valid
C                (changes in the vectors c, l, u and the matrix G are allowed)
C          5 = as 3 but it is assumed that the reduced Hessian matrix Zt.G.Z is
C                unchanged - use with care as this mode allows A (and hence Z)
C                to change
C          6 = as for 4 but it is also assumed that the reduced Hessian matrix
C                is unchanged, e.g. when both A and G are unchanged
C        A local copy (mode) of m0de is made and may be changed by bqpd
c  ifail   outcome of the process
c              0 = solution obtained
c              1 = unbounded problem detected (f(x)<=fmin would occur)
c              2 = bl(i) > bu(i) for some i
c              3 = infeasible problem detected in Phase 1
c              4 = incorrect setting of m, n, kmax, mlp, mode or tol
c              5 = not enough space in lp
c              6 = not enough space for reduced Hessian matrix (increase kmax)
c              7 = not enough space for sparse factors (sparse code only)
c              8 = maximum number of unsuccessful restarts taken
c             >8 = possible use by later sparse matrix codes
c  info  a vector giving information about the progress of the routines for
c        manipulating the basis matrix (see denseL.f or sparseL.f for details)
c        (info(1) always counts the number of pivots taken)
C  iprint  switch for diagnostic printing (0 = off, 1 = summary,
C                 2 = scalar information, 3 = verbose)
C  nout  channel number for output

c  Common
c  ******
c  User information about the lengths of ws and lws is supplied to bqpd in
c    common/wsc/kk,ll,kkk,lll,mxws,mxlws
c  mxws and mxlws must be set to the total length of ws and lws.  kk and ll
c  refer to the length of ws and lws that is used by gdotx. kkk and lll
c  are the numbers of locations used by bqpd and are set by bqpd.

c  User subroutine
c  ***************
c  The user must provide a subroutine to calculate the vector v := G.x from a
c  given vector x. The header of the routine is
c            subroutine gdotx(n,x,ws,lws,v)
c            dimension x(*),ws(*),lws(*),v(*)
c  In the case that G=0 (i.e. kmax=0) the subroutine is not called by bqpd and
c  a dummy routine may be supplied. Otherwise the user may use the parameters
c  ws and lws (see above) for passing real or integer arrays relating to G.
c  Locations ws(1),...,ws(kk) are available to the user for storing any real
c  information to be used by gdotx. Likewise locations lws(1),...,lws(ll) are
c  available for storing any integer information. Default values are kk=ll=0.
c  Any other setting is made by changing  common/wsc/kk,ll,kkk,lll,mxws,mxlws

c  Tolerances and accuracy
c  ***********************
c  bqpd uses tolerance and accuracy information stored in
c     common/epsc/eps,tol,emin
c     common/repc/sgnf,nrep,npiv,nres
c     common/refactorc/nup,nfreq
c  eps must be set to the machine precision (unit round-off) and tol is a
c  tolerance which gives the hoped for relative accuracy in the solution.
c  The tolerance strategy in the code assumes that the problem is well-scaled
c  and a pre-scaling routine cscale is supplied in denseA.f or sparseA.f.
c  The parameter sgnf is used to measure the maximum allowable relative error
c  in two numbers that would be equal in exact arithmetic.
c     Default values are set in block data but can be reset by the user.
c  Suitable values for both single and double precision calculation are given
c  on line 1227. IT IS IMPORTANT THAT THESE MATCH THE PRECISION BEING USED.
c     The code allows one or more refinement steps after the
c  calculation has terminated, to improve the accuracy of the solution,
c  and a fixed number nrep of such repeats is allowed. However the code
c  terminates without further repeats if no more than npiv pivots are taken.
c    When poor agreement is detected in numbers that would be equal in exact
c  arithmetic, and also in other cases of breakdown, the code is restarted,
c  usually in mode 2. The maximum number of unsuccessful restarts allowed
c  is set in nres.
c    The basis matrix may be refactorised on occasions, for example to prevent
c  build-up of round-off in the factors or (when using sparse.f) to improve
c  the sparsity of the factors. The maximum interval between refactorizations
c  is set in nfreq.

      parameter (ncyc=4,ncyc2=8)
      dimension temp(100)
      dimension lcyc(ncyc2)
      dimension a(*),x(*),bl(*),bu(*),g(*),r(*),w(*),e(*),alp(*),ws(*),
     *  la(*),ls(*),lp(*),lws(*),info(*)
      character*32 spaces
      common/bqpdc/irh1,na,na1,nb,nb1,ka1,kb1,kc1,irg1,lu1,lv,lv1,ll1
      common/epsc/eps,tol,emin
      common/vstepc/vstep
      common/repc/sgnf,nrep,npiv,nres
      common/wsc/kk,ll,kkk,lll,mxws,mxlws
      common/refactorc/nup,nfreq
      common/alphac/alpha,rp,pj,qqj,qqj1
      logical psb,degen,eqty
      spaces='         '
      mode=m0de
      iter=0
      info(1)=0
      if(m.lt.0.or.n.le.0.or.mlp.lt.2.or.mode.lt.0.or.mode.gt.6
     *  .or.kmax.lt.0)then
        ifail=4
        return
      endif
      small=max(1.D1*tol,sqrt(eps))
      smallish=max(sqrt(small),1.D1*small)
c     smallish=max(eps/tol,1.D1*small)
      tolp1=tol+1.D0
      nm=n+m
      nmi=nm
      if(iprint.ge.3)then
        write(nout,1000)'lower bounds',(bl(i),i=1,nm)
        write(nout,1000)'upper bounds',(bu(i),i=1,nm)
      endif
      irep=0
      ires=0
      mres=0
      nup=0
      bestf=1.D37
      phase=1
      do i=1,nm
        if(bl(i).gt.bu(i))then
          ifail=2
          return
        endif
      enddo
      if(mode.le.2)then
        do i=1,n
          x(i)=min(bu(i),max(bl(i),x(i)))
        enddo
        call stmap(n,nm,kmax)
        if(mode.eq.0)then
          nk=0
        elseif(mode.eq.1)then
c  collect near-equality c/s
          nk=0
          do i=1,nm
            if(bu(i)-bl(i).le.tol)then
              nk=nk+1
              ls(nk)=i
            endif
          enddo
c         write(nout,*)'number of eqty c/s =',nk
        else
          nk=n-k
        endif
      else
        nk=n-k
      endif
    3 continue
      lev=1
      if(mode.le.3.or.mode.eq.5)then
c  set up factors of basis matrix and permutation vectors
        ifail=mode
        call start_up(n,nm,nmi,a,la,nk,e,ls,ws(lu1),lws(ll1),mode,ifail)
        if(ifail.gt.0)return
        if(mode.le.3)nk=n
      endif
c  collect active near-equality c/s
      peq=0
      do j=1,nk
        i=abs(ls(j))
        if(bu(i)-bl(i).le.tol)then
          if(i.le.n)x(i)=min(bu(i),max(bl(i),x(i)))
          peq=peq+1
          call iexch(ls(peq),ls(j))
        endif
      enddo
      k=n-nk
    5 continue
c  refinement step loop
      mpiv=iter+npiv
      if(mode.eq.0)goto8
      call warm_start(n,nm,nk,a,la,x,bl,bu,r,ls,lws(lv1),ws(lu1),
     *  lws(ll1),ws(na1),vstep)
      if(vstep.gt.tol)mpiv=0
      if(mode.eq.4)then
        do i=lv1,lv+k
          q=lws(i)
          do j=nk+1,nm
            if(abs(ls(j)).eq.q)then
              nk=nk+1
              call iexch(ls(nk),ls(j))
              if(bu(q)-bl(q).le.tol)then
                x(q)=min(bu(q),max(bl(q),x(q)))
                call iexch(ls(nk),ls(lp(1)))
                peq=peq+1
                call iexch(ls(peq),ls(lp(1)))
                lp(1)=lp(1)-1
              endif
              goto6
            endif
          enddo
    6     continue
        enddo
        nk=n
        k=0
      endif
      if(k.gt.0)then
        call hot_start(n,k,kmax,a,la,x,ws(na1),ws(nb1),ws(irh1),
     *    ws(ka1),lws(lv1),w,ls,ws(lu1),lws(ll1),ws,lws,hstep)
        if(hstep.gt.tol)mpiv=0
      endif
c     write(nout,*)'x =',(x(i),i=1,n)
    8 continue
c  calculate residuals of inactive c/s
      call residuals(n,nk+1,nm,a,la,x,bl,bu,r,ls,qj,ninf)
      if(ninf.eq.0.or.k.eq.0)goto9
c  try dual asm iterations
      if(ninf.gt.k)then
        do i=1,n
          x(i)=ws(nb+i)
        enddo
        mode=4
        goto5
      endif
      q=abs(ls(qj))
      call qinv(q,qqv,k,ws(kb1),lws(lv1))
      if(qqv.eq.0)then
        call ztaq(q,n,k,a,la,w,ws(kb1),w,lws(lv1),ws(lu1),lws(ll1))
        call linf(k,ws(kb1),zmx,pv)
        if(zmx.le.tol)then
          mode=4
          goto5
        endif
      endif
      do i=0,k-1
        ws(kc1+i)=ws(kb1+i)
      enddo
      call rtsol(k,kk_,kmax,ws(irh1),ws(kc1))
      sgs=scpr(0.D0,ws(kc1),ws(kc1),k)
      call rsol(k,kk_,kmax,ws(irh1),ws(kc1))
      call zprod(0,n,k,a,la,ws(na1),ws(kc1),lws(lv1),w,ls,ws(lu1),
     *  lws(ll1))
c     write(nout,*)'dual step =',(ws(i),i=na1,na+n)
      if(qqv.eq.0)then
        p=lws(lv+pv)
        if(iprint.ge.2)write(nout,*)'replace',p,' by',q
        call pivot(p,q,n,nmi,a,la,e,ws(lu1),lws(ll1),ifail,info)
        if(ifail.ge.1)then
          if(ifail.ge.2)return
          if(iprint.ge.1)write(nout,*)'dual step fails'
          mode=2
          goto3
        endif
      else
        p=0
        pv=qqv
      endif
c     write(nout,*)'r(q), sgs =',r(q),sgs
      alpha=r(q)/sign(sgs,dble(ls(qj)))
      do i=1,n
        ws(nb+i)=x(i)
        x(i)=x(i)+alpha*ws(na+i)
      enddo
c     write(nout,*)'x =',(x(i),i=1,n)
      call reduce(k,kmax,p,pv,ws(irh1),ws(irg1),lws(lv1),ws(ka1),
     *  ws(kb1),ws(kc1),sgs,.false.)
      nk=nk+1
      call iexch(ls(qj),ls(nk))
      if(bu(q)-bl(q).le.tol)then
        ws(nb+q)=bl(q)
        peq=peq+1
        call iexch(ls(peq),ls(nk))
      endif
c     call  checkrh(n,a,la,k,kmax,ws(irh1),ws(irg1),ws(ka1),lws(lv1),
c    *  ws(lu1),lws(ll1),x,ws,lws,sgs,tol)
      goto8
    9 continue
c  remove redundant equations
      if(mode.eq.1)then
        do j=nm,n+1,-1
          i=abs(ls(j))
          if(r(i).eq.0.D0.and.bu(i)-bl(i).le.tol)then
            call iexch(ls(j),ls(nm))
            nm=nm-1
          endif
        enddo
        if(iprint.ge.1)write(nout,*)nmi-nm,'  redundant equations'
      endif
c  collect pseudo-bounds
      infb=0
      lp(1)=peq+1
      do j=lp(1),nk
        i=abs(ls(j))
        if(i.le.n)then
          if(abs(x(i)-bl(i)).le.tol)then
            x(i)=bl(i)
            ls(j)=i
          elseif(abs(x(i)-bu(i)).le.tol)then
            x(i)=bu(i)
            ls(j)=-i
          else
            call iexch(ls(j),ls(lp(1)))
            if(x(i).lt.bl(i).or.x(i).gt.bu(i))infb=infb+1
            lp(1)=lp(1)+1
          endif
        endif
      enddo
      ninf=ninf+infb
      gtol=tol
c  phase 1 loop
   10 continue
      if(ninf.eq.0)then
        if(iprint.ge.1)write(nout,*)'FEASIBILITY OBTAINED at level 1'
        call setfg2(n,kmax,a,la,x,f,g,ws,lws)
        fold=f
        psb1=lp(1)-peq
        fb=0.D0
        qqq=0
        if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *    ''  level = 1    f ='',E16.8)')info(1),f
      else
        call setfg1(n,nm,a,la,x,bl,bu,f,fb,g,peq,lp(1),nk+1,ls,r)
        if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *    ''  level = 1    f ='',E16.8,''   ninf ='',I4)')
     *    info(1),f,ninf
      endif
c     write(nout,*)'g =',(g(i),i=1,n)
      gnorm=sqrt(scpr(0.D0,g,g,n))
      if(iprint.ge.2)write(nout,*)'gnorm =',gnorm
      gtol=max(tol*gnorm,gtol)
      call newg
      do i=1,ncyc2
        lcyc(i)=-i
      enddo
      goto16
c  start of major iteration
   15 continue
      if(iprint.ge.1)then
        if(ninf.eq.0)then
          if(k.gt.0)then
            write(nout,'(''pivots ='',I5,
     *        ''  level = 1    f ='',E16.8,''   k ='',I4)')info(1),f,k
          else
            write(nout,'(''pivots ='',I5,
     *        ''  level = 1    f ='',E16.8)')info(1),f
          endif
        else
          write(nout,'(''pivots ='',I5,''  level = 1    f ='',
     *      E16.8,''   ninf ='',I4)')info(1),f,ninf
        endif
      endif
      if(ninf.eq.0.and.kmax.gt.0)then
        call gdotx(n,x,ws,lws,g)
        call saipy(1.D0,a,la,0,g,n)
        gnorm=max(gnorm,sqrt(scpr(0.D0,g,g,n)))
        if(iprint.ge.2)write(nout,*)'gnorm =',gnorm
        if(fold-f.le.max(tol,abs(fold)*smallish).and.
     *    psb1.eq.lp(1)-peq)gtol=2.D0*gtol
        fold=f
        psb1=lp(1)-peq
        gtol=max(tol*gnorm,gtol)
        call newg
      endif
c  cycle detection
      do i=1,ncyc
        if(lcyc(i).ne.lcyc(i+ncyc))goto16
      enddo
      gtol=1.D1*gtol
   16 continue
c     if(info(1).ge.117)iprint=3
c     if(info(1).ge.50)stop
c  calculate multipliers
      call fbsub(n,1,nk,a,la,0,g,w,ls,ws(lu1),lws(ll1),.true.)
      call signst(1,nk,.true.,r,w,e,ls,gtol)
c  opposite bound or reset multiplier loop
   20 continue
c  make psb multipliers negative sign
      do j=peq+1,lp(1)-1
        i=abs(ls(j))
        if(r(i).gt.0.D0)then
          r(i)=-r(i)
          ls(j)=-ls(j)
        endif
      enddo
      if(iprint.ge.3)then
        write(nout,1001)'costs vector and indices',
     *    (ls(j),r(abs(ls(j))),j=1,nk)
        write(nout,1000)'steepest edge coefficients',
     *    (e(abs(ls(j))),j=1,nk)
        if(lp(1).gt.1)write(nout,*)'active equality c/s =',peq,
     *    '   pseudo-bounds =',lp(1)-peq-1
      endif
c     call check(n,nk,nmi,kmax,g,a,la,x,bl,bu,r,ls,ws(nb1),f,
c    *  ws,lws,ninf,peq,lp(1),nk+1,1,p,rp)
      if(ninf.eq.0.and.qqq.gt.0)r(qqq)=max(0.D0,r(qqq))
      rp=0.D0
      call optest(peq+1,nk,r,e,ls,rp,pj)
   25 continue
      if(rp.eq.0.D0)then
        if(ninf.gt.0)then
          if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *      ''  level = 1    f ='',E16.8,''   ninf ='',I4)')
     *      info(1),f,ninf
        else
          if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *      ''  level = 1    f ='',E16.8)')info(1),f
        endif
        if(iprint.ge.2)write(nout,*)'OPTIMAL at level 1'
        if(iprint.ge.3)then
c         write(nout,1000)'x variables',(x(i),i=1,n)
          write(nout,1001)'residual vector and indices',
     *      (ls(j),r(abs(ls(j))),j=nk+1,nm)
        endif
        irep=irep+1
        if(irep.le.nrep.and.iter.gt.mpiv)then
          if(iprint.ge.1)write(nout,*)'refinement step #',irep
          mode=6
          goto5
        endif
c     call checkout(n,a,la,ws(lu1),lws(ll1),lws(ll1+n),lws(ll1+n+500))       
c     call checkout(n,a,la,lws(ll1),lws(ll1+n),lws(ll1+2*n),
c    *  lws(ll1+3*n+nmi),lws(ll1+4*n+nmi),lws(ll1+5*n+nmi),
c    *  lws(ll1+6*n+nmi),ws(lu1+5*n),mxws-kk-kkk-5*n,ws(lu1),
c    *  ws(lu1+3*n))
        if(iprint.ge.1)write(nout,*)'total number of restarts =',mres
        if(ninf.gt.0)then
          ifail=3
          return
        endif
c  tidy up x
        do j=lp(1),nk
          i=abs(ls(j))
          if(i.le.n)then
            if(ls(j).ge.0)then
              x(i)=bl(i)
            else
              x(i)=bu(i)
            endif
          endif
        enddo
        do i=1,n
          x(i)=max(min(x(i),bu(i)),bl(i))
        enddo
        do j=nk+1,nm
          i=abs(ls(j))
          if(r(i).eq.0.D0.and.i.le.n)then
            if(ls(j).ge.0)then
              x(i)=bl(i)
            else
              x(i)=bu(i)
            endif
          endif
        enddo
        ifail=0
        return
      endif
      degen=.false.
      psb=pj.lt.lp(1)
      if(psb)lp(1)=lp(1)-1
      call iexch(ls(pj),ls(lp(1)))
   30 continue
      pj=lp(1)
      p=abs(ls(pj))
      qqq=0
c  calculate denominators
      call major_s(p,n,k,kmax,a,la,ws(lu1),lws(ll1),ws(na1),ws(nb1),
     *  ws(irh1),ws(ka1),ws(kb1),ws(kc1),lws(lv1),ws,lws,nk+1,nm,
     *  w,ls,sgs,pp,smx,e(p))
      call signs(nk+1,nm,ls(pj).lt.0,w,ls,tol)
      if(degen)then
c  reset r and w from level 2
        do j=lp(2),nm
          i=abs(ls(j))
          w(i)=min(w(i),0.D0)
          r(i)=0.D0
        enddo
c       call check(n,nk,nmi,kmax,g,a,la,x,bl,bu,r,ls,ws(nb1),f,
c    *    ws,lws,ninf,peq,lp(1),nk+1,1,p,rp)
      endif
c  check consistency of r(p)
      rp=scpr(0.D0,g,ws(na1),n)
      if(ls(pj).lt.0)rp=-rp
      if(abs(rp-r(p)).ge.-sgnf*r(p))then
        call refine_s(p,nk,n,a,la,ls,ws(na1),ws(nb1),ws(lu1),lws(ll1))
c       write(nout,*)'norm_ds =',sqrt(scpr(0.D0,ws(nb1),ws(nb1),n))
        rp=scpr(0.D0,g,ws(na1),n)
        if(ls(pj).lt.0)rp=-rp
        if(iprint.ge.1)
     *    write(nout,*)'new and old values of r(p)',rp,r(p),e(p)
        if(abs(rp).le.gtol*e(p))then
c         if(iprint.ge.1)write(nout,*)'refined r(p) is negligible',rp
          if(psb)lp(1)=pj+1
          r(p)=0.D0
          goto20
        endif
c       if(abs(rp-r(p)).ge.-sgnf*r(p))goto98
        if(abs(rp-r(p)).ge.-sgnf*r(p))then
c         if(iprint.ge.1)write(nout,*)'refined r(p) is negligible',rp
          if(psb)lp(1)=pj+1
          r(p)=0.D0
          goto20
        endif
        r(p)=rp
      endif
      rp=r(p)
      if(ninf.eq.0.and.sgs.gt.eps)then
        ff=f-5.D-1*(rp/sgs)*rp
        if(ff.ge.f*tolp1)then
          if(iprint.ge.1)write(nout,*)
     *      'minimizing step fails to reduce f enough: truncate r(p)'
          if(psb)lp(1)=pj+1
          r(p)=0.D0
          goto20
        endif
      endif
   35 continue
      if(iprint.ge.3)then
        write(nout,1000)'x variables',(x(i),i=1,n)
        write(nout,1001)'residual vector and indices',
     *    (ls(j),r(abs(ls(j))),j=nk+1,nm)
        write(nout,1000)'denominators',(w(abs(ls(j))),j=nk+1,nm)
      endif
      sml=smallish
   40 continue
c  line search
      if(psb)then
        if(ls(pj).gt.0)then
          if(x(p).gt.bu(p))then
            amax=1.D37
          elseif(x(p).lt.bl(p))then
            amax=bl(p)-x(p)
          else
            amax=bu(p)-x(p)
          endif
        else
          if(x(p).lt.bl(p))then
            amax=1.D37
          elseif(x(p).gt.bu(p))then
            amax=x(p)-bu(p)
          else
            amax=x(p)-bl(p)
          endif
        endif
      else
        amax=bu(p)-bl(p)
      endif
      qqj=pj
      if(ninf.eq.0)then
        if(sgs*amax.ge.-rp)then
          amax=-rp/sgs
          qqj=0
        endif
      endif
c  level 1 ratio test
      call ratio(nk+1,nm,r,w,bl,bu,ls,amax,alpha,qqj,qqj1)
c  test update of f
      if(ninf.eq.0)then
        ff=f+alpha*(rp+5.D-1*alpha*sgs)
        if(ff.le.fmin)then
          irep=irep+1
          if(irep.le.nrep.and.iter.gt.mpiv)then
            mode=4
            if(sgs.gt.0.D0)mode=6
            if(iprint.ge.1)write(nout,*)
     *        'unbounded solution identified: refinement step #',irep
            goto5
          else
            ifail=1
c  tidy up x
            do i=1,n
              x(i)=max(min(x(i),bu(i)),bl(i))
            enddo
            do j=nk+1,nm
              i=abs(ls(j))
              if(r(i).eq.0.D0.and.i.le.n)then
                if(ls(j).ge.0)then
                  x(i)=bl(i)
                else
                  x(i)=bu(i)
                endif
              endif
            enddo
            return
          endif
        endif
      else
        ff=f+alpha*rp
        if(qqj1.eq.0.and.ff.le.-small)then
          if(iprint.ge.1)write(nout,*)'negative phase 1 objective'
          if(psb)lp(1)=pj+1
          r(p)=0.D0
          goto20
        endif
      endif
      call ishift(lcyc,ncyc2-1,1)
      lcyc(ncyc2)=p
      if(qqj.eq.0)then
        if(iprint.ge.2)write(nout,*)'line minimum found:  alpha =',
     *      alpha,'   p =',p
        goto50
      endif
      qq=abs(ls(qqj))
      if(iprint.ge.2)then
        write(nout,*)'alpha =',alpha,'   p =',p,'   qq =',qq
        write(nout,*)'r(p),r(qq),w(qq) =',r(p),r(qq),w(qq)
      endif
c  test significance of w(qq)
      if(k.eq.0.and.qqj.ne.pj.and.abs(w(qq)).le.sml)then
        call refine_s(p,nk,n,a,la,ls,ws(na1),ws(nb1),ws(lu1),lws(ll1))
c       write(nout,*)'norm_ds =',sqrt(scpr(0.D0,ws(nb1),ws(nb1),n))
        wqq=w(qq)
        sml=small
        call reset_w(nk+1,nm,ls(pj).lt.0,n,a,la,w,ls,ws(na1),sml)
        if(degen)then
          do j=lp(2),nm
            i=abs(ls(j))
            w(i)=min(w(i),0.D0)
          enddo
        endif
        if(iprint.ge.1)
     *    write(nout,*)'new and old values of w(qq)',w(qq),wqq
        if(iprint.ge.3)write(nout,1000)
     *    'refined denominators',(w(abs(ls(j))),j=nk+1,nm)
        if(wqq*w(qq).le.0.D0)then
          w(qq)=0.D0
          goto40
        endif
        if(nup.gt.0.and.abs(wqq-w(qq)).ge.sgnf*abs(w(qq)))then
          call refactor(n,nm,a,la,ws(lu1),lws(ll1),ifail)
          if(iprint.gt.1)write(nout,*)'refactor: ifail =',ifail
          if(ifail.eq.1)goto98
          if(ifail.gt.0)return
        endif
c       if(w(qq).eq.0.D0)goto40
c       if(abs(wqq-w(qq)).ge.sgnf*abs(w(qq)))goto98
      endif
      eqty=bu(qq)-bl(qq).le.tol
      if(ff.ge.f.and.qqj.ne.pj.and..not.(psb.or.eqty))then
c  potential degeneracy block at level 1
        if(k.gt.0)then
          call qinv(qq,qqv,k,ws(kb1),lws(lv1))
          if(qqv.gt.0)goto50
          call ztaq(qq,n,k,a,la,w,ws(kb1),w,lws(lv1),ws(lu1),lws(ll1))
          call linf(k,ws(kb1),zmx,pv)
c         call ztaq(qq,n,k,a,la,w,temp,w,lws(lv1),ws(lu1),lws(ll1))
c         call linf(k,temp,zmx,pv)
          if(zmx.gt.tol)goto50
        endif
        if(abs(r(qq)).gt.tol.or.(r(qq).ge.0.D0.and.w(qq).lt.0.D0))then
          if(iprint.gt.1)write(nout,*)'* truncate r(p)'
          if(psb)lp(1)=pj+1
          r(p)=0.D0
          goto20
        endif
        plev=nm+1
        if(k.eq.0)then
          do j=nm,nk+1,-1
            i=abs(ls(j))
            if(r(i).eq.0.D0)then
              plev=plev-1
              call iexch(ls(j),ls(plev))
              if(bu(i)-bl(i).gt.tol)r(i)=1.D0
            endif
          enddo
        else
          if(degen)then
            plev=lp(2)-1
          else
            plev=nm
          endif
          call iexch(ls(qqj),ls(plev))
          i=abs(ls(plev))
          if(bu(i)-bl(i).gt.tol)r(i)=1.D0
        endif
        if(mlp.lt.3)then
          ifail=5
          return
        endif
        lp(2)=plev
        lev=2
        alp(1)=f
        f=0.D0
        if(iprint.ge.2)write(nout,*)'degeneracy: increase level to 2'
        qj=pj
        q=p
        if(iprint.ge.1)write(nout,'(''pivots ='',I5,''     level = 2'',
     *    ''    f ='',E16.8)')info(1),f
        goto86
      endif
      df=f-ff
      if(k.gt.0.and.qqj.ne.pj)goto50
   45 continue
      if(.not.eqty)qqq=qq
      if(qqj.ne.pj)then
        if(iprint.ge.2)write(nout,*)'replace',p,' by',qq
        call pivot(p,qq,n,nmi,a,la,e,ws(lu1),lws(ll1),ifail,info)
        if(ifail.ge.1)then
          if(ifail.ge.2)return
c         call iexch(ls(pj),ls(qqj))
          if(iprint.ge.1)write(nout,*)'near singularity in pivot (1)'
          goto98
        endif
      endif
c  update f, x, and r
      call setrp(psb,p.le.n,alpha,x(p),bl(p),bu(p),g(p),rpu,ls(pj),
     *  infb,fb,tol)
      if(alpha.gt.0.D0)then
        iter=iter+1
        call update(n,nk+1,nm,a,la,g,r,w,x,bl,bu,ls,alpha,n_inf,fff,tol)
        fff=fff+fb
        n_inf=n_inf+infb
        if(rpu.lt.0.D0)then
          fff=fff-rpu
          n_inf=n_inf+1
        endif
        if(ninf.gt.0)then
          if(n_inf.lt.ninf)then
            ff=fff
            gnorm=sqrt(scpr(0.D0,g,g,n))
            if(iprint.ge.2)write(nout,*)'gnorm =',gnorm
            gtol=max(tol*gnorm,gtol)
            call newg
          else
            ff=min(ff,fff)
          endif
          if(ff.gt.0.D0.and.ff.lt.smallish.and.f.ge.smallish)then
            call iexch(ls(pj),ls(qqj))
            mode=6
            goto99
          endif
        endif
      else
        n_inf=ninf
      endif
      f=ff
      if(qqj.eq.pj)then
c  opposite bound comes active
        if(ninf.eq.0)then
          if(kmax.gt.0)goto15
          if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *      ''  level = 1    f ='',E16.8)')info(1),f
        elseif(f.le.0.D0)then
          ninf=0
          do j=nk+1,nm
            i=abs(ls(j))
            r(i)=max(r(i),0.D0)
          enddo
          goto10
        elseif(n_inf.lt.ninf)then
          ninf=n_inf
          goto15
        else
          if(iprint.ge.1)write(nout,'(''pivots ='',I5,
     *      ''  level = 1    f ='',E16.8,''   ninf ='',I4)')
     *      info(1),f,ninf
        endif
        r(p)=-rp
        goto20
      endif
      r(p)=rpu
      call iexch(ls(pj),ls(qqj))
      if(eqty)then
        peq=peq+1
        call iexch(ls(peq),ls(pj))
        lp(1)=pj+1
      endif
      if(ninf.eq.0)then
        goto15
      elseif(f.le.0.D0)then
        ninf=0
        do j=nk+1,nm
          i=abs(ls(j))
          r(i)=max(r(i),0.D0)
        enddo
        goto10
      elseif(n_inf.lt.ninf)then
        ninf=n_inf
        goto15
      endif
      goto15
c  code for QP-like iterations
   50 continue
      iter=iter+1
c  set reduced gradient
      do i=irg1,irg1+k-1
        ws(i)=0.D0
      enddo
      if(ls(pj).ge.0)then
        ws(irg1+k)=rp+alpha*sgs
      else
        ws(irg1+k)=-rp-alpha*sgs
      endif
c  update f, x, r
      f=ff
      call setrp(psb,p.le.n,alpha,x(p),bl(p),bu(p),g(p),r(p),ls(pj),
     *  infb,fb,tol)
      if(alpha.gt.0.D0)
     *  call update(n,nk+1,nm,a,la,g,r,w,x,bl,bu,ls,alpha,n_inf,ff,tol)
      if(k.ge.kmax)then
        ifail=6
        return
      endif
c  free constraint p
      call iexch(ls(pj),ls(nk))
      nk=nk-1
      call extend(k,kmax,p,ws(irh1),ws(ka1),ws(kb1),lws(lv1),sgs)
      if(p.gt.n.or.smx.gt.4.D0)then
        call ztaq(pp,n,k,a,la,w,ws(kb1),w,lws(lv1),ws(lu1),lws(ll1))
        if(iprint.ge.2)write(nout,*)'for stability, replace',p,' by',pp
        call pivot(p,pp,n,nmi,a,la,e,ws(lu1),lws(ll1),ifail,info)
        if(ifail.ge.1)then
          if(ifail.ge.2)return
          if(iprint.ge.1)write(nout,*)'near singularity in pivot (2)'
          goto98
        endif
        call revise(k,kmax,ws(irh1),ws(irg1),lws(lv1),pp,ws(ka1),
     *    ws(kb1),ws(kc1),sgs)
      endif
c     call  checkrh(n,a,la,k,kmax,ws(irh1),ws(irg1),ws(ka1),lws(lv1),
c    *  ws(lu1),lws(ll1),x,ws,lws,sgs,tol)
      if(qqj.eq.0)goto15
c     write(nout,*)'reduced gradient =',(ws(i),i=irg1,irg1+k-1)
c  minor iteration loop
   60 continue
      call qinv(qq,qqv,k,ws(kb1),lws(lv1))
      if(qqv.eq.0)then
        call ztaq(qq,n,k,a,la,w,ws(kb1),w,lws(lv1),ws(lu1),lws(ll1))
        call linf(k,ws(kb1),zmx,pv)
        if(zmx.eq.0.D0)then
          if(iprint.ge.1)write(nout,*)'no available pivot in V-list'
          goto98
        endif
        p=lws(lv+pv)
        if(iprint.ge.2)write(nout,*)'replace',p,' by',qq
        call pivot(p,qq,n,nmi,a,la,e,ws(lu1),lws(ll1),ifail,info)
        if(ifail.ge.1)then
          if(ifail.ge.2)return
          if(iprint.ge.1)write(nout,*)'near singularity in pivot (3)'
          goto98
        endif
      else
        p=0
        pv=qqv
        zmx=1.D0
      endif
      call reduce(k,kmax,p,pv,ws(irh1),ws(irg1),lws(lv1),ws(ka1),
     *  ws(kb1),ws(kc1),sgs,.true.)
c     write(nout,*)'reduced gradient =',(ws(i),i=irg1,irg1+k-1)
      nk=nk+1
      call iexch(ls(nk),ls(qqj))
      if(eqty)then
        call iexch(ls(lp(1)),ls(nk))
        peq=peq+1
        call iexch(ls(peq),ls(lp(1)))
        lp(1)=lp(1)+1
      endif
      if(k.eq.0)goto15
      if(iprint.ge.2)write(nout,*)'minor iteration loop'
      if(iprint.ge.1)write(nout,'(''pivots ='',I5,''  level = 1    f =''
     *  ,E16.8,''   k ='',I4,''   minor'')')info(1),f,k
c     call  checkrh(n,a,la,k,kmax,ws(irh1),ws(irg1),ws(ka1),lws(lv1),
c    *  ws(lu1),lws(ll1),x,ws,lws,sgs,tol)
      call minor_s(n,k,kmax,a,la,ws(lu1),lws(ll1),ws(na1),ws(irh1),
     *  ws(ka1),ws(irg1),ws(kc1),lws(lv1),nk+1,nm,w,ls,rp,sgs)
      if(rp.eq.0.D0.and.sgs.ge.0.D0)goto15
      call signs(nk+1,nm,.false.,w,ls,tol)
      if(iprint.ge.3)then
        write(nout,1000)'x variables',(x(i),i=1,n)
        write(nout,1001)'residual vector and indices',
     *    (ls(j),r(abs(ls(j))),j=nk+1,nm)
        write(nout,1000)'denominators',(w(abs(ls(j))),j=nk+1,nm)
      endif
      if(sgs.gt.0.D0)then
        amax=1.D0
      else
        t=2.D0*(f-fmin)
        amax=t/(sqrt(rp**2-t*sgs)+rp)
      endif
      alpha=amax
      qqj=0
      call ratio(nk+1,nm,r,w,bl,bu,ls,amax,alpha,qqj,qqj1)
      f=min(f-alpha*(rp-5.D-1*sgs*alpha),f)
      if(qqj.eq.0)then
        if(sgs.le.0.D0.or.f.le.fmin)then
          irep=irep+1
          if(irep.le.nrep.and.iter.gt.mpiv)then
            mode=4
            if(sgs.gt.0.D0)mode=6
            if(iprint.ge.1)write(nout,*)
     *        'unbounded solution identified: refinement step #',irep
            goto5
          else
            ifail=1
            return
          endif
        else
          if(iprint.ge.2)
     *      write(nout,*)'line minimum obtained:  alpha =',alpha
          qqj=0
        endif
      endif
      call update(n,nk+1,nm,a,la,g,r,w,x,bl,bu,ls,alpha,n_inf,ff,tol)
      if(qqj.eq.0)goto15
      call rgup(k,ws(ka1),ws(irg1),alpha,sgs)
      qq=abs(ls(qqj))
      eqty=bu(qq)-bl(qq).le.tol
      if(iprint.ge.2)write(nout,*)'alpha =',alpha,'   amax =',amax,
     *  '   qq =',qq
      goto60
c  recursive code for resolving degeneracy (Wolfe's method)
   80 continue
c     if(info(1).ge.117)iprint=3
c     if(info(1).ge.120)stop
c  calculate multipliers
      call fbsub(n,1,nk,a,la,0,g,w,ls,ws(lu1),lws(ll1),.true.)
      call signst(1,nk,.true.,r,w,e,ls,gtol)
c  opposite bound or reset multiplier loop
   82 continue
      if(iprint.ge.3)then
        write(nout,1001)'costs vector and indices',
     *    (ls(j),r(abs(ls(j))),j=1,nk)
c       write(nout,1000)'steepest edge coefficients',
c    *    (e(abs(ls(j))),j=1,nk)
        if(lp(1).gt.1)write(nout,*)'active equality c/s =',peq,
     *    '   pseudo-bounds =',lp(1)-peq-1
      endif
c  psb contribution to optimality test
      do j=peq+1,lp(1)-1
        i=abs(ls(j))
        if(r(i).gt.0.D0)then
          r(i)=-r(i)
          ls(j)=-ls(j)
        endif
      enddo
      call optest(peq+1,nk,r,e,ls,rp,pj)
c  84 continue
      if(rp.eq.0.D0.or.pj.lt.lp(1))then
        if(iprint.ge.2)write(nout,*)'return to level 1'
        lev=1
        f=alp(1)
        do j=lp(2),nm
          r(abs(ls(j)))=0.D0
        enddo
        lev=1
        if(rp.eq.0.D0)goto25
        goto20
      endif
      call iexch(ls(pj),ls(lp(1)))
      pj=lp(1)
      p=abs(ls(pj))
      call major_s(p,n,k,0,a,la,ws(lu1),lws(ll1),ws(na1),ws(nb1),
     *  ws(irh1),ws(ka1),ws(kb1),ws(kc1),lws(lv1),ws,lws,lp(lev),nm,
     *  w,ls,sgs,pp,smx,e(p))
      call signs(lp(lev),nm,ls(pj).lt.0,w,ls,tol)
c  check consistency of r(p)
      rp=scpr(0.D0,g,ws(na1),n)
      if(ls(pj).lt.0)rp=-rp
      if(abs(rp-r(p)).ge.-sgnf*r(p))then
        call refine_s(p,nk,n,a,la,ls,ws(na1),ws(nb1),ws(lu1),lws(ll1))
c       write(nout,*)'norm_ds =',sqrt(scpr(0.D0,ws(nb1),ws(nb1),n))
        rp=scpr(0.D0,g,ws(na1),n)
        if(ls(pj).lt.0)rp=-rp
        if(iprint.ge.1)
     *    write(nout,*)'new and old values of r(p)',rp,r(p),e(p)
        if(-rp.le.gtol*e(p))then
c         if(iprint.ge.1)write(nout,*)'refined r(p) is negligible',rp
          r(p)=0.D0
          goto82
        endif
c       if(abs(rp-r(p)).ge.-sgnf*r(p))goto98
        if(abs(rp-r(p)).ge.-sgnf*r(p))then
          if(iprint.ge.1)write(nout,*)'refined r(p) is negligible',rp
          r(p)=0.D0
          goto82
        endif
        r(p)=rp
      endif
      rp=r(p)
   86 continue
      if(iprint.ge.3)then
        write(nout,1001)'residual vector and indices',
     *    (ls(j),r(abs(ls(j))),j=lp(lev),nm)
        write(nout,1000)'denominators',(w(abs(ls(j))),j=lp(lev),nm)
      endif
      sml=smallish
   88 continue
c  ratio test at higher levels
      alpha=1.D37
      qqj=0
      do 90 j=lp(lev),nm
        i=abs(ls(j))
        wi=w(i)
        if(wi.le.0.D0)goto90
        if(r(i).lt.0.D0)goto90
        z=r(i)/wi
        if(z.ge.alpha)goto90
        alpha=z
        qqj=j
   90 continue
      if(qqj.eq.0)then
        do j=lp(lev),nm
          r(abs(ls(j)))=0.D0
        enddo
        jmin=max(nk+1,lp(lev-1))
        do j=jmin,lp(lev)-1
          i=abs(ls(j))
          if(i.le.n)then
            w(i)=ws(na+i)
          else
            w(i)=aiscpr(n,a,la,i-n,ws(na1),0.D0)
          endif
        enddo
        call signs(jmin,lp(lev)-1,ls(pj).lt.0,w,ls,tol)
        lev=lev-1
        f=alp(lev)
        if(iprint.ge.2)write(nout,*)'UNBOUNDED:   p =',p,
     *    '   return to level',lev
        if(lev.gt.1)goto86
        degen=.true.
        if(kmax.ne.0.and.ninf.eq.0)goto30
        goto35
      endif
      qq=abs(ls(qqj))
c  test significance of w(qq)
      if(abs(w(qq)).le.sml)then
        call refine_s(p,nk,n,a,la,ls,ws(na1),ws(nb1),ws(lu1),lws(ll1))
c       write(nout,*)'norm_ds =',sqrt(scpr(0.D0,ws(nb1),ws(nb1),n))
        wqq=w(qq)
        sml=small
        call reset_w(lp(lev),nm,ls(pj).lt.0,n,a,la,w,ls,ws(na1),sml)
        if(iprint.ge.1)
     *    write(nout,*)'new and old values of w(qq)',w(qq),wqq,qq
        if(iprint.ge.3)write(nout,1000)
     *    'refined denominators',(w(abs(ls(j))),j=lp(lev),nm)
c       if(w(qq).eq.0.D0)goto88
        if(wqq*w(qq).le.0.D0)then
          w(qq)=0.D0
          goto88
        endif
        if(nup.gt.0.and.abs(wqq-w(qq)).ge.sgnf*abs(w(qq)))then
          call refactor(n,nm,a,la,ws(lu1),lws(ll1),ifail)
          if(iprint.gt.1)write(nout,*)'refactor: ifail =',ifail
          if(ifail.eq.1)goto98
          if(ifail.gt.0)return
        endif
c       if(abs(wqq-w(qq)).ge.sgnf*abs(w(qq)))goto98
      endif
      ff=f+alpha*rp
      if(iprint.ge.2)then
        write(nout,*)'alpha =',alpha,'   p =',p,'   qq =',qq
        write(nout,*)'r(p),r(qq),w(qq) =',r(p),r(qq),w(qq)
      endif
c  test for equality c/s
      if(bu(qq)-bl(qq).le.tol)then
        do j=lp(2),nm
          r(abs(ls(j)))=0.D0
        enddo
        lev=1
        f=alp(1)
        ff=f
        alpha=0.D0
        eqty=.true.
        if(iprint.ge.2)write(nout,*)'EQTY:   p =',p,'   qq =',qq,
     *    '   return to level 1'
        goto45
      endif
      if(ff.ge.f)then
c  potential degeneracy block at level lev
        if(r(qq).gt.tol)then
          if(iprint.gt.1)write(nout,*)'** truncate r(p)'
          r(p)=0.D0
          goto82
        endif
        if(lev+2.gt.mlp)then
          ifail=5
          return
        endif
        r(qq)=0.D0
        plev=nm+1
        do j=nm,lp(lev),-1
          i=abs(ls(j))
          if(r(i).eq.0.D0)then
            plev=plev-1
            call iexch(ls(j),ls(plev))
            if(bu(i)-bl(i).gt.tol)r(i)=1.D0
          endif
        enddo
        alp(lev)=f
        f=0.D0
        lev=lev+1
        lp(lev)=plev
        if(iprint.ge.2)write(nout,*)
     *    'degeneracy: increase level to ',lev       
        if(iprint.ge.1)write(nout,'(''pivots ='',I5,A,''level ='',
     *    I2,''    f ='',E16.8)')info(1),spaces(:3*lev-1),lev,f
        goto86
      endif
      iter=iter+1
      if(iprint.ge.2)write(nout,*)'replace',p,' by',qq
      call pivot(p,qq,n,nmi,a,la,e,ws(lu1),lws(ll1),ifail,info)
      if(ifail.ge.1)then
        if(ifail.ge.2)return
c       call iexch(ls(pj),ls(qqj))
        if(iprint.ge.1)write(nout,*)'near singularity in pivot (4)'
        goto98
      endif
c  update r and f
      do j=lp(lev),nm
        i=abs(ls(j))
        ri=r(i)-alpha*w(i)
        if(abs(ri).le.tol)ri=0.D0
        r(i)=ri
      enddo
      f=ff
c  exchange a constraint
      r(p)=alpha
      if(r(p).le.tol)r(p)=0.D0
      call iexch(ls(pj),ls(qqj))
      if(iprint.ge.1)write(nout,'(''pivots ='',I5,A,''level ='',
     *    I2,''    f ='',E16.8)')info(1),spaces(:3*lev-1),lev,f
      goto80
c  restart sequence
   98 continue
      k=0
      nk=n
      mode=2
      mres=mres+1
      if(iprint.ge.1)write(nout,*)'major restart #',mres
   99 continue
      if(lev.gt.1)f=alp(1)
      if(ninf.eq.0)then
        if(phase.eq.1.or.f.le.bestf-smallish*gnorm)then
          bestf=f
          phase=2
          ires=0
        else
          ires=ires+1
        endif
      elseif(phase.eq.1.and.f.lt.bestf-smallish*gnorm)then
        bestf=f
        ires=0
      else
        ires=ires+1
      endif
      if(ires.le.nres)goto3
      ifail=8
      return
 1000 format(a/(e16.5,4e16.5))
 1001 format(a/(i4,1x,e11.5,4(i4,1x,e11.5)))
c1000 format(a/(e18.8,3e19.8))
c1001 format(a/(i3,1x,e14.8,3(i4,1x,e14.8)))
      end

      block data defaults
      implicit double precision (a-h,o-z)
      common/epsc/eps,tol,emin
      common/repc/sgnf,nrep,npiv,nres
      common/refactorc/nup,nfreq
      common/wsc/kk,ll,kkk,lll,mxws,mxlws
c  single length tolerances
c     data  eps,   tol, emin, sgnf, nrep, npiv, nres, nfreq, kk, ll
c    *   /6.D-8, 1.D-6, 0.D0, 1.D-1,  2,    3,    3,   100,   0,  0/
c  double length tolerances
      data  eps,    tol,   emin, sgnf, nrep, npiv, nres, nfreq, kk, ll 
     * /1111.D-19, 1.D-12, 0.D0, 1.D-4,  2,    3,   2,   500,   0,  0/
      end

      subroutine ratio(jmin,jmax,r,w,bl,bu,ls,amax,alpha,qqj,qqj1)
c  two-sided ratio test
      implicit double precision (a-h,r-z), integer (i-q)
      common/noutc/nout
      dimension r(*),w(*),bl(*),bu(*),ls(*)
c     write(nout,*)'qqj,alpha,amax',qqj,alpha,amax
      alpha1=1.D37
      qqj1=0
      do 1 j=jmin,jmax
        i=abs(ls(j))
        wi=w(i)
        if(wi.eq.0.D0)goto1
        ri=r(i)
        if(wi.gt.0.D0)then
          if(ri.lt.0.D0)goto1
          z=ri/wi
        else
          if(ri.lt.0.D0)then
            z=ri/wi
            if(z.lt.alpha1)then
              alpha1=z
              qqj1=j
            endif
          endif
          z=(bl(i)-bu(i)+ri)/wi
        endif
        if(z.ge.amax)goto1
        amax=z
        qqj=j
    1 continue
c     write(nout,*)'qqj,qqj1,alpha1,amax',qqj,qqj1,alpha1,amax
      if(qqj1.gt.0.and.alpha1.le.amax)then
        do 2 j=jmin,jmax
          i=abs(ls(j))
          wi=w(i)
          if(wi.ge.0.D0)goto2
          ri=r(i)
          if(ri.lt.0.D0)then
            z=ri/wi
            if(z.gt.alpha1.and.z.le.amax)then
              alpha1=z
              qqj1=j
            endif
          endif
    2   continue
        alpha=alpha1
        qqj=qqj1
      else
        qqj1=0
        alpha=amax
      endif
c     write(nout,*)'alpha,amax',alpha,amax
      return
      end

      subroutine update(n,jmin,nm,a,la,g,r,w,x,bl,bu,ls,
     *  alpha,n_inf,f,tol)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),g(*),r(*),w(*),x(*),bl(*),bu(*),ls(*)
      n_inf=0
      f=0.D0
      do j=jmin,nm
        i=abs(ls(j))
        y=alpha*w(i)
        if(y.ne.0.D0)then
          if(i.le.n)then
            if(ls(j).gt.0)then
              x(i)=x(i)-y
            else
              x(i)=x(i)+y
            endif
          endif
          ri=r(i)-y
          s=sign(1.D0,dble(ls(j)))
          if(y.lt.0.D0)then
            ro=bu(i)-bl(i)-ri
            if(ro.lt.ri)then
              ri=max(ro,0.D0)
              w(i)=-w(i)
              ls(j)=-ls(j)
            endif
          endif
          if(abs(ri).le.tol)ri=0.D0
          if(r(i).lt.0.D0)then
            if(ri.ge.0.D0)then
c  remove contribution to gradient
              if(i.gt.n)then
                call saipy(s,a,la,i-n,g,n)
              else
                g(i)=g(i)+s
              endif
            else
              n_inf=n_inf+1
              f=f-ri
            endif
          endif
          r(i)=ri
        elseif(r(i).lt.0.D0)then
          n_inf=n_inf+1
          f=f-r(i)
        endif
      enddo
      return
      end

      subroutine optest(jmin,jmax,r,e,ls,rp,pj)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension r(*),e(*),ls(*)
      rp=0.D0
      do 1 j=jmin,jmax
        i=abs(ls(j))
        if(e(i).eq.0.D0)print *,'e(i).eq.0.D0: i =',i
        ri=r(i)/e(i)
        if(ri.ge.rp)goto1
        rp=ri
        pj=j
    1 continue
      return
      end

      subroutine signs(jmin,jmax,plus,w,ls,tol)
      implicit double precision (a-h,o-z)
      dimension w(*),ls(*)
      logical plus
c  change signs as necessary
      do 1 j=jmin,jmax
        i=abs(ls(j))
        wi=w(i)
        if(wi.eq.0.D0)goto1
        if(abs(wi).le.tol)then
          w(i)=0.D0
          goto1
        endif
        if(plus.neqv.ls(j).ge.0)then
          w(i)=-wi
        endif
    1 continue
      return
      end

      subroutine signst(jmin,jmax,plus,r,w,e,ls,tol)
      implicit double precision (a-h,o-z)
      dimension r(*),w(*),e(*),ls(*)
      logical plus
c  transfer with sign change as necessary
      do j=jmin,jmax
        i=abs(ls(j))
        if(abs(w(i)).le.e(i)*tol)then
          r(i)=0.D0
        elseif(plus.eqv.ls(j).ge.0)then
          r(i)=w(i)
        else
          r(i)=-w(i)
        endif
      enddo
      return
      end

      subroutine stmap(n,nm,kmax)
c  set storage map for workspace in bqpd and auxiliary routines
      implicit double precision (a-h,r-z), integer (i-q)
      common/wsc/kk,ll,kkk,lll,mxws,mxlws
      common/bqpdc/irh1,na,na1,nb,nb1,ka1,kb1,kc1,irg1,lu1,lv,lv1,ll1
c  real storage (ws)
      kkk=kmax*(kmax+9)/2+nm+n
c  (number of real locations required by bqpd)
c  slot for user workspace for gdotx
      irh1=kk+1
c  slot of length kmax*(kmax+1)/2 for reduced Hessian matrix
      na1=irh1+kmax*(kmax+1)/2
      na=na1-1
c  scratch slots of length n+m, n and four of length kmax follow
      nb1=na1+nm
      nb=nb1-1
      ka1=nb1+n
      kb1=ka1+kmax
      kc1=kb1+kmax
      irg1=kc1+kmax
      lu1=irg1+kmax
c  remaining space for use by denseL.f or sparseL.f
c  integer storage (lws)
      lll=kmax
c  (number of integer locations required by bqpd)
c  slot for user workspace for gdotx
      lv=ll
      lv1=ll+1
c  slot for V-list
      ll1=lv1+kmax
c  remaining space for use by denseL.f or sparseL.f
      return
      end

      subroutine check(n,nk,nm,kmax,g,a,la,x,bl,bu,r,ls,an,f,
     *  ws,lws,ninf,peq,lp1,nk1,lev,p,alp2)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension g(*),a(*),la(*),x(*),bl(*),bu(*),r(*),ls(*),
     *  an(*),ws(*),lws(*)
      common/noutc/nout
      common/epsc/eps,tol,emin
      if(lev.eq.2)then
        do i=1,n
          an(i)=g(i)
        enddo
        e=alp2*sign(1.D0,dble(p))
        i=abs(p)
        if(i.le.n)then
          an(i)=an(i)-e
        else
          call saipy(-e,a,la,i-n,an,n)
        endif
        goto1
      endif
      j=nm*(nm+1)/2
      do i=1,nm
        j=j-abs(ls(i))
      enddo
      if(j.ne.0)write(nout,*)'indexing error'
      e=0.
      do j=nk+1,nm
        i=abs(ls(j))
        if(i.le.n)then
          s=x(i)
        else
          s=aiscpr(n,a,la,i-n,x,0.D0)
        endif
        if(ls(j).gt.0)then
          s=r(i)-s+bl(i)
        else
          s=r(i)+s-bu(i)
        endif
        if(abs(s).le.tol*max(1.D0,abs(r(i))))s=0.D0
        if(abs(s).gt.e)then
          e=abs(s)
          ie=i
        endif
      enddo
      if(e.gt.tol)write(nout,*)'residual error at level 1 = ',e,ie
      if(ninf.eq.0)then
        call setfg2(n,kmax,a,la,x,ff,an,ws,lws)
      else
        call setfg1(n,nm,a,la,x,bl,bu,ff,fb,an,peq,lp1,nk1,ls,r)
      endif
      gnm=sqrt(scpr(0.D0,an,an,n))
      if(lev.eq.1)then
        e=abs(ff-f)
        if(e.gt.tol*max(1.D0,abs(f)))write(nout,*)'function error = ',e,
     *    '   f(x) =',ff
      endif
    1 continue
      e=0.D0
      do j=1,nk
c       write(nout,*)'an =',(an(i),i=1,n)
        i=abs(ls(j))
        s=sign(1.D0,dble(ls(j)))
        if(i.le.n)then
          an(i)=an(i)-s*r(i)
          if(ls(j).gt.0)then
            s=x(i)-bl(i)
          else
            s=bu(i)-x(i)
          endif
        else
          call saipy(-s*r(i),a,la,i-n,an,n)
          if(ls(j).gt.0)then
            s=aiscpr(n,a,la,i-n,x,-bl(i))
          else
            s=-aiscpr(n,a,la,i-n,x,-bu(i))
          endif
        endif
        if(abs(s).gt.e)then
          if(j.gt.peq.and.j.lt.lp1)s=0.
          e=abs(s)
          ie=i
        endif
      enddo
      if(e.gt.tol)write(nout,*)'residual error at level 2 = ',e,ie
      e=0.D0
      do i=1,n
        if(abs(an(i)).gt.e)then
          e=abs(an(i))
          ie=i
        endif
      enddo
      if(e.gt.gnm*tol)write(nout,*)'KT condition error = ',e,ie,gnm
c     if(e.gt.gnm*tol)write(nout,*)'KT cond_n errors = ',(an(i),i=1,n)
      return
      end

      subroutine warm_start(n,nm,nk,a,la,x,bl,bu,b,ls,lv,aa,ll,an,vstep)
      implicit double precision (a-h,o-z)
      dimension a(*),la(*),x(*),bl(*),bu(*),b(*),ls(*),lv(*),
     *  aa(*),ll(*),an(*)
      DOUBLE PRECISION daiscpr
      common/epsc/eps,tol,emin
      common/noutc/nout
      common/iprintc/iprint
      do j=1,nk
        i=abs(ls(j))
        if(i.le.n)then
          b(i)=0.D0
          ri=x(i)-bl(i)
          ro=bu(i)-x(i)
          if(ri.le.ro)then
            ls(j)=i
            if(abs(ri).le.tol)x(i)=bl(i)
          else
            ls(j)=-i
            if(abs(ro).le.tol)x(i)=bu(i)
          endif
        endif
      enddo
c     write(nout,*)'ls(1:nk) =',(ls(i),i=1,nk)
      do j=1,nk
        i=abs(ls(j))
        if(i.gt.n)then
          if(ls(j).ge.0)then
            b(i)=daiscpr(n,a,la,i-n,x,-bl(i))
          else
            b(i)=daiscpr(n,a,la,i-n,x,-bu(i))
          endif
        endif
      enddo
      do j=1,n-nk
        b(lv(j))=0.D0
      enddo
c     write(nout,1000)'x =',(x(i),i=1,n)
c     write(nout,1000)'r =',(b(abs(ls(j))),j=1,nk)
      call tfbsub(n,a,la,0,b,an,aa,ll,ep,.false.)
c     write(nout,1000)'d =',(an(i),i=1,n)
      call linf(n,an,vstep,i)
      if(iprint.ge.1)
     *  write(nout,*)'infinity norm of vertical step =',vstep
      do j=1,nk
        i=abs(ls(j))
        if(i.le.n)an(i)=0.D0
      enddo
      do i=1,n
        x(i)=x(i)-an(i)
      enddo
c     write(nout,*)'x =',(x(i),i=1,n)
 1000 format(a/(e16.5,4e16.5))
c1001 format(a/(i4,1x,e11.5,4(i4,1x,e11.5)))
      return
      end

      subroutine residuals(n,jmin,nm,a,la,x,bl,bu,r,ls,qj,ninf)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),x(*),bl(*),bu(*),r(*),ls(*)
      common/epsc/eps,tol,emin
      DOUBLE PRECISION daiscpr,z
      rq=0.D0
      ninf=0
      do j=jmin,nm
        i=abs(ls(j))
        if(i.gt.n)then
          z=daiscpr(n,a,la,i-n,x,0.D0)
        else
          z=dble(x(i))
        endif
        ri=z-dble(bl(i))
        ro=dble(bu(i))-z
        if(ri.le.ro)then
          ls(j)=i
        else
          ri=ro
          ls(j)=-i
        endif
        if(abs(ri).le.tol)ri=0.D0
        if(ri.lt.0.D0)then
          ninf=ninf+1
          if(ri.lt.rq)then
            qj=j
            rq=ri
          endif
        endif
        r(i)=ri
      enddo
      return
      end

      subroutine setrp(psb,plen,alpha,xp,blp,bup,gp,rpu,lspj,infb,fb,
     *  tol)
      implicit double precision (a-h,o-z)
      logical psb,plen
      if(psb)then
        t=sign(alpha,dble(lspj))
        if(xp.lt.blp)then
          fb=fb+xp-blp
          xp=xp+t
          lspj=abs(lspj)
          rpu=xp-blp
          infb=infb-1
          if(fb.le.tol)fb=0.D0
          if(rpu.ge.-tol)then
            xp=blp
            gp=gp+1.D0
          endif
        elseif(xp.gt.bup)then
c         fp=fp+bup-xp
          fb=fb+bup-xp
          xp=xp+t
          lspj=-abs(lspj)
          rpu=bup-xp
          infb=infb-1
          if(fb.le.tol)fb=0.D0
          if(rpu.ge.-tol)then
            xp=bup
            gp=gp-1.D0
          endif
        else
          xp=xp+t
          rpu=bup-xp
          t=xp-blp
          if(t.le.rpu)then
            rpu=max(t,0.D0)
            lspj=abs(lspj)
          else
            rpu=max(rpu,0.D0)
            lspj=-abs(lspj)
          endif
        endif
      else
        if(plen)xp=xp+sign(alpha,dble(lspj))
        rpu=max(bup-blp-alpha,0.D0)
        if(alpha.le.rpu)then
          rpu=alpha
          lspj=lspj
        else
          lspj=-lspj
        endif
      endif
      if(abs(rpu).le.tol)rpu=0.D0
      return
      end

      subroutine refine_s(p,nk,n,a,la,ls,s,ds,aa,ll)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),ls(*),s(*),ds(*),aa(*),ll(*)
      common/noutc/nout
      DOUBLE PRECISION daiscpr
c     write(nout,*)'refine_s'
      do j=1,nk
        i=abs(ls(j))
        if(i.gt.n)then
          s(i)=daiscpr(n,a,la,i-n,s,0.D0)
        endif
      enddo
      if(p.le.n)then
        s(p)=0.D0
      else
        s(p)=daiscpr(n,a,la,p-n,s,-1.D0)
      endif
      call tfbsub(n,a,la,0,s,ds,aa,ll,ep,.false.)
      do i=1,n
        s(i)=s(i)-ds(i)
      enddo
      if(p.le.n)s(p)=1.D0
      return
      end

      subroutine reset_w(jmin,jmax,plus,n,a,la,w,ls,s,sml)
      implicit double precision (a-h,o-z)
      dimension a(*),la(*),w(*),ls(*),s(*)
      logical plus
      do 1 j=jmin,jmax
        i=abs(ls(j))
        wi=w(i)
        if(wi.eq.0.D0)goto1
        if(i.le.n)then
          z=s(i)
        else
          z=aiscpr(n,a,la,i-n,s,0.D0)
        endif
        if(abs(z).le.sml)then
          w(i)=0.D0
          goto1
        endif
        if(plus.neqv.ls(j).ge.0)then
          w(i)=-z
        else
          w(i)=z
        endif
    1 continue
      return
      end

      subroutine setfg1(n,nm,a,la,x,bl,bu,f,fb,g,peq,lp1,nk1,ls,r)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),x(*),bl(*),bu(*),g(*),ls(*),r(*)
      do i=1,n
        g(i)=0.D0
      enddo
      fb=0.D0
      do j=peq+1,lp1-1
        i=abs(ls(j))
        if(x(i).lt.bl(i))then
          fb=fb+bl(i)-x(i)
          g(i)=g(i)-1.D0
        elseif(x(i).gt.bu(i))then
          fb=fb+x(i)-bu(i)
          g(i)=g(i)+1.D0
        endif
      enddo
      f=fb
      do j=nk1,nm
        i=abs(ls(j))
        if(r(i).lt.0.D0)then
          f=f-r(i)
          if(i.le.n)then
            g(i)=g(i)-sign(1.D0,dble(ls(j)))
          else
            sign_=sign(1.D0,dble(ls(j)))
            call saipy(-sign_,a,la,i-n,g,n)
          endif
        endif
      enddo
      return
      end

      subroutine setfg2(n,kmax,a,la,x,f,g,ws,lws)
      implicit double precision (a-h,o-z)
      dimension a(*),la(*),x(*),g(*),ws(*),lws(*)
      common/noutc/nout
      if(kmax.eq.0)then
        do i=1,n
          g(i)=0.D0
        enddo
        call saipy(1.D0,a,la,0,g,n)
        f=scpr(0.D0,x,g,n)
      else
        call gdotx(n,x,ws,lws,g)
        call saipy(1.D0,a,la,0,g,n)
        f=5.D-1*scpr(aiscpr(n,a,la,0,x,0.D0),g,x,n)
      endif
      return
      end
