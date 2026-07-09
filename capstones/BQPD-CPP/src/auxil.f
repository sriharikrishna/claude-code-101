christen this file auxil.f
cut here >>>>>>>>>>>>>>>>>
c*********** auxiliary routines requiring additional storage ************

c  Copyright, University of Dundee (R.Fletcher), June 1996
c  Current version dated 18/02/99

      subroutine major_s(p,n,k,kmax,a,la,aa,ll,an,bn,rh,ak,bk,ck,lv,
     *  ws,lws,jmin,jmax,w,ls,sgs,pp,smx,ep)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),aa(*),ll(*),an(*),bn(*),rh(*),
     *  ak(*),bk(*),ck(*),lv(*),ws(*),lws(*),w(*),ls(*)
      common/noutc/nout
      common/iprintc/iprint
c     write(nout,*)'major_s  p =',p
      call tfbsub(n,a,la,p,an,an,aa,ll,ep,.true.)
c  compute  s = Y.e_p - Z.M^(-1).Zt.G.Y.e_p  in an
      do i=1,n
        w(i)=an(i)
      enddo
c     write(nout,*)'s =',(w(i),i=1,n)
      if(kmax.gt.0)then
        call linf(n,an,smx,pp)
        call gdotx(n,an,ws,lws,bn)
c       write(nout,*)'G.Y.e_p =',(bn(i),i=1,n)
        sgs=scpr(0.D0,an,bn,n)
        if(k.gt.0)then
c         write(nout,*)'Y.e_p =',(an(i),i=1,n)
          call ztaq(0,n,k,a,la,bn,bk,w,lv,aa,ll)
c  compute  R^(-T).Zt.G.Y.e_p  in ak (ak and bk also used in extend)
c         write(nout,*)'Z#t.G.Y.e_p =',(bk(i),i=1,k),sgs
          do i=1,k
            ak(i)=bk(i)
          enddo
          call rtsol(k,kk,kmax,rh,ak)
c         write(nout,*)'R^(-T).Zt.G.Y.e_p =',(ak(i),i=1,k+1)
          do i=1,k
            ck(i)=ak(i)
          enddo
          call rsol(k,kk,kmax,rh,ck)
c         write(nout,*)'ck =',(ck(i),i=1,k)
          call zprod(p,n,k,a,la,w,ck,lv,w,ls,aa,ll)
          bk(k+1)=sgs
          sgs=-scpr(-sgs,ak,ak,k)
        endif
c       write(nout,*)'sgs =',sgs
      else
        sgs=0.D0
      endif
c     write(nout,*)'s =',(w(i),i=1,n)
c  form At.s
      do j=jmin,jmax
        i=abs(ls(j))
        if(i.gt.n)then
          w(i)=aiscpr(n,a,la,i-n,w,0.D0)
        endif
      enddo
      return
      end

      subroutine minor_s(n,k,kmax,a,la,aa,ll,an,rh,ak,rg,rs,lv,
     *  jmin,jmax,w,ls,sg,sgs)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),aa(*),ll(*),an(*),rh(*),ak(*),rg(*),rs(*),
     *  lv(*),w(*),ls(*)
      common/noutc/nout
      common/minorc/c
c     write(nout,*)'minor_s'
      if(sgs.gt.0.D0)then
        do i=1,k
          rs(i)=rg(i)
        enddo
        call rtsol(k,kk,kmax,rh,rs)
        sgs=scpr(0.D0,rs,rs,k)
        sg=sgs
        if(sgs.eq.0.D0)return
        call rsol(k,kk,kmax,rh,rs)
      else
        do i=1,k
          rs(i)=ak(i)
        enddo
        call rtsol(k,kk,kmax,rh,rs)
        sgs=scpr(0.D0,rs,rs,k)
        c=min(1.D0-sgs,0.D0)
        sgs=sgs*c
        call rsol(k,kk,kmax,rh,rs)
        sg=scpr(0.D0,rs,rg,k)
        if(sg.lt.0.D0)then
          do i=1,k
            rs(i)=-rs(i)
          enddo
          sg=-sg
          c=-c
        endif
      endif
c     write(nout,*)'rs =',(rs(i),i=1,k)
c     write(nout,*)'sg,sgs,c',sg,sgs,c
      call zprod(0,n,k,a,la,an,rs,lv,w,ls,aa,ll)
