proc import datafile= "/folders/myfolders/Resend Graded Assignment/Loandetails.xlsx"
out=loan_details1 dbms=xlsx replace; sheet="36 months";
run;

proc import datafile= "/folders/myfolders/Resend Graded Assignment/Loandetails.xlsx"
out=loan_details2 dbms=xlsx replace; sheet="60 months";
run;

proc import datafile= "/folders/myfolders/Resend Graded Assignment/Loandetails.xlsx"
out=loan_details3 dbms=xlsx replace; sheet="demo";
run;

proc import datafile= "/folders/myfolders/Resend Graded Assignment/US Population by State.csv"
out=us_pop dbms=csv replace;
run;

data population;
set work.loan_details1 work.loan_details2 ;
run;

proc sort data= population;
by id;
run;

/*----------------------------------------------------------------------------------------------*/
 

/*
What is the total default rate of the existing loans in this dataset? Pls specify to 2 decimal places 
(Hint: Use the loan_status variable. Values of this variable that should be considered as “default” are: “Default” and “Late (31-120 days)”
Hint : Calculate the number of customers who are in default based on the "total" sample overall
 */

data default;
set population;
run;
proc contents data=default;
run;
proc freq data=default;
table loan_status / out= test_default;
where loan_status="Default "or loan_status="Late (31-120 days)";
run;
/*
proc sql;
  create table total_default as
  select loan_status,
         sum(count) as count
  from  test_default 

where loan_status="Default "or loan_status="Late (31-120 days)" group by loan_status;
quit;
*/
proc  means  data= work.test_default;
output out= final_default 
sum(count)= data_default;
run;

/*--------------------------------------------------------------------------------------------*/

/*-In order to understand the mean and the median for the “funded_amnt” variable, what would be the right syntax
for a proc means statement? Please add all code here as necessary. Please make sure that only
mean and median for only the specified variable are generated in the output window.-*/

data null;
set work.population;
run;

proc sort data= null;
by loan_status;
run;

proc means data= null mean median;
var funded_amnt;
by loan_status;
where loan_status="Default" or loan_status="Late (31-120 days)" ;
run;

/*---------------------------------------------------------------------------------------------*/
/*-What is the difference in default rate between loans of 3 year tenure and 5 years tenure?

Hint:
You will need to create a variable for loan tenure in the original datasets after import 
Please use loan_status values of “Default”, “Late (31-120 days)”. 

The base for calculating default rate for each type should be the complete loan portfolio consisting of all types of loans and tenures

The default rate for loans of 3 year tenure is_____10.71________  
The default rate for loans of 5 year tenure is_____7.48________  
-*/
proc sort data=work.loan_details3;
by id;
run;


data tenure;
merge work.population work.loan_details3;
by id;
run;
data rate_of_tenure;
set work.tenure;
length tenure $10.;
if emp_length="3 years" then tenure="3 years";
else if emp_length="5 years" then tenure="5 years";
else tenure="Non years";
run;
proc sort data= work.rate_of_tenure;
by id;
run;
proc freq data= rate_of_tenure;
table tenure;
run;

/*------------------------------------------------------------------------------------------*/
/*-4. You notice that people don’t always receive the loan amount that they request – the funded
 amount is lower than the loan amount usually. You want to understand if the ratio of funded 
 amount to loan amount differs by purpose. Please create a table that lists the grant proportion
 (funded amount divided by loan amount) by purpose (use the purpose variable). Please enter the 
 appropriate values in this table below:

Please round off grant rate to 2 decimals. In order to do so, you should use thmaxe
 “maxdec” option
 in the means procedure (See link to a useful article on proc means
 options: http://www2.sas.com/proceedings/sugi29/240-29.pdf)-*/

data maxdec;
set tenure;
funded_ratio=funded_amnt/Loan_amnt;
run;
proc sort data= maxdec;
by purpose;
run;
proc means data=work.maxdec mean maxdec=2;
by purpose;
output out= purpose_maxdec
mean(funded_ratio)=finalratio;
where purpose="educational" or purpose="debt_consolidation" or purpose="major_purchase";
run; 
/*- Answer
1	debt_consolidation	0.9841654188
2	educational	    	0.9906386488
3	major_purchase		0.9905911254-*/

