FUNCTION GETMASS(mlo,mto,imf1,imf2,imfup,imf3,imf4,timfnorm)

  !compute mass in stars and remnants (normalized to 1 Msun at t=0)
  !assume an IMF that runs from 0.08 to 100 Msun.

  USE alf_vars
  IMPLICIT NONE

  !turnoff mass
  REAL(DP), INTENT(in) :: mlo,mto,imf1,imf2,imfup
  REAL(DP), INTENT(in), OPTIONAL :: imf3,imf4
  REAL(DP), INTENT(inout), OPTIONAL :: timfnorm
  REAL(DP) :: imfnorm, getmass
  REAL(DP), PARAMETER :: bhlim=40.0,nslim=8.5
  REAL(DP) :: m2=0.5,m3=1.0,alpha

  !---------------------------------------------------------------!
  !---------------------------------------------------------------!

  IF (mlo.GT.m2) THEN
     WRITE(*,*) 'GETMASS ERROR: mlo>m2'
     STOP
  ENDIF

  getmass  = 0.d0

  IF (.NOT.PRESENT(imf4)) THEN

     !normalize the weights so that 1 Msun formed at t=0
     imfnorm = (m2**(-imf1+2)-mlo**(-imf1+2))/(-imf1+2) + &
          m2**(-imf1+imf2)*(m3**(-imf2+2)-m2**(-imf2+2))/(-imf2+2) + &
          m2**(-imf1+imf2)*(imfhi**(-imfup+2)-m3**(-imfup+2))/(-imfup+2)

     !stars still alive
     getmass = (m2**(-imf1+2)-mlo**(-imf1+2))/(-imf1+2)
     IF (mto.LT.m3) THEN
        getmass = getmass + m2**(-imf1+imf2)*(mto**(-imf2+2)-m2**(-imf2+2))/(-imf2+2)
     ELSE
        getmass = getmass + m2**(-imf1+imf2)*(m3**(-imf2+2)-m2**(-imf2+2))/(-imf2+2) + &
             m2**(-imf1+imf2)*(mto**(-imfup+2)-m3**(-imfup+2))/(-imfup+2)
     ENDIF
     getmass = getmass/imfnorm

     !BH remnants
     !40<M<imf_up leave behind a 0.5*M BH
     getmass = getmass + &
          0.5*m2**(-imf1+imf2)*(imfhi**(-imfup+2)-bhlim**(-imfup+2))/(-imfup+2)/imfnorm

     !NS remnants
     !8.5<M<40 leave behind 1.4 Msun NS
     getmass = getmass + &
          1.4*m2**(-imf1+imf2)*(bhlim**(-imfup+1)-nslim**(-imfup+1))/(-imfup+1)/imfnorm

     !WD remnants
     !M<8.5 leave behind 0.077*M+0.48 WD
     IF (mto.LT.m3) THEN
        getmass = getmass + &
             0.48*m2**(-imf1+imf2)*(nslim**(-imfup+1)-m3**(-imfup+1))/(-imfup+1)/imfnorm
        getmass = getmass + &
             0.48*m2**(-imf1+imf2)*(m3**(-imf2+1)-mto**(-imf2+1))/(-imf2+1)/imfnorm
        getmass = getmass + &
             0.077*m2**(-imf1+imf2)*(nslim**(-imfup+2)-m3**(-imfup+2))/(-imfup+2)/imfnorm
        getmass = getmass + &
             0.077*m2**(-imf1+imf2)*(m3**(-imf2+2)-mto**(-imf2+2))/(-imf2+2)/imfnorm
     ELSE
        getmass = getmass + &
             0.48*m2**(-imf1+imf2)*(nslim**(-imfup+1)-mto**(-imfup+1))/(-imfup+1)/imfnorm
        getmass = getmass + &
             0.077*m2**(-imf1+imf2)*(nslim**(-imfup+2)-mto**(-imfup+2))/(-imfup+2)/imfnorm
     ENDIF

  ELSE

     !non-parametric IMF

     alpha = 2.0 - nonpimf_alpha

     imfnorm = 10**imf1/alpha*(mbin_nimf(1)**alpha-mlo**alpha) + &
          10**imf2/alpha*(mbin_nimf(2)**alpha-mbin_nimf(1)**alpha) + &
          10**imf3/alpha*(mbin_nimf(3)**alpha-mbin_nimf(2)**alpha) + &
          10**imf4/alpha*(mbin_nimf(4)**alpha-mbin_nimf(3)**alpha) + &
          10**imf5/alpha*(mbin_nimf(5)**alpha-mbin_nimf(4)**alpha) + &
          10**imf5/(-imfup+2)/(mbin_nimf(5)**(-imfup)) * &
          (imfhi**(-imfup+2)-mbin_nimf(5)**(-imfup+2)) 

     IF (mto.GT.mbin_nimf(5)) THEN

        ! MSTO > 1.0
        
        getmass = 10**imf1/alpha*(mbin_nimf(1)**alpha-mlo**alpha) + &
             10**imf2/alpha*(mbin_nimf(2)**alpha-mbin_nimf(1)**alpha) + &
             10**imf3/alpha*(mbin_nimf(3)**alpha-mbin_nimf(2)**alpha) + &
             10**imf4/alpha*(mbin_nimf(4)**alpha-mbin_nimf(3)**alpha) + &
             10**imf5/alpha*(mbin_nimf(5)**alpha-mbin_nimf(4)**alpha) + &
             10**imf5/(-imfup+2)/(mbin_nimf(5)**(-imfup)) * &
             (mto**(-imfup+2)-mbin_nimf(5)**(-imfup+2)) 
        
        !WD remnants from MTO-8.5
        getmass = getmass + 0.48*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+1)-mto**(-imfup+1))/(-imfup+1)
        getmass = getmass + 0.077*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+2)-mto**(-imfup+2))/(-imfup+2)

     ELSE IF (mto.GT.mbin_nimf(4).AND.mto.LE.mbin_nimf(5)) THEN

        ! 0.8 < MSTO < 1.0

        getmass = 10**imf1/alpha*(mbin_nimf(1)**alpha-mlo**alpha) + &
             10**imf2/alpha*(mbin_nimf(2)**alpha-mbin_nimf(1)**alpha) + &
             10**imf3/alpha*(mbin_nimf(3)**alpha-mbin_nimf(2)**alpha) + &
             10**imf4/alpha*(mbin_nimf(4)**alpha-mbin_nimf(3)**alpha) + &
             10**imf5/alpha*(mto**alpha-mbin_nimf(4)**alpha) 
        
        !WD remnants from 1.0-8.5
        getmass = getmass + 0.48*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+1)-mbin_nimf(5)**(-imfup+1))/(-imfup+1)
        getmass = getmass + 0.077*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+2)-mbin_nimf(5)**(-imfup+2))/(-imfup+2)
        
        !WD remnants from MSTO-1.0
        getmass = getmass + 0.48*10**imf5/(1-nonpimf_alpha) * &
             (mbin_nimf(5)**(1-nonpimf_alpha)-mto**(1-nonpimf_alpha))
        getmass = getmass + 0.077*10**imf5/alpha * (mbin_nimf(5)**alpha-mto**alpha)

     ELSE

        ! 0.6 < MSTO < 0.8

        getmass = 10**imf1/alpha*(mbin_nimf(1)**alpha-mlo**alpha) + &
             10**imf2/alpha*(mbin_nimf(2)**alpha-mbin_nimf(1)**alpha) + &
             10**imf3/alpha*(mbin_nimf(3)**alpha-mbin_nimf(2)**alpha) + &
             10**imf4/alpha*(mto**alpha-mbin_nimf(3)**alpha) 
        
        !WD remnants from 1.0-8.5
        getmass = getmass + 0.48*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+1)-mbin_nimf(5)**(-imfup+1))/(-imfup+1)
        getmass = getmass + 0.077*10**imf5/(mbin_nimf(5)**(-imfup))*&
             (nslim**(-imfup+2)-mbin_nimf(5)**(-imfup+2))/(-imfup+2)
        
        !WD remnants from 0.8-1.0
        getmass = getmass + 0.48*10**imf5/(1-nonpimf_alpha) * &
             (mbin_nimf(5)**(1-nonpimf_alpha)-mbin_nimf(4)**(1-nonpimf_alpha))
        getmass = getmass + 0.077*10**imf5/alpha * (mbin_nimf(5)**alpha-mbin_nimf(4)**alpha)

        !WD remnants from MSTO-0.8
        getmass = getmass + 0.48*10**imf5/(1-nonpimf_alpha) * &
             (mbin_nimf(4)**(1-nonpimf_alpha)-mto**(1-nonpimf_alpha))
        getmass = getmass + 0.077*10**imf5/alpha * (mbin_nimf(4)**alpha-mto**alpha)


     ENDIF

     !BH remnants
     getmass = getmass + 0.5*10**imf5/(mbin_nimf(5)**(-imfup))*&
          (imfhi**(-imfup+2)-bhlim**(-imfup+2))/(-imfup+2)
     !NS remnants
     getmass = getmass + 1.4*10**imf5/(mbin_nimf(5)**(-imfup))*&
          (bhlim**(-imfup+1)-nslim**(-imfup+1))/(-imfup+1)
 
     getmass = getmass / imfnorm

  ENDIF


  IF (PRESENT(timfnorm)) timfnorm = imfnorm

  RETURN

END FUNCTION GETMASS
