      SUBROUTINE chol_mvnorm(x, mu, sig, n, like, info)

cf2py double precision dimension(n), intent(copy) :: x
cf2py double precision dimension(n), intent(copy) :: mu
cf2py integer intent(hide),depend(x) :: n=len(x)
cf2py double precision dimension(n,n), intent(copy) :: sig
cf2py double precision intent(out) :: like
cf2py integer intent(hide) :: info

      DOUBLE PRECISION sig(n,n), x(n), mu(n), like
      INTEGER n, info
      DOUBLE PRECISION infinity
      PARAMETER (infinity = 1.7976931348623157d308)      
      DOUBLE PRECISION PI
      PARAMETER (PI=3.141592653589793238462643d0) 
      DOUBLE PRECISION twopi_N, log_detC

      EXTERNAL DPOTRS
! DPOTRS( UPLO, N, NRHS, A, LDA, B, LDB, INFO ) Solves triangular system
      EXTERNAL DAXPY
! DAXPY(N,DA,DX,INCX,DY,INCY) Adding vectors
      EXTERNAL DCOPY
! DCOPY(N,DX,INCX,DY,INCY) copies x to y
      EXTERNAL DDOT
      
!     x <- (x-mu)      
      call DAXPY(n, -1.0D0, mu, 1, x, 1)
      
!       mu <- x
      call DCOPY(n,x,1,mu,1)
      
!     x <- sig ^-1 * x
      call DPOTRS('L',n,1,sig,n,x,n,info)
      
!     like <- .5 dot(x,mu) (.5 (x-mu) C^{-1} (x-mu)^T)
      like = -0.5D0 * DDOT(n, x, 1, mu, 1)
!       print *, like
      
      twopi_N = 0.5D0 * N * dlog(2.0D0*PI)
!       print *, twopi_N
      
      log_detC = 0.0D0
      do i=1,n
        log_detC = log_detC + log(sig(i,i))
      enddo
!       print *, log_detC
      
      like = like - twopi_N - log_detC
      
      return
      END


      SUBROUTINE cov_mvnorm(x, mu, C, n, like, info)

cf2py double precision dimension(n), intent(copy) :: x
cf2py double precision dimension(n), intent(copy) :: mu
cf2py integer intent(hide),depend(x) :: n=len(x)
cf2py double precision dimension(n,n), intent(copy) :: C
cf2py double precision intent(out) :: like
cf2py integer intent(hide) :: info

      DOUBLE PRECISION C(n,n), x(n), mu(n), like
      INTEGER n, info
      DOUBLE PRECISION infinity
      PARAMETER (infinity = 1.7976931348623157d308)      
      DOUBLE PRECISION PI
      PARAMETER (PI=3.141592653589793238462643d0) 
      DOUBLE PRECISION twopi_N, log_detC

      EXTERNAL DPOTRF
! DPOTRF( UPLO, N, A, LDA, INFO ) Cholesky factorization
      EXTERNAL DPOTRS
! DPOTRS( UPLO, N, NRHS, A, LDA, B, LDB, INFO ) Solves triangular system
      EXTERNAL DAXPY
! DAXPY(N,DA,DX,INCX,DY,INCY) Adding vectors
      EXTERNAL DCOPY
! DCOPY(N,DX,INCX,DY,INCY) copies x to y
      EXTERNAL DDOT
      
!     C <- cholesky(C)      
      call DPOTRF( 'L', n, C, n, info )
!       print *, C
      
!     Puke if C not positive definite
      if (info .GT. 0) then
        like=-infinity
        RETURN
      endif

!     x <- (x-mu)      
      call DAXPY(n, -1.0D0, mu, 1, x, 1)
      
!       mu <- x
      call DCOPY(n,x,1,mu,1)
      
!     x <- C ^-1 * x
      call DPOTRS('L',n,1,C,n,x,n,info)
      
!     like <- .5 dot(x,mu) (.5 (x-mu) C^{-1} (x-mu)^T)
      like = -0.5D0 * DDOT(n, x, 1, mu, 1)
!       print *, like
      
      twopi_N = 0.5D0 * N * dlog(2.0D0*PI)
!       print *, twopi_N
      
      log_detC = 0.0D0
      do i=1,n
        log_detC = log_detC + log(C(i,i))
      enddo
!       print *, log_detC
      
      like = like - twopi_N - log_detC
      
      return
      END

      SUBROUTINE blas_mvnorm(x, mu, tau, n, like)

cf2py double precision dimension(n), intent(copy) :: x
cf2py double precision dimension(n), intent(copy) :: mu
cf2py integer intent(hide),depend(x) :: n=len(x)
cf2py double precision dimension(n,n), intent(in) :: tau
cf2py double precision intent(out) :: like

      DOUBLE PRECISION tau(n,n), x(n), mu(n), like
      INTEGER n, info
      DOUBLE PRECISION infinity
      PARAMETER (infinity = 1.7976931348623157d308)      
      DOUBLE PRECISION PI
      PARAMETER (PI=3.141592653589793238462643d0) 
      DOUBLE PRECISION twopi_N, log_dettau

      EXTERNAL DPOTRF
! DPOTRF( UPLO, N, A, LDA, INFO ) Cholesky factorization
      EXTERNAL DSYMV
! Symmetric matrix-vector multiply
      EXTERNAL DAXPY
! DAXPY(N,DA,DX,INCX,DY,INCY) Adding vectors
      EXTERNAL DCOPY
! DCOPY(N,DX,INCX,DY,INCY) copies x to y
      EXTERNAL DDOT

      twopi_N = 0.5D0 * N * dlog(2.0D0*PI)

