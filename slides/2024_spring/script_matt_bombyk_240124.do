
*Filename: "balance test table with esttab.do"
*Author: Matthew Bombyk
*Date: 2/8/2024

*Description:
*Example do-file showing the use of -esttab- to create nicely-formatted
*balance test tables. This particular example uses the "matrix" version of
*esttab, so it requires assembling a Stata matrix in advance, but this 
*is not required in general for esttab. 


********************************************************************************
*Load Dataset and define sample
********************************************************************************

*Set directories
glo root "DIRECTORY"
glo dat_dir "$root/01 Data/Clean Data"
glo out_dir "$root/06 Analysis and Results/02 Balance Tests"
glo out_file_balance_esttab "$out_dir/balance_output_esttab_v3.rtf"

*Load the data
use "DATASET" , clear 
		

********************************************************************************
*Create the matrix with means, diffs, SE's, and p-values
********************************************************************************
	
*Define variables to test
glo balance_vars hh1_total_income hh1_total_expend hh1_landq_avg ///
				hh1_herd_size hh1_num_animals hh1_migrat_num_yr ///
				hh1_migrat_dist_yr hh1_famsize hh1_hh_head_age hh1_educ_head
				
*Loop over all variables
	foreach depvar of global balance_vars {

		*Estimated diffs, SE's, p-vals
		qui areg `depvar' treatment , vce(cluster group_id) absorb(cluster_code) 
		
		mat diff_b = ( nullmat(diff_b), _b[treatment] )
		mat diff_se = ( nullmat(diff_se), _se[treatment] )
		mat pvals = ( nullmat(pvals), 2*ttail(e(df_r),abs(_b[treatment]/_se[treatment])) )
		
		*Now get the treatment and control means. Need to do var-by-var since 
		* some have missing values 
		mean `depvar' if treatment==0
		mat cmean = ( nullmat(cmean), e(b) )
		mean `depvar' if treatment==1
		mat tmean = ( nullmat(tmean), e(b) )

	}

*Assemble the matrix
mat bal_tab = cmean \ tmean \ diff_b \ diff_se \ pvals
mat colnames bal_tab = $balance_vars 
mat rownames bal_tab = cmean  tmean  diff_b  diff_se  pvals


********************************************************************************
*Export the results in a nice format
********************************************************************************

#delimit ;

esttab 	matrix(bal_tab, transpose fmt( "%10.0fc %10.0fc a2" 
										"%10.0fc %10.0fc a2"
										"%10.0fc %10.0fc a2"
										"%10.0fc %10.0fc a2" 
										"a2"                  )  )

		using "$out_file_balance_esttab" , 
													
		varlabels(hh1_total_income "Total Income (MNT)" 
					hh1_total_expend "Total Consumption Spending (MNT)"
					hh1_landq_avg "Average Land Quality at Seasonal Camps"
					hh1_herd_size "Herd Size (sheep units)"
					hh1_num_animals "Number of Livestock"
					hh1_migrat_num_yr "Annual Number of Seasonal Migrations"
					hh1_migrat_dist_yr "Annual Distance Migrated"
					hh1_famsize "Number of Household Members"
					hh1_hh_head_age "Age of Household Head"
					hh1_educ_head "Household Head's Years of Schooling"        ) 
			
		collabels("Treatment Mean" 
					"Control Mean" 
					"Difference (Treatment - Control)" 
					"Std. Err. of Difference" 
					"p-value"                          )
												
		label nomtitles nonumbers noobs replace
;

#delimit cr

