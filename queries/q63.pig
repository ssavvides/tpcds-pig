IMPORT 'tablesPlaintext.pig';
%default output_path '/tpcds/output'
RMF $output_path/Q63

C = customer();
CA = customer_address();
CD = customer_demographics();
D = date_dim();
HD = household_demographics();
I = item();
P = promotion();
S = stores();
SS = store_sales();

FD = FILTER D BY ((chararray) d_month_seq) MATCHES '1219|1220|1221|1222|1223|1224|1225|1226|1227|1228|1229|1230';
FI = FILTER I BY
	(
	i_category MATCHES 'Books|Children|Electronics' AND
	i_class MATCHES 'personal|portable|reference|self-help' AND
	i_brand MATCHES 'scholaramalgamalg #14|scholaramalgamalg #7|exportiunivamalg #9|scholaramalgamalg #9'
	) OR
	(
	i_category MATCHES 'Women|Music|Men' AND
	i_class MATCHES 'accessories|classical|fragrances|pants' AND
	i_brand MATCHES 'amalgimporto #1|edu packscholar #1|exportiimporto #1|importoamalg #1'
	);
FSS = FILTER SS BY ss_sold_date_sk >= 2452123 AND ss_sold_date_sk <= 2452487;

J1 = JOIN FSS BY ss_sold_date_sk, FD BY d_date_sk;
J2 = JOIN J1 BY ss_item_sk, FI BY i_item_sk;
J3 = JOIN J2 BY ss_store_sk, S BY s_store_sk;

-- windowing
GW = GROUP J3 BY i_manager_id;
FW = FOREACH GW GENERATE
	group AS manager_id,
	SUM(J3.ss_sales_price) AS monthly_sales;

JFW = JOIN FW BY manager_id, J3 BY i_manager_id;

G1 = GROUP JFW BY (i_manager_id, d_moy);

F1 = FOREACH G1 GENERATE
	group.i_manager_id,
	SUM(JFW.ss_sales_price) AS sum_sales,
	AVG(JFW.monthly_sales) AS avg_monthly_sales;

FF1 = FILTER F1 BY
	avg_monthly_sales > 0 AND
	(ABS(sum_sales - avg_monthly_sales) / avg_monthly_sales)*10 > 1;

O1 = ORDER FF1 BY
	i_manager_id,
    avg_monthly_sales,
    sum_sales;

L1 = LIMIT O1 100;

STORE L1 INTO '$output_path/Q63' USING PigStorage('|');

