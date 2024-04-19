FUNCTION Z_MAE2_JOB_FIND.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(CLIENT) LIKE  TBTCJOB-AUTHCKMAN
*"             VALUE(JOBSELECT_DIALOG) LIKE  BTCH0000-CHAR1
*"             VALUE(JOBSEL_PARAM_IN) LIKE  BTCSELECT
*"                             STRUCTURE  BTCSELECT
*"       EXPORTING
*"             VALUE(JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT
*"             VALUE(JOBSEL_PARAM_OUT) LIKE  BTCSELECT
*"                             STRUCTURE  BTCSELECT
*"             VALUE(MATCHES) LIKE  BTCH0000-INT4
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
*  in the database that match the input parameters: jobname, username,
*  and client number.  The number of jobs that match on all three AND
*  THAT ARE NOT RELEASED is returned in MATCHES.  By checking MATCHES
*  the user can be warned if more than one candidate was found.
*
*  Released jobs are ignored because they are either already run or
*  are already scheduled to run, so they are not our "prototype" job
*  definition.  We look for jobs that are defined but not yet assigned
*  a time to run.
*
*  Unlike BP_JOB_SELECT we do not return a table of matches (which would
*  be just fine if mixed-type tables could be passed via RFC calls).
*  Instead we pass back the unique job id (JOBCOUNT) of the first match
*  and the total number of matches.  Not as good as a table, but it
*  suits our purposes.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1996 by iXOS Software, All Rights Reserved
*
*  History:
*     Coded 02/29/96 Chadwick  Initial coding
*     Modif 03/04/96 Chadwick  Added MATCHES param for diagnosing dups
*
  DATA: BEGIN OF Z_JOBSELECT_JOBLIST OCCURS 100.
          INCLUDE STRUCTURE TBTCJOB.
  DATA: END OF Z_JOBSELECT_JOBLIST.
*
IF CLIENT EQ ' '.
  RAISE CLIENT_MISSING.
ENDIF.

  CALL FUNCTION 'BP_JOB_SELECT'
       EXPORTING
            JOBSELECT_DIALOG    = JOBSELECT_DIALOG
            JOBSEL_PARAM_IN     = JOBSEL_PARAM_IN
       IMPORTING
            JOBSEL_PARAM_OUT    = JOBSEL_PARAM_OUT
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
  MATCHES = 0.
  LOOP AT  Z_JOBSELECT_JOBLIST.
    IF Z_JOBSELECT_JOBLIST-RELDATE EQ SPACE OR
       Z_JOBSELECT_JOBLIST-RELDATE EQ '00000000' AND
       Z_JOBSELECT_JOBLIST-AUTHCKMAN EQ CLIENT.
      MOVE Z_JOBSELECT_JOBLIST-JOBCOUNT TO JOBCOUNT.
      MATCHES = MATCHES + 1.
    ENDIF.
  ENDLOOP.
*
ENDFUNCTION.
