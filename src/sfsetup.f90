SUBROUTINE SFSETUP()

  !read in and set up all the arrays

  USE sfvars; USE nr, ONLY : locate; USE sfutils, ONLY : linterp
  IMPLICIT NONE
  
  REAL(DP) :: d1,l5000=5000.0, t13=1.3,t23=2.3,sig0=99.
  REAL(DP), DIMENSION(nimf*nimf) :: tmp
  REAL(DP), DIMENSION(nl) :: test2,smooth=0.0,lam
  INTEGER :: stat,i,vv,j,k,ii,shift

  !---------------------------------------------------------------!
  !---------------------------------------------------------------!

  !read in filter transmission curves
  OPEN(11,FILE=TRIM(SPECFIT_HOME)//'/infiles/filters.dat',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(11,*) 
  ENDDO
  DO i=1,nl
     READ(11,*) d1,filters(i,1),filters(i,2),filters(i,3) !r,i,K filters
  ENDDO
  CLOSE(11)

  !read in the ATLAS SSPs
  DO j=1,nage_rfcn

     IF (j.EQ.1) THEN
        OPEN(20,FILE=TRIM(SPECFIT_HOME)//'/infiles/atlas_ssp_t01.abund.krpa.s100',&
             STATUS='OLD',iostat=stat,ACTION='READ')
     ELSE IF (j.EQ.2) THEN
        OPEN(20,FILE=TRIM(SPECFIT_HOME)//'/infiles/atlas_ssp_t03.abund.krpa.s100',&
             STATUS='OLD',iostat=stat,ACTION='READ')
      ELSE IF (j.EQ.3) THEN
        OPEN(20,FILE=TRIM(SPECFIT_HOME)//'/infiles/atlas_ssp_t05.abund.krpa.s100',&
             STATUS='OLD',iostat=stat,ACTION='READ')
     ELSE IF (j.EQ.4) THEN
        OPEN(20,FILE=TRIM(SPECFIT_HOME)//'/infiles/atlas_ssp_t09.abund.krpa.s100',&
             STATUS='OLD',iostat=stat,ACTION='READ')
     ELSE IF (j.EQ.5) THEN
        OPEN(20,FILE=TRIM(SPECFIT_HOME)//'/infiles/atlas_ssp_t13.abund.krpa.s100',&
             STATUS='OLD',iostat=stat,ACTION='READ')
     ENDIF

     READ(20,*) !burn the header
     READ(20,*)
     DO i=1,nstart-1
        READ(20,*) 
     ENDDO
     DO i=1,nl
        READ(20,*) sspgrid%lam(i),sspgrid%solar(i,j),sspgrid%nap(i,j),&
             sspgrid%nam(i,j),sspgrid%cap(i,j),sspgrid%cam(i,j),sspgrid%fep(i,j),&
             sspgrid%fem(i,j),sspgrid%cp(i,j),sspgrid%cm(i,j),d1,sspgrid%zp(i,j),&
             sspgrid%zm(i,j),sspgrid%np(i,j),sspgrid%nm(i,j),sspgrid%ap(i,j),&
             sspgrid%tip(i,j),sspgrid%tim(i,j),sspgrid%mgp(i,j),sspgrid%mgm(i,j),&
             sspgrid%sip(i,j),sspgrid%sim(i,j),sspgrid%hep(i,j),sspgrid%hem(i,j),&
             sspgrid%teffp(i,j),sspgrid%teffm(i,j),sspgrid%crp(i,j),sspgrid%mnp(i,j),&
             sspgrid%bap(i,j),sspgrid%bam(i,j),sspgrid%nip(i,j),sspgrid%cop(i,j),&
             sspgrid%eup(i,j),sspgrid%srp(i,j),sspgrid%kp(i,j),sspgrid%vp(i,j),&
             sspgrid%yp(i,j),sspgrid%zrp(i,j),sspgrid%rbp(i,j),&
             sspgrid%cup(i,j),sspgrid%nap6(i,j),sspgrid%nap9(i,j)
     ENDDO
     CLOSE(20)

  ENDDO

  lam = sspgrid%lam
  sspgrid%logagegrid_rfcn = LOG10((/1.0,3.0,5.0,9.0,13.0/))


  IF (1.EQ.0) THEN

     !create fake response functions for Cr, Mn, and Co, by shifting
     !the wavelengths by n pixels
     !shift = 150
     !test2 = sspgrid%crp / sspgrid%solar
     !sspgrid%crp = 1.0
     !sspgrid%crp(shift:nl-1) = test2(1:nl-shift)
     !sspgrid%crp = sspgrid%crp * sspgrid%solar
     
     !test2 = sspgrid%mnp / sspgrid%solar
     !sspgrid%mnp = 1.0
     !sspgrid%mnp(shift:nl-1) = test2(1:nl-shift)
     !sspgrid%mnp = sspgrid%mnp * sspgrid%solar
  
     !test2 = sspgrid%cop / sspgrid%solar
     !sspgrid%cop = 1.0
     !sspgrid%cop(shift:nl-1) = test2(1:nl-shift)
     !sspgrid%cop = sspgrid%cop * sspgrid%solar
 
  ENDIF


  !read in empirical spectra as a function of age
  OPEN(21,FILE=TRIM(SPECFIT_HOME)//'/infiles/CvD_krpaIMF.ssp.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(21,*) 
  ENDDO
  DO i=1,nl
     READ(21,*) d1,sspgrid%logfkrpa(i,1),sspgrid%logfkrpa(i,2),&
          sspgrid%logfkrpa(i,3),sspgrid%logfkrpa(i,4),sspgrid%logfkrpa(i,5),&
          sspgrid%logfkrpa(i,6),sspgrid%logfkrpa(i,7)
  ENDDO
  CLOSE(21)

  sspgrid%logfkrpa   = LOG10(sspgrid%logfkrpa+tiny_number)
  sspgrid%logagegrid = LOG10((/1.0,3.0,5.0,7.0,9.0,11.0,13.5/))

  !vary two power-law slopes, from 0.1<M<0.5 and 0.5<M<1.0
  OPEN(26,FILE=TRIM(SPECFIT_HOME)//'/infiles/CvD_t13.5.ssp.'//&
       'imf_varydoublex.s100',STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(26,*) 
  ENDDO
  DO i=1,nl
     READ(26,*) d1,tmp
     ii=1
     DO j=1,nimf
        DO k=1,nimf
           sspgrid%imf(i,j,k) = tmp(ii)
           ii=ii+1
        ENDDO
     ENDDO
  ENDDO
  CLOSE(26)
  !values of IMF slopes at the 35 grid points
  DO i=1,nimf
     sspgrid%imfx(i) = 0.d2+REAL(i-1)/10.d0 
  ENDDO
  i13 = locate(sspgrid%imfx,t13+1E-3)
  i23 = locate(sspgrid%imfx,t23+1E-3)

  !read in M7III star, normalized to a 13 Gyr SSP at 1um
  OPEN(22,FILE=TRIM(SPECFIT_HOME)//'/infiles/M7III.spec.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(22,*) 
  ENDDO
  DO i=1,nl
     READ(22,*) d1,sspgrid%m7g(i)
  ENDDO
  CLOSE(22)
 

  !read in hot stars 

  OPEN(23,FILE=TRIM(SPECFIT_HOME)//'/infiles/ap00t8000g4.00at12.spec.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(23,*) 
  ENDDO
  DO i=1,nl
     READ(23,*) d1,sspgrid%hotspec(i,1)
  ENDDO
  CLOSE(23)

  OPEN(23,FILE=TRIM(SPECFIT_HOME)//'/infiles/ap00t10000g4.00at12.spec.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(23,*) 
  ENDDO
  DO i=1,nl
     READ(23,*) d1,sspgrid%hotspec(i,2)
  ENDDO
  CLOSE(23)

  OPEN(24,FILE=TRIM(SPECFIT_HOME)//'/infiles/ap00t20000g4.00at12.spec.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(24,*) 
  ENDDO
  DO i=1,nl
     READ(24,*) d1,sspgrid%hotspec(i,3)
  ENDDO
  CLOSE(24)

  OPEN(25,FILE=TRIM(SPECFIT_HOME)//'/infiles/ap00t30000g4.00at12.spec.s100',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(25,*) 
  ENDDO
  DO i=1,nl
     READ(25,*) d1,sspgrid%hotspec(i,4)
  ENDDO
  CLOSE(25)
 
  !normalize to 5000A
  vv = locate(sspgrid%lam(1:nl),l5000)
  DO i=1,nhot
     sspgrid%hotspec(i,:) = sspgrid%hotspec(i,:)/sspgrid%hotspec(vv,i)*&
          10**sspgrid%logfkrpa(vv,6)
  ENDDO
  !hot star Teff in kK
  sspgrid%teffarrhot = (/8.0,10.,20.,30./)

  !define central wavelengths of emission lines (in vacuum)
  emlines(1)  = 4960.30  ! [OIII]
  emlines(2)  = 5008.24  ! [OIII]
  emlines(3)  = 5203.05  ! [NI]
  emlines(4)  = 6549.84  ! [NII]
  emlines(5)  = 6564.61  ! [Ha]
  emlines(6)  = 6585.23  ! [NII]
  emlines(7) = 6718.32  ! [SII]
  emlines(8) = 6732.71  ! [SII]

  !read in template error function (computed from SDSS stacks)
  !NB: this hasn't been used in years!
  OPEN(22,FILE=TRIM(SPECFIT_HOME)//'/infiles/temperrfcn.s350',&
       STATUS='OLD',iostat=stat,ACTION='READ')
  DO i=1,nstart-1
     READ(22,*) 
  ENDDO
  DO i=1,nl
     READ(22,*) d1,temperrfcn(i)
  ENDDO
  CLOSE(22)
 

  !smooth the models to the input instrumental resolution
  IF (MAXVAL(data(1:datmax)%ires).GT.10.0) THEN

     !the interpolation here is a massive extrapoltion beyond the range
     !of the data.  This *should't* matter since we dont use the model
     !beyond the range of the data, but I should double check this at some point
     smooth = linterp(data(1:datmax)%lam,data(1:datmax)%ires,sspgrid%lam)
     smooth = MIN(MAX(smooth,0.0),MAXVAL(data(1:datmax)%ires))

     DO j=1,nage_rfcn
        CALL VELBROAD(lam,sspgrid%solar(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nap(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nam(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cap(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cam(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%fep(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%fem(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cm(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%zp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%zm(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%np(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nm(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%ap(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%tip(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%tim(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%mgp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%mgm(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%sip(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%sim(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%hep(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%hem(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%teffp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%teffm(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%crp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%mnp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%bap(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%bam(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nip(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cop(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%eup(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%srp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%kp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%vp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%yp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%zrp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%rbp(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%cup(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nap6(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
        CALL VELBROAD(lam,sspgrid%nap9(:,j),sig0,l1(1)-100,l2(nlint)+100,smooth)
     ENDDO

     DO i=1,nhot
        CALL VELBROAD(lam,sspgrid%hotspec(i,:),sig0,l1(1)-100,l2(nlint)+100,smooth)
     ENDDO

     CALL VELBROAD(lam,sspgrid%m7g,sig0,l1(1)-100,l2(nlint)+100,smooth)

     DO j=1,nimf
        DO k=1,nimf
           CALL VELBROAD(lam,sspgrid%imf(:,j,k),sig0,l1(1)-100,l2(nlint)+100,smooth)
        ENDDO
     ENDDO

     sspgrid%logfkrpa = 10**sspgrid%logfkrpa
     DO i=1,nage
        CALL VELBROAD(lam,sspgrid%logfkrpa(:,i),sig0,l1(1)-100,l2(nlint)+100,smooth)
     ENDDO
     sspgrid%logfkrpa = LOG10(sspgrid%logfkrpa+tiny_number)

  ENDIF

  !locate where lam=7000A
  lam7 = locate(lam,7000.d0)


END SUBROUTINE SFSETUP
