/*
程序：零件回冲报表
作者：Boywizard
日期：2016.3.24
版本：1.0
说明：统计成品回冲及消耗零件数量。
 */

{mfdtitle.i "1+"}

define variable site like tr_site no-undo.
define variable site1 like tr_site no-undo.
define variable part like tr_part no-undo.
define variable part1 like tr_part no-undo.
define variable effdate like tr_effdate no-undo.
define variable effdate1 like tr_effdate no-undo.

define temp-table xrct_wo
    field xrct_part like tr_part
    field xrct_site like tr_site
    field xrct_id like tr_lot
    field xrct_qty_chg like tr_qty_chg
    field xrct_qty_loc like tr_qty_loc
index idx_rct_part xrct_part xrct_id.

define temp-table xiss_wo
    field xiss_part like tr_part
    field xiss_site like tr_site
    field xiss_id like tr_lot
    field xiss_qty_chg like tr_qty_chg
    field xiss_qty_loc like tr_qty_loc
index idx_iss_part xiss_part xiss_id.

define temp-table rpt_total
    field rpt_site like tr_site
    field rpt_lot like tr_lot
    field rpt_rct_part like tr_part
    field rpt_rct_desc like pt_desc1
    field rpt_rct_qty_chg like tr_qty_chg
    field rpt_rct_qty_loc like tr_qty_loc
    field rpt_iss_part like tr_part
    field rpt_iss_desc like pt_desc1
    field rpt_iss_qty_chg like tr_qty_chg
    field rpt_iss_qty_loc like tr_qty_loc
index idx_rpt_rct_part rpt_rct_part rpt_lot
index idx_rpt_iss_part rpt_iss_part.

form
    part           colon 15
    part1          label "To" colon 49 skip
    site           colon 15
    site1          label "To" colon 49 skip
    effdate        colon 15
    effdate1       label "To" colon 49 skip
with frame a side-labels width 80.

/* SET EXTERNAL LABELS */
setFrameLabels(frame a:handle).

/* REPORT BLOCK */
{wbrp01.i}

repeat:

    if part1 = hi_char then part1 = "".
    if site1 = hi_char then site1 = "".
    if effdate = hi_date then effdate = ?.
    if effdate1 = low_date then effdate1 = ?.

    if c-application-mode <> 'web' then
        update part part1 site site1 effdate effdate1 with frame a.

    {wbrp06.i &command = update
        &fields = "part part1 site site1 effdate effdate1" &frm = "a"}

    if (c-application-mode <> 'web') or
        (c-application-mode = 'web' and
        (c-web-request begins 'data')) then 
        do:
	        bcdparm = "".
	        {mfquoter.i part        }
	        {mfquoter.i part1       }
	        {mfquoter.i site        }
	        {mfquoter.i site1       }
	        {mfquoter.i effdate     }
	        {mfquoter.i effdate1    }

	        if part1 = "" then part1 = hi_char.
	        if site1 = "" then site1 = hi_char.
	        if effdate1 = ? then effdate1 = today.
		end.

    /* OUTPUT DESTINATION SELECTION */
    {gpselout.i &printType = "printer"
        &printWidth = 200
        &pagedFlag = " "
        &stream = " "
        &appendToFile = " "
        &streamedOutputToTerminal = " "
        &withBatchOption = "yes"
        &displayStatementType = 1
        &withCancelMessage = "yes"
        &pageBottomMargin = 6
        &withEmail = "yes"
        &withWinprint = "yes"
        &defineVariables = "yes"
    }

    {mfphead.i}
              for each tr_hist no-lock
                  where tr_domain = global_domain and tr_site >= site
                  and tr_site <= site1
                  and tr_part >= part and tr_part <= part1
                  and tr_effdate >= effdate and tr_effdate <= effdate1
                  and (tr_type = "RCT-WO" OR tr_type = "ISS-WO")
              use-index tr_part_eff:
                  do:
                      if tr_type = "RCT-WO" then
                          do:
                            find first xrct_wo no-lock
                              where xrct_part = tr_part
                              and xrct_id = tr_lot use-index idx_rct_part no-error.
                            if available xrct_wo then
                              do:
                                xrct_qty_chg = xrct_qty_chg + tr_qty_chg.
                                xrct_qty_loc = xrct_qty_loc + tr_qty_loc.
                              end.
                            else
                              do:
                                create xrct_wo.
                                assign xrct_site = tr_site.
                                assign xrct_part = tr_part.
                                assign xrct_id = tr_lot.
                                assign xrct_qty_chg = tr_qty_chg.
                                assign xrct_qty_loc = tr_qty_loc.
                              end.
                          end.
                      if tr_type = "ISS-WO" then
                          do:
                            find first xiss_wo no-lock
                              where xiss_part = tr_part
                              and xiss_id = tr_lot use-index idx_iss_part no-error.
                            if available xiss_wo then
                              do:
                                xiss_qty_chg = xiss_qty_chg + tr_qty_chg.
                                xiss_qty_loc = xiss_qty_loc + tr_qty_loc.
                              end.
                            else
                              do:
                                create xiss_wo.
                                assign xiss_site = tr_site.
                                assign xiss_part = tr_part.
                                assign xiss_id = tr_lot.
                                assign xiss_qty_chg = tr_qty_chg.
                                assign xiss_qty_loc = tr_qty_loc.
                              end.
                          end.
                  end.
              end.

              for each xrct_wo no-lock use-index idx_rct_part:
                do:
                  for each xiss_wo no-lock
                    where xrct_id = xiss_id:
                      do:
                        create rpt_total.
                        assign rpt_site = xrct_site.
                        assign rpt_rct_part = xrct_part.
                        assign rpt_lot = xrct_id.
                        assign rpt_rct_qty_loc = xrct_qty_loc.
                        assign rpt_rct_qty_chg = xrct_qty_chg.
                        assign rpt_iss_part = xiss_part.
                        assign rpt_iss_qty_loc = xiss_qty_loc.
                        assign rpt_iss_qty_chg = xiss_qty_chg.
                      end.
                  end.
                end.
              end.
              /*for each */

              for each rpt_total no-lock.
                find first pt_mstr where pt_part = rpt_rct_part  no-error.
                if available pt_mstr then rpt_rct_desc = pt_desc1.
                find first pt_mstr where pt_part = rpt_iss_part no-error.
                if available pt_mstr then rpt_iss_desc = pt_desc1.
                display rpt_total with frame b width 200 down.
              end.
	/* REPORT TRAILER  */
	{mfrtrail.i}
end. /* end repeat */
{wbrp04.i &frame-spec = a}