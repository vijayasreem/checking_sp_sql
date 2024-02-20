create or replace PROCEDURE claim_payout_approve (
    payoutnumber        IN VARCHAR2,
    intimation_number   IN VARCHAR2,
    productcode         IN VARCHAR2,
    variantcode         IN VARCHAR2,
    gstrate             IN NUMBER,
    cgstamount          IN NUMBER,
    cgstrate            IN NUMBER,
    igstamount          IN NUMBER,
    igstrate            IN NUMBER,
    sgstamount          IN NUMBER,
    sgstrate            IN NUMBER,
    utgstamount         IN NUMBER,
    utgstrate           IN NUMBER,
    drsraccn            IN NUMBER,
    crsraccn            IN NUMBER,
    togstin             IN VARCHAR2,
    fromgstn            IN VARCHAR2,
    hsncode             IN VARCHAR2,
    frompan             IN VARCHAR2,
    topan               IN VARCHAR2,
    natureoftransaction IN VARCHAR2,
    fromstatecode       IN VARCHAR2,
    tostatecode         IN VARCHAR2,
    mphaddress          IN VARCHAR2,
    productvariant      IN VARCHAR2,
    product             IN VARCHAR2,
    amountwithtax       IN VARCHAR2,
    amountwithouttax    IN VARCHAR2,
    entrytype           IN VARCHAR2,
    createdby           IN VARCHAR2,
    senderlei           IN VARCHAR2
) IS

    da            licaccounting.pkg_gratuity_approval.gr_inp_data;
    CURSOR c1 IS
    SELECT 
        licaccounting.gr_inp_obj(accountrulecontext, refno, effectivedateofpayment, payoutsourcemodule, beneficiarypaymentid,
                                 productcode, variantcode, totalamount, operatingunit, operatingunittype,
                                 paymentmode, policyno, lob, product, mphcode,
                                 productvariant, icodeforlob, icodeforproductline, icodeforvarient, icodeforbusinesstype,
                                 icodeforparticipatingtype, icodeforbusinesssegment, icodeforinvestmentportfolio, beneficiary_name, beneficiary_bank_name
                                 ,
                                 beneficiary_branch_ifsc, beneficiary_branch_name, beneficiary_account_type, beneficiary_account_number
                                 , beneficiarylei,
                                 senderlei, unitcode, membernumber, paymentcategory, paymentsubcategory,
                                 nroaccount, iban, remarks, paymentamount, gstliabiltyamount,
                                 isgstapplicable, transactiontype, transaction_sub_type, gstrefno, gst_ref_transaction_no,
                                 gst_transaction_type, amount_with_tax, amount_without_tax, cess_amount, total_gst_amount,
                                 gst_rate, cgst_amount, cgst_rate, igst_amount, igst_rate,
                                 sgst_amount, sgst_rate, utgst_amount, utgst_rate, gst_applicable_type,
                                 gst_type, collection_id, to_gstin, from_gstn, hsn_code,
                                 from_pan, to_pan, nature_of_transaction, mph_name, mph_address,
                                 entry_type, gstremarks, old_invoice_date, from_state_code, to_state_code,
                                 created_by, dr_sr_accn, cr_sr_accn, ismultiplebeneficiary)
    FROM
        (
            WITH beneficiaries AS (
                SELECT distinct
                    ptcb.claim_beneficiary_id,
                    ptcb.mph_tmp_bank_id AS tmp_bank_id,
                    ptmb.mph_bank_id     AS tmp_bank_id1,
                    ptm.mph_name         AS beneficiary_name,
                    ptmb.bank_name,
                    ptmb.account_number  AS bank_account_number,
                    ptmb.account_type,
                    ptmb.bank_branch,
                    ptmb.ifsc_code,
                    ptm.mph_lei,
                    100                  AS percentage
                FROM
                         pmst_tmp_claim_beneficiary ptcb
                    JOIN pmst_tmp_claim_props ptcp ON ptcb.claim_props_id = ptcp.claim_props_id
                    LEFT JOIN pmst_tmp_mph_bank    ptmb ON ptmb.mph_bank_id = ptcb.mph_tmp_bank_id
                    JOIN pmst_tmp_mph         ptm ON ptm.mph_id = ptmb.mph_id
                WHERE
                    ptcp.intimation_number = intimation_number
                UNION ALL
                SELECT
                    ptcb.claim_beneficiary_id,
                    ptcb.member_tmp_bank_id      AS tmp_bank_id,
                    ptmba.member_bank_account_id AS tmp_bank_id1,
                    ptm2.first_name              AS beneficiary_name,
                    ptmba.bank_name,
                    ptmba.bank_account_number    AS bank_account_number,
                    ptmba.account_type,
                    ptmba.bank_branch,
                    ptmba.ifsc_code,
                    NULL                         AS mph_lei,
                    100                          AS percentage
                FROM
                         pmst_tmp_claim_beneficiary ptcb
                    JOIN pmst_tmp_claim_props         ptcp ON ptcb.claim_props_id = ptcp.claim_props_id
                    LEFT JOIN pmst_tmp_member_bank_account ptmba ON ptmba.member_bank_account_id = ptcb.member_tmp_bank_id
                    JOIN pmst_tmp_member              ptm2 ON ptm2.member_id = ptmba.member_id
                WHERE
                    ptcp.intimation_number = intimation_number
                UNION ALL
                SELECT
                    ptcb.claim_beneficiary_id,
                    ptcb.nominee_tmp_bank_id AS tmp_bank_id,
                    ptcb.nominee_tmp_bank_id AS tmp_bank_id1,
                    ptmn.nominee_name        AS beneficiary_name,
                    ptmn.bank_name,
                    ptmn.bank_account_number AS bank_account_number,
                    ptmn.account_type,
                    ptmn.bank_branch,
                    ptmn.ifsc_code,
                    NULL                     AS mph_lei,
                    ptmn.percentage          AS percentage
                FROM
                         pmst_tmp_claim_beneficiary ptcb
                    JOIN pmst_tmp_claim_props    ptcp ON ptcb.claim_props_id = ptcp.claim_props_id
                    LEFT JOIN pmst_tmp_member_nominee ptmn ON ptmn.member_nominee_id = ptcb.nominee_tmp_bank_id
                WHERE
                    ptcp.intimation_number = intimation_number
            )
            SELECT DISTINCT
                CASE ptcp.mode_of_exit
                    WHEN 193 THEN
                        'Gratuity Death Claim Payment Approval'
                    WHEN 194 THEN
                        'Gratuity Maturity/Retirement Claim Payment Approval'
                    WHEN 195 THEN
                        'Gratuity Withdrawal Claim Payment Approval'
                    ELSE
                        NULL
                END                                       AS accountrulecontext,
                ptcp.intimation_number                    AS refno,
                TO_char(sysdate, 'DD-MM-YYYY')            AS effectivedateofpayment,
                'GRATCLAIMAPPROVE'                        payoutsourcemodule,
                to_char(ptcb.claim_beneficiary_id)        beneficiarypaymentid,
                productcode                               productcode,
                variantcode                               variantcode,
                round( round(coalesce(ptcp.modified_gratuity_amount, ptcp.gratuity_amt_on_date_of_exit) + coalesce(ptcp.refund_premium_amount
                , 0) + coalesce(ptcp.lc_sum_assured, 0) + coalesce(ptcp.penal_amount, 0) + coalesce(ptcp.court_award, 0),
                        0)* ( ben.percentage / 100 )  )                                      totalamount,
                ptp.unit_code                             operatingunit,
                'UO'                                      operatingunittype,
                'N'                                       paymentmode,
                TO_NUMBER(ptp.policy_number)              policyno,
                ptp.line_of_business                      lob,
                product                                   product,
                ptm.mph_code                              mphcode,
                productvariant                            productvariant,
                gi.icode_business_line                    icodeforlob,
                gi.icode_product_line                     icodeforproductline,
                TO_NUMBER(gi.icode_varient)               icodeforvarient,
                gi.icode_business_type                    icodeforbusinesstype,
                gi.icode_participating_type               icodeforparticipatingtype,
                gi.icode_business_segment                 icodeforbusinesssegment,
                0                                         icodeforinvestmentportfolio,
                ben.beneficiary_name                      beneficiary_name,
                substr(ben.bank_name, 0, 15)              beneficiary_bank_name,
                ben.ifsc_code                             beneficiary_branch_ifsc,
                ben.bank_branch                           beneficiary_branch_name,
                CASE ben.account_type
                    WHEN '93'      THEN
                        to_char('10')
                    WHEN '95'      THEN
                        to_char('29')
    --                WHEN   '160' THEN TO_CHAR('')
                    WHEN 'Savings' THEN
                        to_char('10') -- Savings
                    WHEN 'Current' THEN
                        to_char('29') --Current
                    ELSE
                        NULL
                END                                       AS beneficiary_account_type,
                to_char(ben.bank_account_number)          beneficiary_account_number,
                ben.mph_lei                               beneficiarylei,
                senderlei                                 senderlei,
                ptp.unit_code                             unitcode,
                to_char(ptm2.employee_code)               membernumber,
                'PCM002'                                  paymentcategory,
                CASE ptcp.mode_of_exit
                    WHEN 193 THEN
                        'DC' --'Gratuity Death Claim Payment Approval'
                    WHEN 194 THEN
                        'O' --'Gratuity Maturity/Retirement Claim Payment Approval'
                    WHEN 195 THEN
                        'O' --'Gratuity Withdrawal Claim Payment Approval'
                    ELSE
                        NULL
                END                                       AS paymentsubcategory,
                ''                                        nroaccount,
                ''                                        iban,
                'GRATUITY CLAIM PROPS ID/CLAIM BENEFICIARY ID ['
                || ptcp.claim_props_id
                || '/'
                || ptcb.claim_beneficiary_id
                || ']'                                    remarks,
               round( round(round(coalesce(ptcp.modified_gratuity_amount, ptcp.gratuity_amt_on_date_of_exit) + coalesce(ptcp.refund_premium_amount
                , 0) + coalesce(ptcp.lc_sum_assured, 0) + coalesce(ptcp.penal_amount, 0) + coalesce(ptcp.court_award, 0),
                            0) + coalesce(ptcp.refund_gst_amount, 0))*(ben.percentage / 100)) paymentamount,
                coalesce(ptcp.refund_gst_amount, 0)       gstliabiltyamount,
                CASE ptp.gst_applicable_id
                    WHEN 1 THEN
                        'YES' -- GST TYPE
                    WHEN 2 THEN
                        'NO' --GST TYPE
                    ELSE
                        NULL
                END                                       AS isgstapplicable,
                'C'                                       transactiontype,
                'A'                                       transaction_sub_type,
                ptp.policy_number                         gstrefno,
                NULL                                      gst_ref_transaction_no,
                'CREDIT'                                  gst_transaction_type,
                amountwithtax                             amount_with_tax,
                amountwithouttax                          amount_without_tax,
                0                                         cess_amount,
                coalesce(ptcp.refund_gst_amount, 0)       total_gst_amount,
                gstrate                                   gst_rate,
                cgstamount                                cgst_amount,
                cgstrate                                  cgst_rate,
                igstamount                                igst_amount,
                igstrate                                  igst_rate,
                sgstamount                                sgst_amount,
                sgstrate                                  sgst_rate,
                utgstamount                               utgst_amount,
                utgstrate                                 utgst_rate,
                CASE ptp.gst_applicable_id
                    WHEN 1 THEN
                        'Taxable' -- GST TYPE
                    WHEN 2 THEN
                        'SEZ with payment' --GST TYPE
                    ELSE
                        NULL
                END                                       AS gst_applicable_type,
                'GST'                                     gst_type,
                0                                         collection_id,
                togstin                                   to_gstin,
                fromgstn                                  from_gstn,
                hsncode                                   hsn_code,
                frompan                                   from_pan,
                topan                                     to_pan,
                natureoftransaction                       nature_of_transaction,
                ptm.mph_name                              mph_name,
                mphaddress                                mph_address,
                entrytype                                 entry_type,
                NULL                                      gstremarks,
                NULL                                      old_invoice_date,
                fromstatecode                             from_state_code,
                tostatecode                               to_state_code,
                createdby                                 created_by,
                coalesce(drsraccn, 0)                     dr_sr_accn,
                coalesce(crsraccn, 0)                     cr_sr_accn,
                'Y'                                       ismultiplebeneficiary
            FROM
                     beneficiaries ben
                JOIN pmst_tmp_claim_beneficiary ptcb ON ptcb.claim_beneficiary_id = ben.claim_beneficiary_id
                JOIN pmst_tmp_claim_props       ptcp ON ptcb.claim_props_id = ptcp.claim_props_id
                JOIN pmst_tmp_policy            ptp ON ptcp.tmp_policy_id = ptp.policy_id
                JOIN pmst_tmp_mph               ptm ON ptp.mph_id = ptm.mph_id
                JOIN pmst_tmp_member            ptm2 ON ptm2.member_id = ptcp.tmp_member_id
                JOIN gratuity_icodes            gi ON ptp.product_id = gi.product_id
                                           AND ptp.product_variant_id = gi.variant_id
            WHERE
                ben.tmp_bank_id IS NOT NULL
                AND ben.tmp_bank_id1 IS NOT NULL
                AND ben.tmp_bank_id1 > 0
                AND ptcp.intimation_number = intimation_number
        )
        where refno=intimation_number;

    var_grobj_out licaccounting.pkg_gratuity_approval.gr_out_data;
    var_num       NUMBER;