c     write(nout,*)'s =',(an(i),i=1,n)
c  form At.s
      do j=jmin,jmax
        i=abs(ls(j))
        if(i.gt.n)then
          w(i)=aiscpr(n,a,la,i-n,an,0.D0)
        else
          w(i)=an(i)
        endif
      enddo
      return
      end

      subroutine extend(k,kmax,p,rh,ak,bk,lv,sgs)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension rh(*),ak(*),bk(*),lv(*)
      common/noutc/nout
      common/epsc/eps,tol,emin
c  extend factors of M
      kp=k+1
      lv(kp)=p
      ij=kp
      if(sgs.gt.0.D0)then
c       write(nout,*)'ak =',(ak(i),i=1,k),'   sgs =',sgs
        do i=1,k
          rh(ij)=ak(i)
          ij=ij+kmax-i
        enddo
        rh(ij)=sqrt(sgs)
      else
        u=bk(kp)
c       if(u.gt.1.D0)then
c         b=sqrt(u)
c         c=1.D0/b
c       else
c         b=1.D0
c         c=1.D0/(1.D0+sqrt(1.D0-u))
c       endif
c       a=(c*u-1.D0/c)*5.D-1
        bsq=max(tol,scpr(0.D0,bk,bk,k)/rh(1)**2+abs(u))
        b=sqrt(bsq)
        c=1.D0/(b+sqrt(bsq-u))
        a=c*u-b
        do i=1,k
          bk(i)=c*bk(i)
          ak(i)=bk(i)
          rh(ij)=0.D0
          ij=ij+kmax-i
        enddo
        ak(kp)=a
        bk(kp)=b
        ij=1
        do i=1,k
          call angle(rh(ij),bk(i),cos,sin)
          ij=ij+1
          call rot(kp-i,rh(ij),bk(i+1),cos,sin)
          ij=ij+kmax-i
        enddo
        rh(ij)=bk(kp)
      endif
      k=kp
c     write(nout,*)'extend: V-list =',(lv(i),i=1,k)
c     write(nout,*)'extended reduced Hessian factor'
c     ij=0
c     do i=1,k
c       write(nout,*)(rh(ij+j),j=1,k-i+1)
c       ij=ij+kmax-i+1
c     enddo
c     if(sgs.le.0.D0)write(nout,*)'negative part:  a =',(ak(i),i=1,k)
      return
      end

      subroutine rgup(k,ak,rg,alpha,sgs)
      implicit double precision (a-h,o-z)
      dimension ak(*),rg(*)
      common/noutc/nout
      common/minorc/c
      if(sgs.gt.0.D0)then
        c=1.D0-alpha
        do i=1,k
          rg(i)=rg(i)*c
        enddo
      else
        call mysaxpy(-alpha*c,ak,rg,k)
      endif
c     write(nout,*)'reduced gradient =',(rg(i),i=1,k)
      return
      end

      subroutine zprod(p,n,k,a,la,an,ak,lv,w,ls,aa,ll)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),an(*),ak(*),lv(*),w(*),ls(*),aa(*),ll(*)
      common/noutc/nout
      do i=1,n-k
        w(abs(ls(i)))=0.D0
      enddo
      if(p.gt.0)w(p)=1.D0
      do i=1,k
        w(lv(i))=-ak(i)
      enddo
      call tfbsub(n,a,la,0,w,an,aa,ll,ep,.false.)
      return
      end

      subroutine qinv(q,qv,k,ak,lv)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension ak(*),lv(*)
c  look for q in V-list
      do i=1,k
        if(q.eq.lv(i))then
          do j=1,k
            ak(j)=0.D0
          enddo
          qv=i
          ak(qv)=1.D0
          return
        endif
      enddo
      qv=0
      return
      end

      subroutine ztaq(q,n,k,a,la,an,ak,w,lv,aa,ll)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),an(*),ak(*),w(*),lv(*),aa(*),ll(*)
      common/noutc/nout
      call fbsub(n,1,k,a,la,q,an,w,lv,aa,ll,.false.)
      do i=1,k
        ak(i)=w(lv(i))
      enddo
c     write(nout,*)'Zt.aq =',(ak(i),i=1,k)
      return
      end

      subroutine reduce(k,kmax,p,pv,rh,rg,lv,ak,bk,ck,sgs,rg_up)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension rh(*),rg(*),lv(*),ak(*),bk(*),ck(*)
      common/noutc/nout
      logical rg_up
      external rshift
