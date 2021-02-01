#!/bin/bash
#Comments: 
#This script is called by Link.sh. It will manage the times series calculation with the coordinates entered by web user.
#
#		Dependencies:
#		- Must be connected by local network to Doris-pro and HP-Server
#		- TimeSeriesInfo_bis.sh 
#		- mutt must be installed to send email
#	Arguments:
#		No arguments.
#
#	Action:
#		- Create a directory in ‘zRequestFolder’ where the created time series will be stored.
#		- Check the connection to Doris-Pro and hp server. Try to reconnect 3 times every 60sec if needed, if the communication still fails an email will be sent.
#		- Check if time series LOS_ascending must be calculated.
#		- Extract coordinates in local variables. Copy coordinate file to doris-pro server.
#		- Connect with SSH to doris-pro server and perform the following actions:
#		- Extract coordinates.
#		- Launch PlotTS.sh (This shell script must be run on Doris-pro because it uses some programs function installed on doris-pro)
#		- From terra2, move the eps files just created by doris-pro to the corresponding folder in Qgis2Web/Time_series folder.
#		- Create the final jpeg time series with thumbnail and legend using “TimeSeriesInfo_bis.sh”.
#		- Do the same for “LOS_Descending”, EW and UD time series.
#		- Clean directories.
#		- Verification of created files in the request folder. Assign a numerical value in a variable to know how many files we must attach do the email.
#		- Send the email and create a file with request information in ‘zRequestSent ‘ folder to confirm the process did execute successfully.
#
#####################################################################################

source ${HOME}/.bashrc


LocalPath='/Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web'
RequestPath="${LocalPath}/Time_Series/zRequest"
RequestTempFile="${LocalPath}/Time_Series/zRequest/temp.txt"
RequestArchiveDir="${LocalPath}/Time_Series/zRequestArchive"
RequestInfo="${LocalPath}/Request_info.txt"
Message="${LocalPath}/message.txt"
MailHeader="${LocalPath}/MailHeader.txt"
logo="${LocalPath}/logo_all_3.png"

DORISPRO='/Volumes/doris/MAXIME'
DorisHome='/Users/doris'
DorisPATHGNU='/opt/local/bin'
PathQgis2Web='/Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web'
Logfile='/Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web/qgis2web.log'
errormessage='An issue occurs during request to remote server: support team is informed and will react asap'

MSBASDIR='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_20m_450days'
REMARKDIR='_Auto_3_0.04_Domuyo'

WebSite="/Library/Server/Web/Data/Sites/defo-domuyo/images"

W_TS_EW_UD="${PathQgis2Web}/Time_Series/EW_UD"
W_TS_Asc="${PathQgis2Web}/Time_Series/Ascending"
W_TS_Desc="${PathQgis2Web}/Time_Series/Descending"

W_TS_sorted="${PathQgis2Web}/Time_Series/TS_sorted"
W_TS="${PathQgis2Web}/Time_Series"

W_A_18_Amplitude="$WebSite/Amp_Coh_Defo/A_18"
W_D_83_Amplitude="$WebSite/Amp_Coh_Defo/D_83"
W_Script_Path="/Library/Server/Web/Data/Sites/defo-domuyo/script"

/bin/echo "Executing Qgis2Web" > $Logfile

email=$(sed '1q;d' ${RequestInfo})
info=$(sed '2q;d' ${RequestInfo})
Orbit=$(cat ${RequestTempFile} | cut -d '/' -f 1)
RequestId=$(cat ${RequestTempFile} | cut -d '/' -f 2)

cp ${Message} ${RequestArchiveDir}/${RequestId}.txt
mkdir ${RequestPath}/${RequestId} >> ${Logfile} 2>&1

sleep 1 #To be sure that TS_Data.txt has been written by php scrit

