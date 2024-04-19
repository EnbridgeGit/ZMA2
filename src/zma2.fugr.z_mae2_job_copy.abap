FUNCTION Z_MAE2_JOB_COPY.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(INIT_STEP) LIKE  YMAEVARIAN-STEP_NUM
*"             VALUE(SOURCE_JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT
*"             VALUE(SOURCE_JOBNAME) LIKE  TBTCJOB-JOBNAME
*"             VALUE(TARGET_JOBCOUNT) LIKE  TBTCJOB-JOBCOUNT
*"       TABLES
*"              STEP_VARIANT STRUCTURE  YMAEVARIAN
*"       EXCEPTIONS
*"              BAD_PRIPARAMS
*"              BAD_XPGFLAGS
*"              INVALID_INITIAL_STEP
*"              INVALID_JOBDATA
*"              INVALID_STEP_NUMBER
*"              JOBNAME_MISSING
*"              JOB_NOTEX
*"              JOB_SUBMIT_FAILED
*"              LAST_STEP_0
*"              LOCK_FAILED
*"              PROGRAM_MISSING
*"              PROG_ABAP_AND_EXTPG_SET
*"----------------------------------------------------------------------
*
*  Generic routine to copy a job from a given step number. If the
*  Step number = 1 then the whole job gets copied. This routine also
*  adds to each step the new variant passed during runtime from maestro.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1995 by iXOS Software, All Rights Reserved.
*
*  History:
*     Coded   6/4/96    Ravi Ramaswamy   initial coding
*
*
  DATA LAST_STEP LIKE TBTCP-STEPCOUNT.
  DATA INITIAL_STEP LIKE TBTCP-STEPCOUNT.
  DATA: BEGIN OF STEP_PRINT_PARAMS.
        INCLUDE STRUCTURE PRI_PARAMS.
  DATA: END OF STEP_PRINT_PARAMS.

  DATA: BEGIN OF STEP_ARC_PARAMS.
        INCLUDE STRUCTURE ARC_PARAMS.
  DATA: END OF STEP_ARC_PARAMS.

  DATA: BEGIN OF ALL_STEPS OCCURS 100.
        INCLUDE STRUCTURE TBTCP.
  DATA: END OF ALL_STEPS.

  DATA: BEGIN OF Z_JOBSELECT_JOBLIST OCCURS 100.
        INCLUDE STRUCTURE TBTCJOB.
  DATA: END OF Z_JOBSELECT_JOBLIST.

  DATA: BEGIN OF CORR_STEP_VARIANT OCCURS 100,
        STEP_NUM LIKE TBTCP-STEPCOUNT,
        OPTIONS LIKE TBTCP-VARIANT,
        END OF CORR_STEP_VARIANT.
  DATA: TARGETHOST LIKE TBTCJOB-BTCSYSREAX.
  DATA: JOB_WAS_RELEASED LIKE BTCH0000-CHAR1.

  MOVE INIT_STEP TO INITIAL_STEP.
* count the number of steps in the existing job and check
* if the input parameter step_number is valid.
   SELECT COUNT(*) FROM  TBTCP INTO LAST_STEP
      WHERE JOBCOUNT = SOURCE_JOBCOUNT.
  IF SY-DBCNT <= 0.
     RAISE LAST_STEP_0.
  ENDIF.
 IF LAST_STEP <= 0.
    RAISE LAST_STEP_0.
 ENDIF.
 IF ( INITIAL_STEP  > LAST_STEP ) OR ( INITIAL_STEP <= 0 ).
    RAISE INVALID_INITIAL_STEP.
 ENDIF.

* Copy tbtcp into internal table all_steps
   SELECT * FROM TBTCP INTO TABLE ALL_STEPS
        WHERE JOBNAME = SOURCE_JOBNAME
        AND JOBCOUNT = SOURCE_JOBCOUNT
        AND STEPCOUNT >= INITIAL_STEP.

* Copy the run-time variant passed through table step_variant
* into table all_steps.
   LOOP AT STEP_VARIANT.
      MOVE-CORRESPONDING STEP_VARIANT TO CORR_STEP_VARIANT.
      APPEND CORR_STEP_VARIANT.
   ENDLOOP.

* If it is a variant dump it into abap variant slot.
* Else if it is parameters for external program put that in the right
* place.

   LOOP AT CORR_STEP_VARIANT.
      LOOP AT ALL_STEPS WHERE
          STEPCOUNT = CORR_STEP_VARIANT-STEP_NUM.
          IF ALL_STEPS-XPGFLAG = 'X'.
             MOVE CORR_STEP_VARIANT-OPTIONS TO ALL_STEPS-XPGPARAMS.
          ELSE.
             MOVE CORR_STEP_VARIANT-OPTIONS TO ALL_STEPS-VARIANT.
          ENDIF.
          MODIFY ALL_STEPS.
      ENDLOOP.
      IF SY-SUBRC <> 0.
          RAISE INVALID_STEP_NUMBER.
      ENDIF.
   ENDLOOP.

