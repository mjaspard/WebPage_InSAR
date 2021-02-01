#!/bin/bash
#
#Comments: This script is called by index.php as sonn as a uweb user submit the request.
#
#		Dependencies:
#		- script python: CheckCoh.py
#	Arguments:
#		No arguments.
#
#			Action:
# 		- Check if the coordinates are different from the last request.
#		- Check if a request is already running. If yes, message info is display to the web user (Request already running, please wait)
#		- Extract coordinate data from file.
#		- Check coherence in both orbit of two points with “checkCoh.py”.
#		- Create a filename “${ReqId}”, including date and time, coordinates and request name. 
#		- Fill the file “message.txt” with all the infos from this request.
#		- Read the feedback of the python script “CheckCoh.py” and write the value in local variables.
#		- Fill the file message.txt file with the coherence information, and create a variable “${value} to code this information with a numerical value.
#		- Use this numerical value to interpret which time series must be calculated based on the coherence (If a point is coherent only in one orbit, only the LOS time series of this orbit will be calculated, and no EW or UD will be generated), write the resut in variable ${Orbit}
#		- Write the two variables ${Orbit}/${ReqId} in a file “temp.txt” in zRequest Folder.
#		- Copy the variable ${Message} containing request infos to the “zRequestArchive” folder in a file named ${ReqId}.txt to keep a trace of this request.
#		- Using the osascript function, we will call the shell script “Custom_TS” to launch the time series calculation. Osascript is useful to dissociate the call of “Custom_TS”, otherwise the web page script “index.php” will wait for the end of the script for refreshing. And as Custom_TS will last more than 1 minutes, we would get a timeout if we would launch Custom_TS with a basic “exec” function.
#
#		- Then copy the file “TS_Data.txt” to “TS_Data_Done.txt” to avoid a duplicate consecutive calculation.
# -*-coding:Utf-8 -*
source /Users/ecgsadmin/.bashrc

LocalPath='/Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web'
RequestPath="${LocalPath}/Time_Series/zRequest"
MaskAsc="/Library/Server/Web/Data/Sites/defo-domuyo/images/Amp_Coh_Defo/Mask/LOS_Asc_Defo_bin_Mask"
MaskDesc="/Library/Server/Web/Data/Sites/defo-domuyo/images/Amp_Coh_Defo/Mask/LOS_Desc_Defo_bin_Mask"

old="${LocalPath}/TS_Data_done.txt"
new="${LocalPath}/TS_Data.txt"
Results="${LocalPath}/CheckCoh.txt"
Message="${LocalPath}/message.txt"
RequestInfo="${LocalPath}/Request_info.txt"
log="${LocalPath}/log.txt"
Coh_error="${LocalPath}/Coh_error.txt"
PixNum=5361 # from hdr
sleep 1 # To ensure php write to the file

now=`date "+%Y%m%d_%H%M%S"`
echo "start script at date $now" > ${log} 2>&1
echo "" > ${Coh_error}

RunProcessNum=$(ps -ax | grep Custom_TS.sh | wc -l | awk '{print $1}') >> ${log} 2>&1
RunProcessNum=$((RunProcessNum - 1)) >> ${log} 2>&1
echo "run process number: $RunProcessNum"

