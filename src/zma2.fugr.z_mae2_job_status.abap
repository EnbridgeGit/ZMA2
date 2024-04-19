FUNCTION Z_MAE2_JOB_STATUS.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(CLIENT) LIKE  TBTCJOB-AUTHCKMAN
*"             VALUE(JOBSELECT_DIALOG) LIKE  BTCH0000-CHAR1
*"             VALUE(JOBSEL_PARAM_IN) LIKE  BTCSELECT
*"                             STRUCTURE  BTCSELECT DEFAULT SPACE
*"       EXPORTING
*"             VALUE(JOBSTATUS) LIKE  TBTCJOB-STATUS
*"       EXCEPTIONS
*"              CLIENT_MISSING
*"              INVALID_DIALOG_TYPE
*"              JOBNAME_MISSING
*"              NO_JOBS_FOUND
*"              SELECTION_CANCELED
*"              USERNAME_MISSING
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to call BP_JOB_SELECT.  It finds jobs
*  in the database that match the input parameters: jobname, jobcount,
*  and client number.  There should be only one job found with the
*  specified jobcount.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1996 by iXOS Software, All Rights Reserved
*
*  History:
*     Coded 09/12/96 Ravi Ramaswamy  Initial coding
*
  DATA: BEGIN OF Z_JOBSELECT_JOBLIST OCCURS 100.
          INCLUDE STRUCTURE TBTCJOB.
  DATA: END OF Z_JOBSELECT_JOBLIST.

IF CLIENT EQ ' '.
  RAISE CLIENT_MISSING.
ENDIF.

  CALL FUNCTION 'BP_JOB_SELECT'
       EXPORTING
            JOBSELECT_DIALOG    = JOBSELECT_DIALOG
            JOBSEL_PARAM_IN     = JOBSEL_PARAM_IN
       TABLES
            JOBSELECT_JOBLIST   = Z_JOBSELECT_JOBLIST
       EXCEPTIONS
            INVALID_DIALOG_TYPE = 01
            JOBNAME_MISSING     = 02
            NO_JOBS_FOUND       = 03
            SELECTION_CANCELED  = 04
            USERNAME_MISSING    = 05.

  IF SY-SUBRC <> 0.
    CASE SY-SUBRC.
      WHEN 1.
        RAISE INVALID_DIALOG_TYPE.
      WHEN 2.
        RAISE JOBNAME_MISSING.
      WHEN 3.
        RAISE NO_JOBS_FOUND.
      WHEN 4.
        RAISE SELECTION_CANCELED.
      WHEN 5.
        RAISE USERNAME_MISSING.
    ENDCASE.
  ENDIF.
*
  LOOP AT Z_JOBSELECT_JOBLIST.
    IF Z_JOBSELECT_JOBLIST-JOBCOUNT EQ JOBSEL_PARAM_IN-JOBCOUNT.
      JOBSTATUS = Z_JOBSELECT_JOBLIST-STATUS.
    ENDIF.
  ENDLOOP.
*
ENDFUNCTION.
