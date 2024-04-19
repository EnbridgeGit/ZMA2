FUNCTION Z_MAE2_JOB_STOP.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(JOBCOUNT) LIKE  TBTCO-JOBCOUNT
*"             VALUE(JOBNAME) LIKE  TBTCO-JOBNAME
*"       EXCEPTIONS
*"              CHECKING_OF_JOB_HAS_FAILED
*"              JOBCOUNT_MISSING
*"              JOBNAME_MISSING
*"              JOB_ABORT_HAS_FAILED
*"              JOB_DOES_NOT_EXIST
*"              JOB_IS_NOT_ACTIVE
*"              NO_ABORT_PRIVILEGE_GIVEN
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to abort a running job.
*
*  Identifies the job to be started using JOBCOUNT and JOBNAME,
*      then aborts the job.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1995 by iXOS Software, All Rights Reserved.
*
*  History:
*    Coded:    Chadwick 11/03/95 Initial coding
*    Modified:
*
*=======================================================================
*
  IF JOBCOUNT = SPACE.
    RAISE JOBCOUNT_MISSING.
  ENDIF.
  IF JOBNAME = SPACE.
    RAISE JOBNAME_MISSING.
  ENDIF.
*
  CALL FUNCTION 'BP_JOB_ABORT'
       EXPORTING
            JOBCOUNT                   = JOBCOUNT
            JOBNAME                    = JOBNAME
       EXCEPTIONS
            CHECKING_OF_JOB_HAS_FAILED = 01
            JOB_ABORT_HAS_FAILED       = 02
            JOB_DOES_NOT_EXIST         = 03
            JOB_IS_NOT_ACTIVE          = 04
            NO_ABORT_PRIVILEGE_GIVEN   = 05.
*
  CASE SY-SUBRC.
    WHEN 1.
      RAISE CHECKING_OF_JOB_HAS_FAILED.
    WHEN 2.
      RAISE JOB_ABORT_HAS_FAILED.
    WHEN 3.
      RAISE JOB_DOES_NOT_EXIST.
    WHEN 4.
      RAISE JOB_IS_NOT_ACTIVE.
    WHEN 5.
      RAISE NO_ABORT_PRIVILEGE_GIVEN.
  ENDCASE.
*
ENDFUNCTION.
