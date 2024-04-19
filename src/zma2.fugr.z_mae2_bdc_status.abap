FUNCTION Z_MAE2_BDC_STATUS.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             VALUE(CLIENT) LIKE  TBTCO-AUTHCKMAN
*"             VALUE(SESSIONNAME) LIKE  APQI-GROUPID DEFAULT SPACE
*"             VALUE(SESSIONQID) LIKE  APQI-QID DEFAULT SPACE
*"       TABLES
*"              SESSIONS STRUCTURE  YMAESESSNS
*"       EXCEPTIONS
*"              CLIENT_MISSING
*"              NAME_AND_QID_MISSING
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to check the status of a BDC session.
*
*  It assumes that either session name or session qid (queue id) will
*  be specified on input, and that client will be specified as well.
*
*  Output is in the SESSIONS table, which has one entry per qualifying
*  BDC session.  When session qid is given only one line is returned,
*  but when a session name is given multiple sessions may be returned.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1996 by iXOS Software, All Rights Reserved
*
*  History:
*     10/17/96 Chadwick  Initial coding
*
  DATA: BEGIN OF Z_SESSION_TABLE OCCURS 100.
          INCLUDE STRUCTURE YMAESESSNS.
  DATA: END OF Z_SESSION_TABLE.

IF CLIENT EQ ' '.
  RAISE CLIENT_MISSING.
ENDIF.
IF SESSIONNAME EQ ' ' AND SESSIONQID EQ ' '.
  RAISE NAME_AND_QID_MISSING.
ENDIF.
*
IF SESSIONNAME NE ' '.
* SELECT GROUPID QID CREDATE CRETIME QSTATE CREATOR FROM APQI
*   INTO TABLE SESSIONS
*   WHERE MANDANT = CLIENT
*     AND GROUPID = SESSIONNAME.
  SELECT * FROM APQI WHERE MANDANT = CLIENT
                       AND GROUPID = SESSIONNAME.
    MOVE-CORRESPONDING APQI TO SESSIONS.
    APPEND SESSIONS.
  ENDSELECT.
ENDIF.
*
IF SESSIONQID NE ' '.
*  SELECT GROUPID QID CREDATE CRETIME QSTATE CREATOR FROM APQI
*    INTO TABLE SESSIONS
*    WHERE MANDANT = CLIENT
*      AND     QID = SESSIONQID.
  SELECT * FROM APQI WHERE MANDANT = CLIENT
                       AND QID = SESSIONQID.
    MOVE-CORRESPONDING APQI TO SESSIONS.
    APPEND SESSIONS.
  ENDSELECT.
ENDIF.
*
ENDFUNCTION.