#Check connectivity to Doris-Pro server and hp server
if [ ! -e ${MSBASDIR} ] || [ ! -e ${DORISPRO} ]
then 
	i=0
	while [ ! -e ${MSBASDIR} ] || [ ! -e ${DORISPRO} ]
		do
			open 'smb://ecgs:19RueJosyWelter@192.168.64.120/hp-D3602-Data_RAID5'
			open 'smb://doris:d0r1s@192.168.64.119/doris'
			echo "Wait for connectivity to HPserver"  >> $Logfile
			sleep 10
			i=$((i +1))
			echo $i
				if [ $i -gt 3 ]
					then 
						echo "Domuyo region custom time series creation" | mutt -s "Connection issue between Terra2 to HP Server or Doris-pro" -- maxime@ecgs.lu
						echo ${errormessage} | mutt -s "Time Series creation for Domuyo" -- ${email}
						exit
				fi
		done
fi

# Check connectivity from Doris-pro to hp Server (the email is sent from terra 2 to user because variable do not pass through ssh here)
		/usr/bin/ssh -T doris@192.168.64.119 << 'ENDSSH'

		source /Users/doris/.bashrc

		if [ ! -d  /Volumes/hp-D3602-Data_RAID5/MSBAS ]
			then 
				i=0
					while [ ! -d  /Volumes/hp-D3602-Data_RAID5/MSBAS ]
						do
							open 'smb://ecgs:19RueJosyWelter@192.168.64.120/hp-D3602-Data_RAID5'
							sleep 20
							i=$((i +1))
							if [ $i -gt 3]
							 	then
									echo "Connection issue defo-domuyo send from doris-pro" | mutt -s "Connection issue between Doris-pro and HP Server" -- maxime@ecgs.lu
									touch ${HOME}/MAXIME/Domuyo/error.info
									exit
							fi
						done
		fi

ENDSSH

if [ -e ${DORISPRO}/Domuyo/error.info ]
	then	
		echo ${errormessage} | mutt -s "Time Series creation for Domuyo region" -- ${email}
		echo "Connection issue defo-domuyo send from terra2" | mutt -s "Connection issue between Doris-pro and HP Server" -- maxime@ecgs.lu
		rm ${DORISPRO}/Domuyo/error.info
fi

# Check which calculation we are going to do (all, LOS Asc or LOS Desc)
Data=$(/bin/cat /Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web/TS_Data.txt)
X1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 1)
Y1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 2)
X2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 3)
Y2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 4)

ORDER=3
# Lambda
LAMBDA=0.04
BP=20



# Next copy will be used within next SSH connection to doris-pro
cp ${PathQgis2Web}/TS_Data.txt /Volumes/doris/MAXIME/Domuyo




############################# Connection to 192.168.64.119 and send command from here #################



########################################## LOS_ASC ################################################
if [ "${Orbit}" == "LOS_Asc" ] || [ "${Orbit}" == "All" ]
	then

		echo "start LOS_ASC calculation" >> $Logfile
		/usr/bin/ssh -T doris@192.168.64.119 << 'ENDSSH'

		source /Users/doris/.bashrc
		Data=$(/bin/cat /Users/doris/MAXIME/Domuyo/TS_Data.txt)

		X1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 1)
		Y1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 2)
		X2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 3)
		Y2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 4)

		ORDER=3
		# Lambda
		LAMBDA=0.04
		BP=20


		cd /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Asc_Auto_${ORDER}_${LAMBDA}_Domuyo/	
		/Users/doris/PROCESS/SCRIPTS_OK/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f # remove -f if does not want the linear fit
		rm plotTS*.gnu timeLine*.png timeLine*.txt