/*-------------------------------------------------------------------------------------------*/


/*-As part of the exploratory data analysis, you may want to understand if the data you have is
 somewhat representative geographically across the US. One way is to compare the distribution of
 funded amounts by state, and compare that to the US population by state. In other words, you
 can create an index of the ratio of each state’s share of funded amount to population share of
 the state.

Create an index of the funded share to population share, and identify how many states have a
 ratio of greater than 1. Also identify which state has the maximum ratio.
 
Hint: There are multiple steps you will need to follow
a. Use the US State population by State file provided. Import the file and create a variable
 which is the ratio of each state’s population to total US population. You will need to sum up
 population across states, and merge back to the original file to create this ratio. Name the
 ratio variable “popshare”
b. Next step is to create a variable that has the ratio of total funded-amnt by state divided 
 by total funded_amnt across all observations. You will need to aggregate and merge. Name the
 ratio variable “loanshare”.
c. Final step is to put both of these share variables by state in one dataset, and divide 
 loanshare by popshare. This is the final ratio
d. Based on this final ratio, answer these two questions:

How many states have ratios of > 1 -*/

data us_state (rename=(_2013=State_pop));
set work.us_pop;
run;

data semi_master (rename=(addr_state=States));
set work.tenure;
run;

proc sort data= us_state;
by States;
run;
proc sort data= semi_master;
by States;
run;

/*-a. Use the US State population by State file provided. Import the file and create a variable
 which is the ratio of each state’s population to total US population. You will need to sum up
 population across states, and merge back to the original file to create this ratio. Name the
 ratio variable “popshare”*-*/
data master;
merge work.us_state work.semi_master;
by States;
run;

proc means data= master sum;
var state_pop;
by states;
output out= master1
sum (state_pop)=total_pop ;
run;

data total_state;
merge  work.master1 work.us_state;
by states;
popshare=state_pop/total_pop;
run;

/*-b. Next step is to create a variable that has the ratio of total funded-amnt by state divided 
 by total funded_amnt across all observations. You will need to aggregate and merge. Name the
 ratio variable “loanshare”.-*/

proc means data= master sum;
var funded_amnt;
by states;
output out= funds
sum (funded_amnt)=total_fund ;
run;

proc means data=master sum;
output out= allfunds
sum (funded_amnt)=fund;
run;

data fund1;
set work.funds;
common=1;
run;

data fund2;
set work.allfunds;
common=1;
run;

data total_funds;
merge work.fund1 work.fund2;
by common;
loanshare=total_fund/fund;
run;

/*- c. Final step is to put both of these share variables by state in one dataset, and divide 
 loanshare by popshare. This is the final ratio-*/

data total_share;
merge work.total_funds work.total_state;
by states;
final_ratio= loanshare/popshare;
run;

/*-How many states have ratios of > 1 -*/


proc sql;
  create table countstates as
  select final_ratio,
         count(final_ratio) as count
  from  total_share 

where final_ratio > 1 group by final_ratio;
quit;

proc sort data= work.countstates;
by final_ratio;
run;

proc means data=work.countstates;
output out= count_states
sum(count)= count;
run;

/*- Answer is 25 -*/

/*-Which state has the highest ratio? -*/
proc sort data=total_share;
by descending final_ratio;
run;
/*-Answer is CA (california)-*/

/*-In order to produce the following output, what else do you need to include in the statement below?
Output:

Proc freq data = master;

Tables term * def ____________ ;

run;                                                                   

(Hint – make sure you put in exact syntax, along with semi colons where required )

	-*/
	
	
	
data output1;
set tenure;
if emp_length="3 years" then def=1;
else def = 0;
run;

data output2;
set tenure;
if emp_length="5 years" then def=1;
else def = 0;
run;

proc sort data=output1;
by id;
run;


proc sort data=output2;
by id;
run;

data finaloutput;
merge work.output1 work.output2;
by id;
run;

proc freq data=finaloutput;
tables emp_length* def/ nocol norow;
where emp_length="3 years" or emp_length="5 years";
run;

/*-
proc sort data= output1;
by def;
run;
proc means data= output1 sum;
output out= delta sum(def)= delta1;
by def;
run;
-*/

/*--------------------------------------------------------------------------------------------*/



