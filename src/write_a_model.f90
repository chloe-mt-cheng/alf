PROGRAM WRITE_A_MODEL

  !write a model to file

  USE alf_vars; USE alf_utils
  USE nr, ONLY : gasdev,locate,powell,ran1
  USE ran_state, ONLY : ran_seed,ran_init

  IMPLICIT NONE

  INTEGER  :: i
  REAL(DP) :: s2n,lmin,lmax,ires=0.,emnorm
  REAL(DP), DIMENSION(nl) :: mspec,lam,err,gdev
  CHARACTER(100)  :: file=''
  TYPE(PARAMS)   :: pos
  
  !-----------------------------------------------------------!
  !-----------------------------------------------------------!

  !instrumental resolution (<10 -> no broadening)
  ires = 1.

  !initialize the random number generator
  CALL INIT_RANDOM_SEED()
  !compute an array of gaussian deviates
  CALL GASDEV(gdev)

  file = 'model4_sn1E4.spec'
  s2n    = 1E4
  lmin   = 3900.
  lmax   = 10000.
  emnorm = -5.0

  pos%sigma   = 300.0
  pos%logage  = LOG10(12.0)
  pos%feh     = 0.05
  pos%ah      = 0.35
  pos%nhe     = 0.0
  pos%ch      = 0.25
  pos%nh      = 0.25
  pos%nah     = 0.5
  pos%mgh     = 0.35
  pos%sih     = 0.35
  pos%kh      = 0.0
  pos%cah     = 0.05
  pos%tih     = 0.25
  pos%vh      = 0.25
  pos%crh     = 0.05
  pos%mnh     = 0.05
  pos%coh     = 0.25
  pos%nih     = 0.05
  pos%cuh     = 0.0
  pos%rbh     = 0.0
  pos%srh     = 0.0
  pos%yh      = 0.0
  pos%zrh     = 0.0
  pos%bah     = 0.0
  pos%euh     = 0.0
  pos%teff    = -40.0
  pos%imf1    = 1.3
  pos%imf2    = 2.3
  pos%logfy   = -5.0
  pos%fy_logage = 0.3
  pos%logtrans  = -5.0
  pos%sigma2  = 300.
  pos%velz    = 5000.
  pos%velz2   = 0.0
  pos%logm7g  = -5.0
  pos%hotteff = 20.0
  pos%loghot  = -4.0
  pos%logemline_h=emnorm
  pos%logemline_oiii=emnorm
  pos%logemline_sii=emnorm
  pos%logemline_ni=emnorm
  pos%logemline_nii=emnorm

  !force a constant instrumental resolution
  !needs to be done this way for setup.f90 to work
  datmax=10000
  DO i=1,datmax
     data(i)%lam=i+3500
  ENDDO
  data(1:datmax)%ires = ires

  !read in the SSPs and bandpass filters
  CALL SETUP()
  lam = sspgrid%lam

  !define the log wavelength grid used in velbroad.f90
  nl_fit = MIN(MAX(locate(lam,lmax+500.0),1),nl)
  dlstep = (LOG(sspgrid%lam(nl_fit))-LOG(sspgrid%lam(1)))/nl_fit
  DO i=1,nl_fit
     lnlam(i) = i*dlstep+LOG(sspgrid%lam(1))
  ENDDO
  l1(1) = lmin
  nlint = 2
  l2(nlint) = lmax

  !get a model spectrum
  CALL GETMODEL(pos,mspec)

  IF (1.EQ.1) THEN
     err   = mspec/s2n
     mspec = mspec + err*gdev
  ELSE
     DO i=1,nl
        IF (lam(i).LT.4600) THEN
           err(i) = mspec(i)/10. 
           mspec(i) = mspec(i) + err(i)*gdev(i)
        ELSE
           err(i) = mspec(i)/30.
           mspec(i) = mspec(i) + err(i)*gdev(i)
        ENDIF
     ENDDO
  ENDIF
  
  !write model spectrum to file
  OPEN(12,FILE=TRIM(SPECFIT_HOME)//'models/'//&
       TRIM(file),STATUS='REPLACE')
  DO i=1,nl
     IF (lam(i).GE.lmin.AND.lam(i).LE.lmax) THEN
        WRITE(12,'(F10.3,2ES12.4,2x,2F4.1)') lam(i),mspec(i),err(i),1.0,ires
     ENDIF
  ENDDO
  CLOSE(12)


END PROGRAM WRITE_A_MODEL