* Fill up the structure for print parameters and archive parameters
* call job_submit for each step in the all_steps table
   LOOP AT ALL_STEPS.
     MOVE-CORRESPONDING ALL_STEPS TO STEP_PRINT_PARAMS.
     MOVE-CORRESPONDING ALL_STEPS TO STEP_ARC_PARAMS.
     IF ALL_STEPS-TRACECNTL = '3'.
        ALL_STEPS-TRACECNTL = 'X'.
     ELSE.
        ALL_STEPS-TRACECNTL = ' '.
     ENDIF.
     IF ALL_STEPS-STDERRCNTL = 'N'.
       ALL_STEPS-STDERRCNTL = ' '.
     ELSE.
       ALL_STEPS-STDERRCNTL = 'X'.
     ENDIF.
     IF ALL_STEPS-STDOUTCNTL = 'N'.
       ALL_STEPS-STDOUTCNTL = ' '.
     ELSE.
       ALL_STEPS-STDOUTCNTL = 'X'.
     ENDIF.
     IF ALL_STEPS-TERMCNTL = 'W'.
       ALL_STEPS-TERMCNTL = ' '.
     ELSE.
       ALL_STEPS-TERMCNTL = 'X'.
     ENDIF.

           CALL FUNCTION 'JOB_SUBMIT'
                EXPORTING
                     ARCPARAMS                   =
                        STEP_ARC_PARAMS
                     AUTHCKNAM                   =
                        ALL_STEPS-AUTHCKNAM
                     EXTPGM_NAME                 =
                        ALL_STEPS-XPGPROG
                     EXTPGM_PARAM                =
                        ALL_STEPS-XPGPARAMS
                     EXTPGM_SET_TRACE_ON         = ALL_STEPS-TRACECNTL
                     EXTPGM_STDERR_IN_JOBLOG     = ALL_STEPS-STDERRCNTL
                     EXTPGM_STDOUT_IN_JOBLOG     = ALL_STEPS-STDOUTCNTL
                     EXTPGM_SYSTEM               = ALL_STEPS-XPGTGTSYS
                     EXTPGM_WAIT_FOR_TERMINATION = ALL_STEPS-TERMCNTL
                     JOBCOUNT                    = TARGET_JOBCOUNT
                     JOBNAME                     = SOURCE_JOBNAME
                     LANGUAGE                    = ALL_STEPS-LANGUAGE
                     PRIPARAMS                   =
                        STEP_PRINT_PARAMS
                     REPORT                      = ALL_STEPS-PROGNAME
                     VARIANT                     = ALL_STEPS-VARIANT
                EXCEPTIONS
                     BAD_PRIPARAMS               = 01
                     BAD_XPGFLAGS                = 02
                     INVALID_JOBDATA             = 03
                     JOBNAME_MISSING             = 04
                     JOB_NOTEX                   = 05
                     JOB_SUBMIT_FAILED           = 06
                     LOCK_FAILED                 = 07
                     PROGRAM_MISSING             = 08
                     PROG_ABAP_AND_EXTPG_SET     = 09.
           IF SY-SUBRC <> 0.
               CASE SY-SUBRC.
                     WHEN 1.
                        RAISE BAD_PRIPARAMS.
                     WHEN 2.
                        RAISE BAD_XPGFLAGS.
                     WHEN 3.
                        RAISE INVALID_JOBDATA.
                     WHEN 4.
                        RAISE JOBNAME_MISSING.
                     WHEN 5.
                        RAISE JOB_NOTEX.
                     WHEN 6.
                        RAISE JOB_SUBMIT_FAILED.
                     WHEN 7.
                        RAISE LOCK_FAILED.
                     WHEN 8.
                        RAISE PROGRAM_MISSING.
                     WHEN 9.
                        RAISE PROG_ABAP_AND_EXTPG_SET.
                ENDCASE.
           ENDIF.
   ENDLOOP.

* Try to close the job with the target host filled in ...
SELECT * FROM TBTCO INTO TABLE Z_JOBSELECT_JOBLIST
    WHERE JOBNAME = SOURCE_JOBNAME
    AND JOBCOUNT  = SOURCE_JOBCOUNT.

LOOP AT Z_JOBSELECT_JOBLIST.
    IF Z_JOBSELECT_JOBLIST-JOBCOUNT EQ SOURCE_JOBCOUNT.
      MOVE Z_JOBSELECT_JOBLIST-BTCSYSTEM TO TARGETHOST.
    ENDIF.
ENDLOOP.

CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
        JOBCOUNT     = TARGET_JOBCOUNT
        JOBNAME      = SOURCE_JOBNAME
        TARGETSYSTEM = TARGETHOST
    IMPORTING
        JOB_WAS_RELEASED = JOB_WAS_RELEASED
    EXCEPTIONS
        CANT_START_IMMEDIATE    = 01
        INVALID_STARTDATE       = 02
        JOBNAME_MISSING         = 03
        JOB_CLOSE_FAILED        = 04
        JOB_NOSTEPS             = 05
        JOB_NOTEX               = 06
        LOCK_FAILED             = 07.
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

ENDFUNCTION.
