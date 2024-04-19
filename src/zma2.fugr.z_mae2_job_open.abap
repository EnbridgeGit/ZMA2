FUNCTION Z_MAE2_JOB_OPEN.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(TARGET_JOBNAME) LIKE  TBTCJOB-JOBNAME
*"                             DEFAULT SPACE
*"       EXPORTING
*"             VALUE(NEW_JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT
*"       EXCEPTIONS
*"              CANT_CREATE_JOB
*"              INVALID_JOB_DATA
*"              JOBNAME_MISSING
*"----------------------------------------------------------------------
*
*  Maestro wrapper  for job_open function.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1995 by iXOS Software, All Rights Reserved.
*
*  History:
*     Coded   6/4/96    Ravi Ramaswamy   initial coding
*
*
* call function job_open

CALL FUNCTION 'JOB_OPEN'
     EXPORTING
          JOBNAME          = TARGET_JOBNAME
     IMPORTING
          JOBCOUNT         = NEW_JOBCOUNT
     EXCEPTIONS
          CANT_CREATE_JOB  = 01
          INVALID_JOB_DATA = 02
          JOBNAME_MISSING  = 03.
IF SY-SUBRC <> 0.
  CASE SY-SUBRC.
    WHEN 1.
      RAISE CANT_CREATE_JOB.
    WHEN 2.
      RAISE INVALID_JOB_DATA.
    WHEN 3.
      RAISE JOBNAME_MISSING.
  ENDCASE.
ENDIF.

ENDFUNCTION.
