christen this file    sparseA.f
cut here >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
c  ******************************************
c  Specification of A in sparse matrix format
c  ******************************************

c  The matrix A contains gradients of the linear terms in the objective
c  function (column 0) and the general constraints (columns 1:m).
c  No explicit reference to simple bound constraints is required in A.
c  The information is set in the parameters a (real) and la (integer) of bqpd.

c  In this sparse format, these vectors have dimension  a(1:nnza)  and
c   la(0:lamax), where nnza is the number of nonzero elements in A,
c  and lamax is at least  nnza+m+2.  The last m+2 elements in la are pointers.

c  The vectors a(.) and la(.) must be set as follows:

c  a(j) and la(j) for j=1,nnza are set to the values and row indices (resp.)
c  of all the nonzero elements of A. Entries for each column are grouped
c  together in increasing column order.

c  The last m+2 elements of la(.) contain pointers to the first elements in
c  the column groupings. Thus la(la(0)+i) for i=0,m is set to the location
c  in a(.) containing the first nonzero element for column i of A. Also
c  la(la(0)+m+1) is set to nnza+1 (the first unused location in a(.)).

c  Finally la(0) is also a pointer which points to the start of the pointer
c  information in la. la(0) must be set to nnza+1 (or a larger value if it
c  is desired to allow for future increases to nnza).

c  Copyright, University of Dundee (R.Fletcher), June 1996
c  Current version dated 21/05/98

      subroutine saipy(s,a,la,i,y,n)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),y(*)
c  saxpy with column i of A
      if(s.eq.0.D0)return
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=la(j)
        y(ir)=y(ir)+s*a(j)
      enddo
      return
      end

c     subroutine daipy(s,a,la,i,y,n)
c     DOUBLE PRECISION a(*),y(*),d
c     dimension la(0:*)
c     if(s.eq.0.D0)return
c     d=dble(s)
c     jp=la(0)+i
c     do j=la(jp),la(jp+1)-1
c       ir=la(j)
c       y(ir)=y(ir)+d*dble(a(j))
c     enddo
c     return
c     end

      subroutine isaipy(s,a,la,i,y,n,lr,li)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),y(*),lr(*),li(*)
c  indirectly addressed saxpy with column i of A
      if(s.eq.0.D0)return
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=li(la(j))
        y(ir)=y(ir)+s*a(j)
      enddo
      return
      end

c the old isaipy was what might be called isaipy2

      subroutine isaipy1(s,a,la,i,y,n,lr,li,m1)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),y(*),lr(*),li(*)
c  indirectly addressed saxpy with column i of A_1
      if(s.eq.0.D0)return
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=li(la(j))
        if(ir.le.m1)y(ir)=y(ir)+s*a(j)
      enddo
      return
      end

c     subroutine ssaipy(s,a,la,i,y,n)
c     implicit double precision (a-h,o-z)
c     dimension a(*),la(0:*),y(*)
c  saxpy with squares of column i of A
c     if(s.eq.0.D0)return
c     jp=la(0)+i
c     do j=la(jp),la(jp+1)-1
c       ir=la(j)
c       y(ir)=y(ir)+s*(a(j))**2
c     enddo
c     return
c     end

      function aiscpr(n,a,la,i,x,b)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*)
c  scalar product with column i of A
      aiscpr=b
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=la(j)
        aiscpr=aiscpr+x(ir)*a(j)
      enddo
      return
      end

      function daiscpr(n,a,la,i,x,b)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*)
      DOUBLE PRECISION daiscpr
      daiscpr=dble(b)
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=la(j)
        daiscpr=daiscpr+dble(x(ir))*dble(a(j))
      enddo
      return
      end

      function aiscpri(n,a,la,i,x,b,lr,li)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*),lr(*),li(*)
c  indirectly addressed scalar product with column i of A
      aiscpri=b
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=li(la(j))
        aiscpri=aiscpri+x(ir)*a(j)
      enddo
      return
      end

      function daiscpri(n,a,la,i,x,b,lr,li)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*),lr(*),li(*)
      DOUBLE PRECISION daiscpri
      daiscpri=dble(b)
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=li(la(j))
        daiscpri=daiscpri+dble(x(ir))*dble(a(j))
      enddo
      return
      end

c the old aiscpri was what might be called aiscpri2

      function aiscpri1(n,a,la,i,x,b,lr,li,m1)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*),lr(*),li(*)
