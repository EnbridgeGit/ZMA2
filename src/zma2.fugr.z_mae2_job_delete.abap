FUNCTION Z_MAE2_JOB_DELETE.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(TARGET_JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT
*"             VALUE(TARGET_JOBNAME) LIKE  TBTCJOB-JOBNAME
*"       EXCEPTIONS
*"              JOB_DELETE_FAILED
*"----------------------------------------------------------------------
*
*  Maestro wrapper  for job_delete function.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1995 by iXOS Software, All Rights Reserved.
*
*  History:
*     Coded   6/4/96    Ravi Ramaswamy   initial coding
*
*
* call function job_delete
BREAK RAVI.

CALL FUNCTION 'BP_JOB_DELETE'
    EXPORTING
               FORCEDMODE         = 'X'
               JOBNAME            = TARGET_JOBNAME
               JOBCOUNT           = TARGET_JOBCOUNT
    EXCEPTIONS
               OTHERS             = 99.
    IF SY-SUBRC <> 0.
      RAISE JOB_DELETE_FAILED.
    ENDIF.

ENDFUNCTION.