!     x <- (x-mu)      
      call DAXPY(n, -1.0D0, mu, 1, x, 1)

!       mu <- x
      call DCOPY(n,x,1,mu,1)

!     x <- tau * x
      call DSYMV('L',n,1.0D0,tau,n,x,1,0.0D0,mu,1)

!     like <- .5 dot(x,mu) (.5 (x-mu) C^{-1} (x-mu)^T)
      like = -0.5D0 * DDOT(n, x, 1, mu, 1)

!      Cholesky factorize tau for the determinant.      
       call DPOTRF( 'L', n, tau, n, info )
      
!      If cholesky failed, puke.
       if (info .GT. 0) then
         like = -infinity
         RETURN
       endif

!      Otherwise read off determinant.
       log_dettau = 0.0D0
       do i=1,n
         log_dettau = log_dettau + dlog(tau(i,i))
       enddo
            
       like = like - twopi_N + log_dettau
      
      return
      END
      
      SUBROUTINE blas_wishart(X,k,n,V,like)

c Wishart log-likelihood function.

cf2py double precision dimension(k,k),intent(copy) :: X,V
cf2py double precision intent(in) :: n
cf2py double precision intent(out) :: like
cf2py integer intent(hide),depend(X) :: k=len(X)

      INTEGER i,k
      DOUBLE PRECISION X(k,k),V(k,k),bx(k,k)
      DOUBLE PRECISION dx,n,db,tbx,a,g,like
      DOUBLE PRECISION infinity
      PARAMETER (infinity = 1.7976931348623157d308)

      EXTERNAL DCOPY
! DCOPY(N,DX,INCX,DY,INCY) copies x to y      
      EXTERNAL DSYMM
! DSYMM(SIDE,UPLO,M,N,ALPHA,A,LDA,B,LDB,BETA,C,LDC) alpha*A*B + beta*C when side='l'
      EXTERNAL DPOTRF
! DPOTRF( UPLO, N, A, LDA, INFO ) Cholesky factorization      

      print *, 'Warning, vectorized Wisharts are untested'
c determinants
      call dtrm(X,k,dx) 
      call dtrm(V,k,db)

c trace of V*X
!     bx <- V * bx
      call DSYMM('l','L',n,n,1.0D0,V,n,x,n,0.0D0,bx)

c Cholesky factor V, puke if not pos def.
      call DPOTRF( 'L', n, V, n, info )
      if (info .GT. 0) then
        like = -infinity
        RETURN
      endif 
c Cholesky factor X, puke if not pos def.
      call DPOTRF( 'L', n, X, n, info )
      if (info .GT. 0) then
        like = -infinity
        RETURN
      endif 

c Get the trace and log-sqrt-determinants
      tbx = 0.0D0
      dx = 0.0D0
      db = 0.0D0      
      
      do i=1,n
        tbx = tbx + bx(i,i)
        dx = dx + dlog(X(i,i))
        dx = dx + dlog(V(i,i))
      enddo
            
      if (k .GT. n) then
        like = -infinity
        RETURN
      endif
      
      like = (n - k - 1) * dx
      like = like + n * db
      like = like - 0.5 * tbx
      like = like - (n*k/2.0)*dlog(2.0d0)

      do i=1,k
        a = (n - i + 1)/2.0
        call gamfun(a, g)
        like = like - g
      enddo

      return
      END

c

      SUBROUTINE blas_wishart_cov(X,k,n,V,like)

c Wishart log-likelihood function.
c Doesn't vectorize the determinants, just the matrix multiplication.

cf2py double precision dimension(k,k),intent(copy) :: V,X
cf2py double precision intent(in) :: n
cf2py double precision intent(out) :: like
cf2py integer intent(hide),depend(X) :: k=len(X)

      INTEGER i,k,info
      DOUBLE PRECISION X(k,k),V(k,k),bx(k,k)
      DOUBLE PRECISION dx,n,db,tbx,a,g,like
      DOUBLE PRECISION infinity
      PARAMETER (infinity = 1.7976931348623157d308)
c
      EXTERNAL DCOPY
! DCOPY(N,DX,INCX,DY,INCY) copies x to y      
      EXTERNAL DPOTRF
! DPOTRF( UPLO, N, A, LDA, INFO ) Cholesky factorization
      EXTERNAL DPOTRS
! DPOTRS( UPLO, N, NRHS, A, LDA, B, LDB, INFO ) Solves triangular system
      print *, 'Warning, vectorized Wisharts are untested'
c determinants
      
c Cholesky factorize sigma, puke if not pos def
!     V <- cholesky(V)      
      call DPOTRF( 'L', n, V, n, info )
      if (info .GT. 0) then
        like = -infinity
        RETURN
      endif
      
c trace of sigma*X
!     bx <- X
      call DCOPY(n * n,X,1,bx,1)
!     bx <- sigma * bx
      call DPOTRS('L',n,n,V,n,bx,n,info)

!     X <- cholesky(X)
      call DPOTRF( 'L', n, X, n, info )

! sqrt-log-determinant of sigma and X, and trace
      db=0.0D0
      dx=0.0D0
      tbx = 0.0D0
      do i=1,n
        db = db + dlog(V(i,i))
        dx = dx + dlog(X(i,i))        
        tbx = tbx + bx(i,i)
      enddo
      
      if (k .GT. n) then
        like = -infinity
        RETURN
      endif
      
      like = (n - k - 1) * dx
      like = like + n * db
      like = like - 0.5*tbx
      like = like - (n*k/2.0)*dlog(2.0d0)

      do i=1,k
        a = (n - i + 1)/2.0
        call gamfun(a, g)
        like = like - dlog(g)
      enddo

      return
      END