c  indirectly addressed scalar product with column i of A_1
      aiscpri1=b
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ir=li(la(j))
        if(ir.le.m1)aiscpri1=aiscpri1+x(ir)*a(j)
      enddo
      return
      end

      function ailen(n,a,la,i)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*)
c  L2 length of column i of A
      ailen=0.D0
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        ailen=ailen+a(j)**2
      enddo
      ailen=sqrt(ailen)
      return
      end

      subroutine iscatter(a,la,i,li,an,n)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),li(*),an(*)
c  indirect scatter into previously zeroed vector an
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        an(li(la(j)))=a(j)
      enddo
      return
      end

      subroutine iunscatter(a,la,i,li,an,n)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),li(*),an(*)
c  undo effect of iscatter
      jp=la(0)+i
      do j=la(jp),la(jp+1)-1
        an(li(la(j)))=0.D0
      enddo
      return
      end

      function aij(i,j,a,la)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*)
c  get element A(i,j)
      jp=la(0)+j
      do jj=la(jp),la(jp+1)-1
        ir=la(jj)
        if(ir.eq.i)then
          aij=a(jj)
          return
        endif
      enddo
      aij=0.D0
      return
      end

      subroutine cscale(n,m,a,la,x,bl,bu,s,menu,ifail)
      implicit double precision (a-h,o-z)
      dimension a(*),la(0:*),x(*),bl(*),bu(*),s(*)

c     Constraint scaling procedure for use prior to calling bqpd when using
c     sparseA.f

c     Parameters are set as for bqpd, except for s, menu and ifail

c     The user must set the parameter menu to control how the
c     x-variables are scaled (or equivalently how constraints i = 1:n
c     are scaled), as follows

c     menu = 1 indicates that a unit scaling applies to the x-variables

c     menu = 2 the user provides estimates s(i)>0 of the magnitude of
c              x(i) for i = 1:n. In this case the elements  x(i), bl(i), bu(i)
c              are divided by s(i) for i = 1:n.

c     In all cases, cscale goes on to scale the general constraints, in
c     such a way that the normal vector of each nontrivial constraint in
c     the scaled problem has an l_2 norm of unity. This scaling is also
c     applied to the right hand sides  bl(i), bu(i) for i = n+1:n+m.
c     The scaled data overwrites the original data.

c     cscale also scales the constant vector of the quadratic function,
c     which is found in a(1:n). However if a non-unit x-variable scaling
c     is used, it is necessary for the user to scale the Hessian matrix
c     G appropriately. This can be done by passing the x-variable scale
c     factors s(i) i = 1:n into the subroutine gdotx using the
c     parameter ws, and multiplying G(i,j) by s(i)*s(j) (possibly
c     implicitly).

c     cscale sets ifail = 1 to indicate that some s(i)< = 0,
c             and ifail = 2 to indicate an incorrect setting of menu.
c       Otherwise ifail = 0.

      integer pjp

      ifail=2
      if(menu.lt.1.or.menu.gt.2)return
      pjp=la(0)
c     z=1.D0/log(2.D0)
      if(menu.eq.1)then
        do j=1,n
          s(j)=1.D0
        enddo
      else
        ifail=1
        do j=1,n
          if(s(j).le.0.D0)return
        enddo
c       if(menu.eq.2)then
c         do j=1,n
c           s(j)=2.D0**nint(log(s(j))*z)
c         enddo
c       endif
        do j=1,n
          if(s(j).ne.1.D0)then
            x(j)=x(j)/s(j)
            bl(j)=bl(j)/s(j)
            bu(j)=bu(j)/s(j)
          endif
        enddo
        do j=1,la(pjp+1)-1
          a(j)=a(j)*s(la(j))
        enddo
      endif
      do i=1,m
        t=0.D0
        do j=la(pjp+i),la(pjp+i+1)-1
          a(j)=s(la(j))*a(j)
          t=t+a(j)**2
        enddo
        t=sqrt(t)
        if(t.eq.0.D0)then
          s(n+i)=1.D0
        else
c         t=2.D0**nint(log(t)*z)
          s(n+i)=t
          do j=la(pjp+i),la(pjp+i+1)-1
            a(j)=a(j)/t 
          enddo
          bl(n+i)=bl(n+i)/t
          bu(n+i)=bu(n+i)/t
        endif
      enddo
      ifail=0
      return
      end
