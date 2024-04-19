FUNCTION Z_MAE2_JOB_START.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(JOBCLASS) LIKE  TBTCO-JOBCLASS
*"             VALUE(JOBCOUNT) LIKE  TBTCO-JOBCOUNT
*"             VALUE(JOBNAME) LIKE  TBTCO-JOBNAME
*"             VALUE(USERNAME) LIKE  TBTCO-SDLUNAME
*"       EXCEPTIONS
*"              BOGUS_JOBCLASS
*"              CANT_START_IMMEDIATE
*"              FAILURE_IN_JOB_SELECT
*"              INVALID_STARTDATE
*"              JOBCOUNT_MISSING
*"              JOBNAME_MISSING
*"              JOB_CLOSE_FAILED
*"              JOB_NOSTEPS
*"              JOB_NOTEX
*"              JOB_VANISHED
*"              LOCK_FAILED
*"              USERNAME_MISSING
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to start a job immediately.
*  (This is a replacement routine for the earlier "Z_MAE_START_JOB")
*
*  Identifies the job to be started by JOBCOUNT, JOBNAME and USERNAME,
*      then starts the job with the priority class JOBCLASS.  If the
*      JOBCLASS parameter is "*", then we leave the priority as it is.
*  The "start immediate" flag is set by JOB_CLOSE so that the job is
*      run by R/3 as soon as a batch work process becomes available.
*
*  As of the Mar96 rev we first call BP_JOB_SELECT to extract the
*      "target host" specification for this job, so that we can pass
*      it to JOB_CLOSE.  Otherwise JOB_CLOSE will pick up its default
*      parameter (blank) and force the "target host" to blank, thus
*      overwriting what the user gave for target host.  Bummer.
*  So we look up the original value and pass it to JOB_CLOSE so that
*      the target host field isn't overwritten with blanks.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) by iXOS Software, 1995-1996.  All Rights Reserved.
*
*  History:
*    Coded:    Chadwick 11/03/95 Initial coding
*    Modified: Chadwick 03/13/96 Added code to call BP_JOB_SELECT and
*                                pass the job's target host to JOB_CLOSE
*
*=======================================================================
*
  DATA: BEGIN OF Z_JOBSELECT_JOBLIST OCCURS 100.
          INCLUDE STRUCTURE TBTCJOB.
  DATA: END OF Z_JOBSELECT_JOBLIST.
  DATA: BEGIN OF Z_JOBSEL_PARAM_IN.
          INCLUDE STRUCTURE BTCSELECT.
  DATA: END OF Z_JOBSEL_PARAM_IN.
  DATA: BEGIN OF Z_JOBSEL_PARAM_OUT.
          INCLUDE STRUCTURE BTCSELECT.
  DATA: END OF Z_JOBSEL_PARAM_OUT.
*
  DATA: TARGETHOST LIKE TBTCJOB-BTCSYSREAX.
  DATA: JOB_WAS_RELEASED LIKE BTCH0000-CHAR1.
*
  IF JOBCOUNT = SPACE.
    RAISE JOBCOUNT_MISSING.
  ENDIF.
  IF JOBNAME = SPACE.
    RAISE JOBNAME_MISSING.
  ENDIF.
  IF USERNAME = SPACE.
    RAISE USERNAME_MISSING.
  ENDIF.
  IF JOBCLASS <> 'A' AND JOBCLASS <> 'B' AND
     JOBCLASS <> 'C' AND JOBCLASS <> '*' .
    RAISE BOGUS_JOBCLASS.
  ENDIF.
*
  CLEAR Z_JOBSEL_PARAM_IN.
  Z_JOBSEL_PARAM_IN-JOBNAME = JOBNAME.
  Z_JOBSEL_PARAM_IN-JOBCOUNT = JOBCOUNT.
  Z_JOBSEL_PARAM_IN-USERNAME = USERNAME.
  CLEAR Z_JOBSEL_PARAM_OUT.
  CALL FUNCTION 'BP_JOB_SELECT'
       EXPORTING
            JOBSELECT_DIALOG    = 'N'
            JOBSEL_PARAM_IN     = Z_JOBSEL_PARAM_IN
       IMPORTING
            JOBSEL_PARAM_OUT    = Z_JOBSEL_PARAM_OUT
       TABLES
            JOBSELECT_JOBLIST   = Z_JOBSELECT_JOBLIST
       EXCEPTIONS
            INVALID_DIALOG_TYPE = 01
            JOBNAME_MISSING     = 02
            NO_JOBS_FOUND       = 03
            SELECTION_CANCELED  = 04
            USERNAME_MISSING    = 05.
  IF SY-SUBRC <> 0.
    RAISE FAILURE_IN_JOB_SELECT.
  ENDIF.
*
  TARGETHOST = '*NF*'.                 " '*NF*' indicates "not found"
  LOOP AT Z_JOBSELECT_JOBLIST.
    IF Z_JOBSELECT_JOBLIST-JOBCOUNT EQ JOBCOUNT.
      MOVE Z_JOBSELECT_JOBLIST-BTCSYSTEM TO TARGETHOST.
    ENDIF.
  ENDLOOP.
*
  IF TARGETHOST = '*NF*'.
    RAISE JOB_VANISHED.                " It was there a minute ago...
  ENDIF.
*
*  Find the one row in TBTCO where the jobname ane jobcount match ours.
*
  SELECT COUNT(*) FROM TBTCO
                  WHERE JOBNAME = JOBNAME
                  AND JOBCOUNT = JOBCOUNT.
*
*  If exactly one row matches (as it should) AND if jobclass is
*  not '*' (which means don't change the jobclass), then update the
*  jobclass for this job in TBTCO.

  IF SY-DBCNT = 1 AND JOBCLASS <> '*'.
    UPDATE TBTCO SET JOBCLASS = JOBCLASS
                 WHERE JOBNAME = JOBNAME
                   AND JOBCOUNT = JOBCOUNT.
  ENDIF.
*
  CALL FUNCTION 'JOB_CLOSE'
       EXPORTING
            JOBCOUNT             = JOBCOUNT
            JOBNAME              = JOBNAME
            STRTIMMED            = 'X'
            TARGETSYSTEM         = TARGETHOST
       IMPORTING
            JOB_WAS_RELEASED     = JOB_WAS_RELEASED
       EXCEPTIONS
            CANT_START_IMMEDIATE = 01
            INVALID_STARTDATE    = 02
            JOBNAME_MISSING      = 03
            JOB_CLOSE_FAILED     = 04
            JOB_NOSTEPS          = 05
            JOB_NOTEX            = 06
            LOCK_FAILED          = 07.
*
  CASE SY-SUBRC.
    WHEN 1.
      RAISE CANT_START_IMMEDIATE.
    WHEN 2.
      RAISE INVALID_STARTDATE.
    WHEN 3.
      RAISE JOBNAME_MISSING.
    WHEN 4.
      RAISE JOB_CLOSE_FAILED.
    WHEN 5.
      RAISE JOB_NOSTEPS.
    WHEN 6.
      RAISE JOB_NOTEX.
    WHEN 7.
      RAISE LOCK_FAILED.
  ENDCASE.
*
ENDFUNCTION.