if cmp -s $old $new  >> ${log} 2>&1
	then
			echo "" > ${Results}
			echo "Process already done" > ${Message}
			echo 'process already done' >> ${log}
	else
		
		if  [ ${RunProcessNum} -gt 1 ]
			then
				echo "PLEASE WAIT - Request already in running: " > ${Message}
				echo "Process number = ${RunProcessNum}" >> ${Message}	
				echo "Refresh the page in about 1 minute and your request will be executed" >> ${Message}
				echo 'process already in running' >> ${log}
				echo"" > ${Results}
			else
				echo 'process can start checking coherence' >> ${log}
				X1=$(cat ${new} | cut -d '_' -f 1)		 
				Y1=$(cat ${new} | cut -d '_' -f 2)		
				X2=$(cat ${new} | cut -d '_' -f 3)		
				Y2=$(cat ${new} | cut -d '_' -f 4)		
			
				email=$(sed '1q;d' ${RequestInfo}) 
				description=$(sed '2q;d' ${RequestInfo}) 
				description=$(echo ${description} | sed -e "s/ /_/g") 
				RUNDATE=`date "+%Y%m%d_%H%M%S"` 
				echo $RUNDATE
				ReqId="${RUNDATE}_${X1}_${Y1}_${X2}_${Y2}_${description}" 

				echo "Results of last request:" > ${Message} 
				echo "Request name:  $description" >> ${Message}
				echo "Coordinate: - Point A = [$X1:$Y1] - Point B = [$X2:$Y2]" >> ${Message}
				echo "Email: ${email}" >> ${Message}

				${LocalPath}/CheckCoh.py $X1 $Y1 $X2 $Y2 ${PixNum} ${MaskAsc} ${MaskDesc} ${Results} 2> ${Coh_error}
				
				if [[ -s ${Coh_error} ]]
					then
						echo -e  "Coordinates coherence verification failure, select 2 points within Sentinel 1 amplitude area" > ${Message}		
						exit
				fi
				
				echo 'script python done' >> ${log}
				

				A_ASC=$(cat ${Results} | grep Ascending | cut -d '_' -f 3)
				B_ASC=$(cat ${Results} | grep Ascending | cut -d '_' -f 4)
				A_DESC=$(cat ${Results} | grep Descending | cut -d '_' -f 3)
				B_DESC=$(cat ${Results} | grep Descending | cut -d '_' -f 4)

				if (( $(echo "${A_ASC} > 0.0" | bc -l) )); then echo 'Point A is coherent in Ascending' >> ${Message} ; else echo 'Point A is NOT coherent in Ascending' >> ${Message}; fi
				if (( $(echo "${B_ASC} > 0.0" | bc -l) )); then echo 'Point B is coherent in Ascending' >> ${Message}; else echo 'Point B is NOT coherent in Ascending' >> ${Message}; fi
				if (( $(echo "${A_DESC} > 0.0" | bc -l) )); then echo 'Point A is coherent in Descending' >> ${Message}; else echo 'Point A is NOT coherent in Descending' >> ${Message};fi
				if (( $(echo "${B_DESC} > 0.0" | bc -l) )); then echo 'Point B is coherent in Descending' >> ${Message}; else  echo 'Point B is NOT coherent in Descending' >> ${Message};fi		

				if (( $(echo "${A_ASC} > 0.0" | bc -l) )); then value=1 ; else value=0;  fi
				if (( $(echo "${B_ASC} > 0.0" | bc -l) )); then ((value+=2)) ; fi
				if (( $(echo "${A_DESC} > 0.0" | bc -l) )); then ((value+=4)) ; fi
				if (( $(echo "${B_DESC} > 0.0" | bc -l) )); then ((value+=8)) ; fi	

				echo '' >> ${Message}
					if [ ${value} -eq 15 ]
						then 
							echo 'All Time Series will be calculated (East/West -- Up/Down -- LOS Ascending -- LOS Descending) and sent to email.' >> ${Message}
							Orbit="All"
					elif [ ${value} -eq 3 ] || [ ${value} -eq 7 ] || [ ${value} -eq 11 ]
						then 
							echo 'Time Series will be calculated for LOS Ascending and sent to email.' >> ${Message}
							Orbit="LOS_Asc"
					elif [ ${value} -eq 12 ] || [ ${value} -eq 13 ] || [ ${value} -eq 14 ]
						then 
							echo 'Time Series will be calculated for LOS Descending and sent to email.' >> ${Message}
							Orbit="LOS_Desc"
					else
							echo 'No Time Series are able to be calculated: at least both points must be coherent for one orbit.' >> ${Message}
							exit
					fi
					
					touch ${RequestPath}/temp.txt	
					echo "${Orbit}/${ReqId}" > ${RequestPath}/temp.txt
					
					echo 'start script custom_TS' >> ${log} 
					whoami >> ${log}  
				 	
					exec sudo -u ecgsadmin /Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web/Custom_TS.sh >> ${log} 2>&1 &
					cp $new $old
				fi
					
fi