ENDSSH

		/usr/bin/find ${W_TS_Asc} -type f -delete #Remove first existing file

		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Asc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X1}_${Y1}.eps ${W_TS_Asc}/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Asc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X2}_${Y2}.eps ${W_TS_Asc}/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Asc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${W_TS_Asc}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
	



		/bin/echo "Creation Times series for LOS ascending" >> $Logfile

		for files in ${W_TS_Asc}/*		#Rename the downloaded file to have deformation direction in the name 
			do
				files_new=$(/bin/echo "${files//.eps/_LOS_Asc.eps}")
				mv $files $files_new
			done

		for files in $(/usr/bin/find ${W_TS_Asc} -type f -maxdepth 1 -name "*_LOS_Asc.eps")  #Insert maps 
			do
				${PathQgis2Web}/TimeSeriesInfo_bis.sh $files ${W_A_18_Amplitude}/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Asc.jpg ${RequestId}
			done
fi
########################################## LOS_DESC ################################################

if [ "${Orbit}" == "LOS_Desc" ] || [ "${Orbit}" == "All" ]
	then
		echo "start LOS_Desc calculation" >> $Logfile
		/usr/bin/ssh -T doris@192.168.64.119 << 'ENDSSH'

		source /Users/doris/.bashrc
		Data=$(/bin/cat /Users/doris/MAXIME/Domuyo/TS_Data.txt)

		X1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 1)
		Y1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 2)
		X2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 3)
		Y2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 4)

		ORDER=3
		# Lambda
		LAMBDA=0.04
		BP=20


		cd /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Desc_Auto_${ORDER}_${LAMBDA}_Domuyo/	
		/Users/doris/PROCESS/SCRIPTS_OK/PlotTS.sh ${X1} ${Y1} ${X2} ${Y2} -f # remove -f if does not want the linear fit
		rm plotTS*.gnu timeLine*.png timeLine*.txt


ENDSSH
		/usr/bin/find ${W_TS_Desc} -type f -delete #Remove first existing file

		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Desc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X1}_${Y1}.eps ${W_TS_Desc}/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Desc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X2}_${Y2}.eps ${W_TS_Desc}/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_LOS_Desc_Auto_${ORDER}_${LAMBDA}_Domuyo/timeLine${X1}_${Y1}_${X2}_${Y2}.eps ${W_TS_Desc}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps



		/bin/echo "Creation Times series for LOS descending"  >> $Logfile
	
		for files in $W_TS_Desc/*		#Rename the downloaded file to have deformation direction in the name 
			do
				files_new=$(/bin/echo "${files//.eps/_LOS_Desc.eps}")
				mv $files $files_new
			done
	
		for files in $(/usr/bin/find $W_TS_Desc -type f -maxdepth 1 -name "*_LOS_Desc.eps")   #Insert maps 
			do
				${PathQgis2Web}/TimeSeriesInfo_bis.sh $files ${W_D_83_Amplitude}/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Desc.jpg ${RequestId}
			done
fi
########################################## EW UD################################################

if [ "${Orbit}" == "All" ]
	then
		echo "start EW_UD calculation"  >> $Logfile
		/usr/bin/ssh -T doris@192.168.64.119 << 'ENDSSH'

		source /Users/doris/.bashrc
		Data=$(/bin/cat /Users/doris/MAXIME/Domuyo/TS_Data.txt)

		X1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 1)
		Y1=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 2)
		X2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 3)
		Y2=$(/bin/echo ${Data} | /usr/bin/cut -d '_' -f 4)

		ORDER=3
		# Lambda
		LAMBDA=0.04
		BP=20
	
		cd /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/	
		/Users/doris/PROCESS/SCRIPTS_OK/PlotTS_all_comp.sh _Auto_${ORDER}_${LAMBDA}_Domuyo ${X1} ${Y1} ${X2} ${Y2} -f # remove -f if does not want the linear fit
		rm plotTS*.gnu timeLine*.png timeLine*.txt

ENDSSH

		/usr/bin/find ${W_TS_EW_UD} -type f -delete #Remove first existing file

		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_20m_450days/timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps ${W_TS_EW_UD}/${DESCRIPTION}_timeLines_${X1}_${Y1}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_20m_450days/timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps ${W_TS_EW_UD}/${DESCRIPTION}_timeLines_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps
		mv /Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_20m_450days/timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps ${W_TS_EW_UD}/${DESCRIPTION}_timeLines_${X1}_${Y1}_${X2}_${Y2}_Auto_${ORDER}_${LAMBDA}_Domuyo.eps

		RUNDIREW=/Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_EW_Auto_${ORDER}_${LAMBDA}_Domuyo
		RUNDIRUD=/Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_${BP}m_450days/zz_UD_Auto_${ORDER}_${LAMBDA}_Domuyo
	
		rm ${RUNDIREW}/timeLine_EW_${X1}_${Y1}_Auto_3_0.04_Domuyo.txt
		rm ${RUNDIREW}/timeLine_EW_${X2}_${Y2}_Auto_3_0.04_Domuyo.txt	
		rm ${RUNDIRUD}/timeLine_UD_${X1}_${Y1}_Auto_3_0.04_Domuyo.txt
		rm ${RUNDIRUD}/timeLine_UD_${X2}_${Y2}_Auto_3_0.04_Domuyo.txt	



		/bin/echo "Creation Times series for EW_UD "  >> $Logfile

	
		for files in $W_TS_EW_UD/*		#Rename the downloaded file to have deformation direction in the name 
			do
				files_new=$(/bin/echo "${files//.eps/_EW_UD.eps}")
				mv $files $files_new
			done

		for files in $(/usr/bin/find $W_TS_EW_UD -type f -maxdepth 1 -name "*_EW_UD.eps")
			do
				${PathQgis2Web}/TimeSeriesInfo_bis.sh $files ${W_A_18_Amplitude}/AMPLI_COH_MSBAS_LINEAR_RATE_EW.jpg ${RequestId}
				
			done

fi

# Send email to request

i=0
for files in ${RequestPath}/${RequestId}/*
 do 
 		echo ${files}
 		case ${files} in
 			*"_EW_UD_"*)
 					combi_1=$(echo ${files})
 					i=$((i + 1))			
 					;;
 			*"LOS_Asc"*)
 					combi_2=${files}
 					i=$((i + 2))			
 					;;
 			*"LOS_Desc"*)
 					combi_3=$(echo ${files})
 					i=$((i + 4))
				;;
 			*)
 					echo "fini"
 					;;
 			esac
 done



SendMail ()
{
RUNDATE=`date "+%Y%m%d_%H%M%S"` > ${LocalPath}/Time_Series/zRequestSent/${RequestId}.txt
echo "Email sent: ${RUNDATE}" >> ${LocalPath}/Time_Series/zRequestSent/${RequestId}.txt
echo "Request info: ${info}" >> ${LocalPath}/Time_Series/zRequestSent/${RequestId}.txt
echo "email: ${email}" >> ${LocalPath}/Time_Series/zRequestSent/${RequestId}.txt
}


cat "${RequestArchiveDir}/${RequestId}.txt" > ${MailHeader}
echo "" >> ${MailHeader}
echo "http://terra2.ecgs.lu/defo-domuyo/" >> ${MailHeader}

		case ${i} in
 			2)
 					cat "${MailHeader}" | mutt -s "Time Series Domuyo: ${info}" -a ${combi_2} -a ${logo} -- ${email}
 					SendMail
 					#cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- ndo@ecgs.lu 
 					cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- maxime@ecgs.lu 
 					;;
 			7)
 					cat "${MailHeader}" | mutt -s "Time Series Domuyo: ${info}" -a ${combi_1} -a ${combi_2} -a ${combi_3} -a ${logo} -- ${email}	
 					SendMail
 					#cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- ndo@ecgs.lu 
 					cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- maxime@ecgs.lu 
 					;;
 			4)
 					cat "${MailHeader}" | mutt -s "Time Series Domuyo: ${info}" -a ${combi_3} -a ${logo} -- ${email}
 					SendMail
 					#cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- ndo@ecgs.lu 
 					cat "${Message}" | mutt -s "Web User Time Series Request for Domuyo" -- maxime@ecgs.lu 
 					;;
 			*)
 					echo "pas normal"
 					cat "${Message}" | mutt -s "Issue when creating time series: number of TS created mismatch" -- maxime@ecgs.lu
 					;;
 			esac


sleep 1 # Let the time to write the file to '${RequestArchiveDir}/${RequestId}.txt'

# Check if files in zRequest , zRequestArchiveDir and zRequestSent are matching

Num1=$(find ${LocalPath}/Time_Series/zRequestArchive -type f -name [0-9]* | wc -l)
Num2=$(find ${LocalPath}/Time_Series/zRequestSent -type f -name [0-9]* | wc -l)
Num3=$(find ${RequestPath} -type d -name [0-9]* | wc -l)
if [[ $Num1 == $Num2 ]] && [[ $Num2 == $Num3 ]]
	then 
		echo 'ok'
	else
		echo 'Creation Custom Time Serie Domuyo, mismatch number of files in zFolder' | mutt -s "Issue is TS zFolder (Domuyo)" -- maxime@ecgs.lu
	fi