BEGIN
    OPEN c1;
    LOOP
        FETCH c1
        BULK COLLECT INTO da;
        var_num := c1%rowcount;
                    -- insert request query

        INSERT INTO log_test VALUES (
            user,
            'Input Loaded...' || var_num,
            sysdate
        );

        COMMIT;
        EXIT WHEN c1%notfound;
    END LOOP;

    CLOSE c1;
     
    licaccounting.pkg_gratuity_approval.proc_grty_claim_payout_approval(da, var_grobj_out);
    dbms_output.put_line('var_grobj_out count after'||var_grobj_out.count);
    dbms_output.put_line('da count'||da.count);
    
--INSERT INTO LOG_TEST VALUES(USER, 'Accounting Approval Processed...', sysdate);
--commit;   
    FOR i IN var_grobj_out.first..var_grobj_out.last LOOP
            --INSERT INTO TABLE VALUES (var_GRobj_out(i).P_OUT_JOURNAL_NO, var_GRobj_out(i).P_OUT_DEBITACCOUNT, ...)
            
                       dbms_output.put_line('P_OUT_JOURNAL_NO '||var_GRobj_out(i).P_OUT_JOURNAL_NO);
            dbms_output.put_line('P_OUT_DEBITACCOUNT '||var_GRobj_out(i).P_OUT_DEBITACCOUNT);
           dbms_output.put_line('P_OUT_CREDITACCOUNT '||var_GRobj_out(i).P_OUT_CREDITACCOUNT);
            dbms_output.put_line('P_OUT_TOTALAMOUNT '||var_GRobj_out(i).P_OUT_TOTALAMOUNT);
           dbms_output.put_line('P_OUT_DEBITICODE '||var_GRobj_out(i).P_OUT_DEBITICODE);
            dbms_output.put_line('P_OUT_CREDITICODE '||var_GRobj_out(i).P_OUT_CREDITICODE);
            dbms_output.put_line('P_OUT_MESSAGE '||var_GRobj_out(i).P_OUT_MESSAGE);
            dbms_output.put_line('P_OUT_STATUS '||var_GRobj_out(i).P_OUT_STATUS);
           dbms_output.put_line('P_OUT_STATUSCODE '||var_GRobj_out(i).P_OUT_STATUSCODE);
            dbms_output.put_line('P_SQLCODE '||var_GRobj_out(i).P_SQLCODE);
          dbms_output.put_line('P_SQLERROR_MESSAGE '||var_GRobj_out(i).P_SQLERROR_MESSAGE);
       dbms_output.put_line('p_beneficiary_payment_id '||var_grobj_out(i).p_beneficiary_payment_id);
        INSERT INTO payout_sp_response (
            claim_props_id,
            payout_number,
            journal_no,
            payout_date,
            debit_account,
            credit_account,
            TOTAL_AMOUNT,
            credit_code,
            debit_code,
            message,
            status,
            statuscode,
            sqlcode,
            sql_error_message,
            beneficiarypaymentid,
            is_active,
            created_by,
            created_date
        ) VALUES (
            NULL,
            payoutnumber,
            var_grobj_out(i).p_out_journal_no,
            TO_DATE(current_date, 'yyyy/mm/dd hh24:mi:ss'),
            var_grobj_out(i).p_out_debitaccount,
            var_grobj_out(i).p_out_creditaccount,            
			da(i).paymentamount,
            var_grobj_out(i).p_out_debiticode,
            var_grobj_out(i).p_out_crediticode,
            var_grobj_out(i).p_out_message,
            var_grobj_out(i).p_out_status,
            var_grobj_out(i).p_out_statuscode,
            var_grobj_out(i).p_sqlcode,
            var_grobj_out(i).p_sqlerror_message,
            var_grobj_out(i).p_beneficiary_payment_id,
            1,
            'maker',
            current_date
        );