c     write(nout,*)'reduce:  p =',p,'   pv =',pv
c  remove column pv from V and update reduced Hessian factors
c     write(nout,*)'ak =',(ak(i),i=1,k)
c     write(nout,*)'bk =',(bk(i),i=1,k)
      ij=pv
      do i=1,pv
        ck(i)=rh(ij)
        call rshift(rh(ij),k-pv,1)
        ij=ij+kmax-i
      enddo
      kk=ij-kmax+pv
      kmx1=kmax+1
      ij=ij+1
      za=ak(pv)
      zb=bk(pv)
      zr=rg(pv)
      do i=pv+1,k
        ck(i)=rh(ij)
        call rshift(rh(ij),k-i,1)
        im=i-1
        ak(im)=ak(i)
        bk(im)=bk(i)
        rg(im)=rg(i)
        lv(im)=lv(i)
        ij=ij+kmx1-i
      enddo
c     write(nout,*)'ck =',(ck(i),i=1,k)
      k=k-1
      if(k.eq.0)return
c     write(nout,*)'V list =',(lv(i),i=1,k)
c  return to triangular form
      if(p.ne.0)then
        call brots(k,kmax,pv,kk,rh,ck)
        call mysaxpy(-ck(1)/zb,bk,rh,k)
        call frots(k,k,kmax,rh,ck)
        if(sgs.le.0.D0)call mysaxpy(-za/zb,bk,ak,k)
      else
        call frots(k-pv+1,k-pv+1,kmax-pv+1,rh(kk),ck(pv))
      endif
      if(rg_up)call mysaxpy(-zr/zb,bk,rg,k)
      if(sgs.le.0.D0)then
c  check if negative part can be removed
        do i=1,k
          bk(i)=ak(i)
        enddo
        call rtsol(k,kk,kmax,rh,bk)
        sgs=-scpr(-1.D0,bk,bk,k)
        if(sgs.gt.0.D0)then
          call brots(k,kmax,k,kk,rh,bk)
          sgs=sqrt(sgs)
          do i=1,k
            rh(i)=rh(i)*sgs
          enddo
          call frots(k,k-1,kmax,rh,bk)
        endif
      endif
c     write(nout,*)'reduced Hessian factor'
c     ij=0
c     do i=1,k
c       write(nout,*)(rh(ij+j),j=1,k-i+1)
c       ij=ij+kmx1-i
c     enddo
c     if(sgs.le.0.D0)write(nout,*)'negative part:  a =',(ak(i),i=1,k)
c     write(nout,*)'reduced gradient',(rg(i),i=1,k)
      return
      end

      subroutine revise(k,kmax,rh,rg,lv,q,ak,bk,ck,sgs)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension rh(*),rg(*),lv(*),ak(*),bk(*),ck(*)
      common/noutc/nout
c     write(nout,*)'revise'
c     write(nout,*)'bk =',(bk(i),i=1,k)
      smx=bk(k)
      lv(k)=q
      km=k-1
      ij=k
      do i=1,k
        ck(i)=rh(ij)/smx
        rh(ij)=0.D0
        ij=ij+kmax-i
      enddo
      ij=ij-kmax+k
c     write(nout,*)'ak =',(ak(i),i=1,k)
c     write(nout,*)'ck =',(ck(i),i=1,k)
      call brots(km,kmax,k,ij,rh,ck)
      call mysaxpy(-ck(1),bk,rh,km)
      rh(k)=ck(1)
      call frots(k,km,kmax,rh,ck)
      if(sgs.le.0.D0)then
        ak(k)=ak(k)/smx
        call mysaxpy(-ak(k),bk,ak,km)
      endif
      rg(k)=rg(k)/smx
      call mysaxpy(-rg(k),bk,rg,km)
c     write(nout,*)'V list =',(lv(i),i=1,k)
c     write(nout,*)'revised reduced Hessian factor'
c     ij=0
c     do i=1,k
c       write(nout,*)(rh(ij+j),j=1,k-i+1)
c       ij=ij+kmax-i+1
c     enddo
c     if(sgs.le.0.D0)write(nout,*)'negative part:  a =',(ak(i),i=1,k)
c     write(nout,*)'reduced gradient',(rg(i),i=1,k)
      return
      end

      subroutine hot_start(n,k,kmax,a,la,x,an,bn,rh,ak,lv,w,ls,aa,ll,
     *  ws,lws,hstep)
      implicit double precision (a-h,o-z)
      dimension a(*),la(*),x(*),an(*),bn(*),rh(*),ak(*),lv(*),
     *  w(*),ls(*),aa(*),ll(*),ws(*),lws(*)
      common/noutc/nout
      common/iprintc/iprint
