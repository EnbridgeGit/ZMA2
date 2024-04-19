FUNCTION Z_MAE2_JOB_LOG.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(CLIENT) LIKE  TBTCJOB-AUTHCKMAN DEFAULT SPACE
*"             VALUE(JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT DEFAULT SPACE
*"             VALUE(JOBNAME) LIKE  TBTCJOB-JOBNAME DEFAULT SPACE
*"             VALUE(MAXROWS) LIKE  BTCH0000-INT4
*"             VALUE(STARTROW) LIKE  BTCH0000-INT4
*"       EXPORTING
*"             VALUE(ROWCOUNT) LIKE  BTCH0000-INT4
*"       TABLES
*"              JOBLOGTEXT STRUCTURE  YMAEJOBLOG
*"       EXCEPTIONS
*"              CANT_READ_JOBLOG
*"              JOBCOUNT_MISSING
*"              JOBLOG_DOES_NOT_EXIST
*"              JOBLOG_IS_EMPTY
*"              JOBLOG_NAME_MISSING
*"              JOBNAME_MISSING
*"              JOB_DOES_NOT_EXIST
*"              STARTROW_SNAFU
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to retrieve a batch job's log entries
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1995-1997 by iXOS Software, All Rights Reserved.
*
*  History:
*    Coded:
*        Chadwick 04/08/97 Created from old Z_MAE2_JOB_READLOG
*    Modified:
*
*=======================================================================
*
  DATA: BEGIN OF JOBLOGTBL OCCURS 500.
          INCLUDE STRUCTURE TBTC5.
  DATA: END OF JOBLOGTBL.
  DATA: JOBLOG(20)  TYPE C.
  DATA: POSSIBLE    TYPE I.
  DATA: STOPROW     TYPE I.
  DATA: TOTALROWS   TYPE I.
*
  IF JOBCOUNT = SPACE.
    RAISE JOBCOUNT_MISSING.
  ENDIF.
  IF JOBNAME = SPACE.
    RAISE JOBNAME_MISSING.
  ENDIF.
*
  CALL FUNCTION 'BP_JOBLOG_READ'
       EXPORTING
            CLIENT                = SY-MANDT
            JOBCOUNT              = JOBCOUNT
            JOBLOG                = JOBLOG
            JOBNAME               = JOBNAME
       TABLES
            JOBLOGTBL             = JOBLOGTBL
       EXCEPTIONS
            CANT_READ_JOBLOG      = 01
            JOBCOUNT_MISSING      = 02
            JOBLOG_DOES_NOT_EXIST = 03
            JOBLOG_IS_EMPTY       = 04
            JOBLOG_NAME_MISSING   = 05
            JOBNAME_MISSING       = 06
            JOB_DOES_NOT_EXIST    = 07.
*
  CASE SY-SUBRC.
    WHEN 1.
      RAISE CANT_READ_JOBLOG.
    WHEN 2.
      RAISE JOBCOUNT_MISSING.
    WHEN 3.
      RAISE JOBLOG_DOES_NOT_EXIST.
    WHEN 4.
      RAISE JOBLOG_IS_EMPTY.
    WHEN 5.
      RAISE JOBLOG_NAME_MISSING.
    WHEN 6.
      RAISE JOBNAME_MISSING.
    WHEN 7.
      RAISE JOB_DOES_NOT_EXIST.
  ENDCASE.
*  Find out how many lines there are, and check how many lines are
*      requested by the caller.
  DESCRIBE TABLE JOBLOGTBL LINES TOTALROWS.
  IF MAXROWS <= 0.
    ROWCOUNT = TOTALROWS.
  ELSEIF STARTROW < 1 OR STARTROW > TOTALROWS.
    RAISE STARTROW_SNAFU.
  ELSE.
    POSSIBLE = STARTROW + MAXROWS - 1.
    IF TOTALROWS > POSSIBLE.
      STOPROW = POSSIBLE.
    ELSE.
      STOPROW = TOTALROWS.
    ENDIF.
*  Transfer the text of the requested message lines into JOBLOGTEXT.
    REFRESH JOBLOGTEXT.
    LOOP AT JOBLOGTBL FROM STARTROW TO STOPROW.
      MOVE-CORRESPONDING JOBLOGTBL TO JOBLOGTEXT.
      APPEND JOBLOGTEXT.
    ENDLOOP.
    ROWCOUNT = STOPROW - STARTROW + 1.
  ENDIF.
*
ENDFUNCTION.
