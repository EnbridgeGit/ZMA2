FUNCTION Z_MAE2_DATE_TIME.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       EXPORTING
*"             VALUE(CURRENTDATE) LIKE  TBTCP-JOBCOUNT
*"             VALUE(CURRENTTIME) LIKE  TBTCP-PRDSN
*"----------------------------------------------------------------------
*
*  Interface routine for Maestro to obtain the current date and time
*  from R/3.  This is used for getting a timestamp that is based on
*  the time/date setting on the R/3 system, which may be different
*  from the time/date setting on the machine we're calling R/3 from.
*
*  This code is the proprietary property of iXOS Software.
*  Copyright (c) 1996 by iXOS Software, All Rights Reserved
*
*  History:
*     Coded 10/22/96 Chadwick  Initial coding
*
MOVE SY-DATUM TO CURRENTDATE.
MOVE SY-UZEIT TO CURRENTTIME.
*
ENDFUNCTION.
