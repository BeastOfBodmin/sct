MODULE SJP_UTIL
! Module containing common code for SAS analysis programs
! Original author: Stephen J. Perkins
! Rewritten: David W. Wright
! Date: 08 October 2013


IMPLICIT NONE

CONTAINS

SUBROUTINE GET_FILENAME (MSG, FILENAME)

    CHARACTER(LEN=*), INTENT(IN) :: MSG
    CHARACTER(LEN=*), INTENT(OUT) :: FILENAME

    LOGICAL VALID

    VALID = .FALSE.
    DO WHILE ( .NOT. VALID)
        WRITE(*,'(1X,A)') MSG
        READ (*,'(A)') FILENAME
        IF (FILENAME .NE. ' ') THEN
            VALID = .TRUE.
        ELSE
            WRITE (*,'(1X,A)') 'Error: Please supply a filename'
        END IF
    END DO

    RETURN
    
END SUBROUTINE GET_FILENAME

SUBROUTINE READ_SCATTER_FILE (FILENAME, QMIN, Q, I, NO)

    ! Read in scattering data
    ! Assume that the file has Q and I as the first two columns
    ! NO = number of values read from file
    
    CHARACTER(LEN=*), INTENT(IN) :: FILENAME
    DOUBLE PRECISION, INTENT(IN) :: QMIN
    DOUBLE PRECISION, DIMENSION(*), INTENT(INOUT) :: Q , I
    INTEGER, INTENT(OUT) :: NO

    DOUBLE PRECISION :: TMPQ, TMPI
    LOGICAL :: FILEEXISTS
    INTEGER :: IERR, UNIT_NO
        
    UNIT_NO = 12
    
    INQUIRE(FILE=FILENAME, EXIST=FILEEXISTS)
    IF (.NOT. FILEEXISTS) THEN
        WRITE(*,*) 'Specified file does not exist: ', FILENAME
        STOP
    ELSE
        OPEN(UNIT=UNIT_NO, FILE=FILENAME, STATUS='OLD', ACTION='READ')
        NO = 1
        DO 
            READ(UNIT_NO, *, IOSTAT=IERR) TMPQ, TMPI
            IF (IERR .LT. 0) THEN
                NO = NO - 1
                EXIT
            ELSE IF (IERR .NE. 0) THEN
                WRITE(*,*) 'Abort: Error reading file: ', FILENAME
                STOP
            ELSE IF (TMPQ .GE. QMIN) THEN
                Q(NO) = TMPQ
                I(NO) = TMPI
                NO = NO + 1
            END IF
        END DO
        
        CLOSE(UNIT_NO)
    END IF
        
    RETURN
        
END SUBROUTINE READ_SCATTER_FILE
      
SUBROUTINE QRANGE_MATCH(QOBS, QCALC, ICALC, XNO, CNO, IMATCH, MNO)
 
    ! Match modelled I values with experimental Q range 
        
    ! QOBS = Experimental Q values
    ! QCALC, ICALC = Modelled Q and I values
    ! XNO = no. experimental values, CNO = no. modelled values
    ! IMATCH = Modelled I values matched to experimental Q values
    ! MNO = no. matched values
    DOUBLE PRECISION, DIMENSION(*), INTENT(IN) :: QOBS, QCALC, ICALC    
    INTEGER, INTENT(IN) :: XNO, CNO
    DOUBLE PRECISION, DIMENSION(*), INTENT(OUT) :: IMATCH
    INTEGER, INTENT(OUT) :: MNO
        
    INTEGER :: I, J
    DOUBLE PRECISION :: QMINDIFF, DELTAQ

    ! Find the last experimental Q value that overlaps with the modelled ones
    MNO = 0
    DO I = 1, (XNO)
        IF ( QOBS(I) .LE. QCALC(CNO) ) MNO = MNO + 1
    END DO

    ! Find the corresponding modelled Q values for each experimental one
    ! Store the corresponding I value in IMATCH
    DO I = 1, MNO
        ! Set initial Q minimum difference to a very big number
        QMINDIFF = 1.0E+13
        DO J = 0, (CNO)
            DELTAQ = ABS( QOBS(I) - QCALC(J) )
            IF ( DELTAQ .LT. QMINDIFF ) THEN
                QMINDIFF = DELTAQ
                IMATCH(I) = ICALC(J)
            ENDIF
        END DO
    END DO

    RETURN
      
END SUBROUTINE QRANGE_MATCH
      
DOUBLE PRECISION FUNCTION AVERAGE_DATA (DATAIN, N)
    
    ! Calculate average of values in DATAIN for indices 0 to N
    DOUBLE PRECISION, DIMENSION(*), INTENT(IN) :: DATAIN
    INTEGER, INTENT(IN) :: N
    
    INTEGER :: I
    DOUBLE PRECISION :: TOTAL
    
    TOTAL = 0
    DO I = 1, N
        TOTAL = TOTAL + DATAIN(I)
    END DO

    AVERAGE_DATA = TOTAL / N

END FUNCTION AVERAGE_DATA
    
DOUBLE PRECISION FUNCTION CALC_RFACTOR (QOBS, IOBS, IMATCH, N, QMIN, QMAX, CON, VERBOSE)
    
    ! Calculate the R factor comparing IOBS to IMATCH
    
    DOUBLE PRECISION, DIMENSION(*), INTENT(IN) :: QOBS, IOBS, IMATCH
    INTEGER, INTENT(IN) :: N
    DOUBLE PRECISION, INTENT(IN) :: QMIN, QMAX
    DOUBLE PRECISION, INTENT(INOUT) :: CON
    LOGICAL, INTENT(IN) :: VERBOSE
        
    DOUBLE PRECISION :: DELTAC, ORFAC, RFNUM, RFDEN, RFACTOR
    INTEGER :: NDX

    ! Initialize the update and R factor
    DELTAC = CON / 10.
    RFACTOR = 1000000.
        
    DO WHILE ( ( ABS(DELTAC) ) .GT. ( CON / 10000. ) )
    
        ORFAC = RFACTOR
        RFACTOR = 0.
        RFNUM = 0.
        RFDEN = 0.
            
        DO NDX = 1, N
            IF ( ( QOBS(NDX) .LE. QMAX ) .AND. ( QOBS(NDX) .GT. QMIN ) ) THEN
                RFNUM = RFNUM + ABS( ( IOBS(NDX) / CON ) - IMATCH(NDX) )
                RFDEN = RFDEN + ABS( IOBS(NDX) / CON )
            END IF
        END DO
            
        RFACTOR = RFNUM / RFDEN
            
        IF (VERBOSE) THEN
            WRITE(*,*) 'BEST YET:', DELTAC, CON, RFACTOR
        END IF
            
        IF (RFACTOR .LT. ORFAC) THEN
            CON = CON + DELTAC
        ELSE    
            DELTAC = DELTAC * (-0.5)
            CON = CON + DELTAC
        ENDIF
            
    END DO
    
    IF (VERBOSE) THEN
        WRITE(*,*) 'FINISHED WITH:', DELTAC, CON, RFACTOR
    END IF
        
    CALC_RFACTOR = RFACTOR * 100

END FUNCTION CALC_RFACTOR

END MODULE SJP_UTIL