--            dbms_output.put_line('P_OUT_JOURNAL_NO '||var_GRobj_out(i).P_OUT_JOURNAL_NO);
--            dbms_output.put_line('P_OUT_DEBITACCOUNT '||var_GRobj_out(i).P_OUT_DEBITACCOUNT);
--            dbms_output.put_line('P_OUT_CREDITACCOUNT '||var_GRobj_out(i).P_OUT_CREDITACCOUNT);
--            dbms_output.put_line('P_OUT_TOTALAMOUNT '||var_GRobj_out(i).P_OUT_TOTALAMOUNT);
--            dbms_output.put_line('P_OUT_DEBITICODE '||var_GRobj_out(i).P_OUT_DEBITICODE);
--            dbms_output.put_line('P_OUT_CREDITICODE '||var_GRobj_out(i).P_OUT_CREDITICODE);
--            dbms_output.put_line('P_OUT_MESSAGE '||var_GRobj_out(i).P_OUT_MESSAGE);
--            dbms_output.put_line('P_OUT_STATUS '||var_GRobj_out(i).P_OUT_STATUS);
--            dbms_output.put_line('P_OUT_STATUSCODE '||var_GRobj_out(i).P_OUT_STATUSCODE);
--            dbms_output.put_line('P_SQLCODE '||var_GRobj_out(i).P_SQLCODE);
--            dbms_output.put_line('P_SQLERROR_MESSAGE '||var_GRobj_out(i).P_SQLERROR_MESSAGE);
    END LOOP;

END claim_payout_approve;