c     dimension Z(100,20)
c     write(nout,*)'Zt matrix'
c     do i=1,k
c       call tfbsub(n,a,la,lv(i),w,Z(1,i),aa,ll,ep,.false.)
c       write(nout,*)lv(i),':',(Z(j,i),j=1,n)
c     enddo
      call gdotx(n,x,ws,lws,an)
      call saipy(1.D0,a,la,0,an,n)
c     write(nout,*)'g =',(an(i),i=1,n)
      call ztaq(0,n,k,a,la,an,ak,w,lv,aa,ll)
c     write(nout,*)'Zt.g =',(ak(i),i=1,k)
      call rtsol(k,kk,kmax,rh,ak)
      call rsol(k,kk,kmax,rh,ak)
c     write(nout,*)'M^(-1).Zt.g =',(ak(i),i=1,k)
      call zprod(0,n,k,a,la,an,ak,lv,w,ls,aa,ll)
c     write(nout,*)'Z.M^(-1).Zt.g =',(an(i),i=1,n)
      do j=1,n-k
        i=abs(ls(j))
        if(i.le.n)an(i)=0.D0
      enddo
      hstep=sqrt(scpr(0.D0,an,an,n))
      if(iprint.ge.1)write(nout,*)'norm of horizontal step =',hstep
      do i=1,n
        bn(i)=x(i)
        x(i)=x(i)+an(i)
      enddo
c     write(nout,*)'x =',(x(i),i=1,n)
      return
      end

      subroutine checkrh(n,a,la,k,kmax,rh,rg,ak,lv,aa,ll,x,ws,lws,
     *  sgs,tol)
      implicit double precision (a-h,r-z), integer (i-q)
      dimension a(*),la(*),rh(*),rg(*),ak(*),lv(*),aa(*),ll(*),
     *  x(*),ws(*),lws(*)
      dimension Z(500,20),E(20,20),v(20),w(500)
      common/noutc/nout
      if(n.gt.500.or.k.gt.20)then
        write(6,*)'extend local storage for checkrh'
        stop
      endif
c     write(nout,*)'checkrh'
c     write(nout,*)'Zt matrix'
      do i=1,k
        call tfbsub(n,a,la,lv(i),w,Z(1,i),aa,ll,ep,.false.)
c       write(nout,*)lv(i),':',(Z(j,i),j=1,n)
      enddo
      call gdotx(n,x,ws,lws,w)
      call saipy(1.D0,a,la,0,w,n)
c     write(nout,*)'g =',(w(i),i=1,n)
      do i=1,k
        v(i)=scpr(0.D0,w,Z(1,i),n)
      enddo
c     write(nout,*)'reduced gradient vector Zt.g',(v(i),i=1,k)
      emax=0.D0
      do i=1,k
        emax=max(emax,abs(rg(i)-v(i)))
      enddo
      if(emax.gt.tol)
     *  write(nout,*)'max error in reduced gradient =',emax
c     write(nout,*)'Zt.G.Z matrix'
      do i=1,k
        call gdotx(n,Z(1,i),ws,lws,w)
        do j=1,k
          E(i,j)=scpr(0.D0,w,Z(1,j),n)
        enddo
c       write(nout,*)(E(i,j),j=1,k)
      enddo
      ij=1
      do i=1,k
        do j=i,k
          w(j)=rh(ij+j-i)
        enddo
        do j=i,k
          do jj=i,k
            E(j,jj)=E(j,jj)-w(j)*w(jj)
          enddo
        enddo
        ij=ij+kmax-i+1
      enddo
      if(sgs.lt.0.D0)then
        do j=1,k
          do jj=1,k
            E(j,jj)=E(j,jj)+ak(j)*ak(jj)
          enddo
        enddo
      endif
c     write(nout,*)'error  Zt.G.Z - Rt.R'
      emax=0.D0
      do i=1,k
        do j=1,k
          emax=max(emax,abs(E(i,j)))
        enddo
c       write(nout,*)(E(i,j),j=1,k)
      enddo
      if(emax.gt.tol)write(nout,*)'max error in Rt.R =',emax
      return
      end
