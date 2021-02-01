#!/bin/bash
# -----------------------------------------------------------------------------------------
#FOR DETAILED INFORMATIONS REGARDING THE PROCESS OF THIS SCRIPT, PLEASE REFER TO /Library/Server/Web/Data/Sites/defo-lux/Documents/Page_Web.docx 
#
# This script will perform sequentially the following action:
# 
#		- DOWNLOAD DATA FROM HP SERVER
#		- CREATION AMPLITUDE-COHERENCE-DEFORMATION COMBINE IMAGE (ASCENDING)
#		- CREATION AMPLITUDE-COHERENCE-DEFORMATION COMBINE IMAGE (DESCENDING) 
#		- CREATE LAST AMPLITUDE JPG FILE 
#		- CREATION OF MAPS IN TIME SERIE GRAPHICS
#		- READ LAST DATE ON HP SERVER
#		- READ THE LAST MODIFICATION TIME ON DOWNLOADED FILE
#		- CREATE KMZ FILE
#
# Parameters: No argument. All the path and files name are hard coded
#
# Hard coded:	- All the path to source directory (HO Server) 
#				- All the PATh to the Web Server
#				- Path where dependent script are located
#				- RadarSize= size of deformation maps thumbnail
#				- PlotSize= size of Time Series thumbnail
#				- Name of Mask file and Amp_coh_defo file before the call of python and fiji script
#	
#Script:		Main.sh 	--> Mask_Builder.py
#							--> Amplitude_Average.py
#							--> Fiji_Amp_Defo_Coh.sh	--> CreateColorFrame.py
#							--> TimeSeriesInfo.sh	
#							--> ZoneMaker_1.0.sh
#							--> ZoneMaker_1.0.sh
#							--> TS_ReadLastPoint.sh
#							--> ImageCreator.sh	--> Amplitude_log10.py
#							--> KMzCreator.sh	--> GetMinMax.py
#												--> Envi2ColorKmz.sh
#
#
# Dependencies:	- Fiji (ImageJ). 
#				- gnu sed for more compatibility. 
#				
# 
#Syntax of variables:	W_** = Path to a folder in the Web Server
#						GD = Ground Deformatio
#						TS = Time series

# Maxime Jaspard ( 9th of JUNE 2020)
# -----------------------------------------------------------------------------------------
source ${HOME}/.bash_profile


#Function to write in a console and in a $Logfiles
function EchoTee()
	{
	unset MESSAGE
	local MESSAGE=$1
	echo $(date "+%Y-%m-%d% %H:%M:%S")"___${MESSAGE}"	| tee -a $Logfile
	}
	
EchoTee " ************** Creation of variables ************" 

#*********   SOURCE DATA    ***********

#Create Source Path for ground deformation linear rate (raster file)
Common='/Volumes/hp-D3602-Data_RAID5/MSBAS/_Domuyo_S1_Auto_20m_450days'
UD_Defo="$Common/zz_UD_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_UD.bin.ras"
EW_Defo="$Common/zz_EW_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_EW.bin.ras"
LOS_Asc_Defo="$Common/zz_LOS_Asc_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_LOS.bin.ras"
LOS_Desc_Defo="$Common/zz_LOS_Desc_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_LOS.bin.ras"

#Create Source Path for ground deformation linear rate (binary files file)
UD_Defo_bin="$Common/zz_UD_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_UD.bin"
EW_Defo_bin="$Common/zz_EW_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_EW.bin"
LOS_Asc_Defo_bin="$Common/zz_LOS_Asc_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_LOS.bin"
LOS_Desc_Defo_bin="$Common/zz_LOS_Desc_Auto_3_0.04_Domuyo/MSBAS_LINEAR_RATE_LOS.bin"

#Create Source Path for Amplitude SAR images
A_18_Ampli='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4/Geocoded/Ampli'
D_83_Ampli='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4/Geocoded/Ampli'
A_18_dir='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_A_18/SMNoCrop_SM_20180512_Zoom1_ML4'
D_83_dir='/Volumes/hp-D3601-Data_RAID6/SAR_MASSPROCESS/S1/ARG_DOMU_LAGUNA_D_83/SMNoCrop_SM_20180222_Zoom1_ML4'

#*********   WEBSITE DATA    ***********

#Create WebSiteTarget path
WebSite='/Library/Server/Web/Data/Sites/defo-domuyo/images'
WebSite_Doc='/Library/Server/Web/Data/Sites/defo-domuyo/Documents'

#Utilities Data
Logfile="$WebSite/Logfile.txt"

#Create Target Path folder for Deformation rate and Time Series
W_GD_EW_UD="$WebSite/GD_Linear_Rate/EW_UD"
W_GD_Asc="$WebSite/GD_Linear_Rate/Ascending"
W_GD_Desc="$WebSite/GD_Linear_Rate/Descending"
W_TS_EW_UD="$WebSite/Time_Series/EW_UD"
W_TS_Asc="$WebSite/Time_Series/Ascending"
W_TS_Desc="$WebSite/Time_Series/Descending"
W_TS_all="$WebSite/Time_Series/TS_all"
W_TS_sorted="$WebSite/Time_Series/TS_sorted"
W_TS="$WebSite/Time_Series"

#Create Target Path folder for Amplitude and Mask
W_A_18_Amplitude="$WebSite/Amp_Coh_Defo/A_18"
W_D_83_Amplitude="$WebSite/Amp_Coh_Defo/D_83"
W_Defo_Mask="$WebSite/Amp_Coh_Defo/Mask"

#Create Path where script in dependencies are located
W_Script_Path="/Library/Server/Web/Data/Sites/defo-domuyo/script"

#Enter Thumbnail size for images in Web pages
RadarSize=500

#Empty logfile.txt
Echo "" > $Logfile


EchoTee "Variable declaration done" 

EchoTee "Check server connectivity" 

if [ ! -e ${Common} ] || [ ! -e ${A_18_Ampli} ]
then 
	i=0
	while [ ! -e $Common ] || [ ! -e ${A_18_Ampli} ]
		do
			open 'smb://ecgs:19RueJosyWelter@192.168.64.120/hp-D3602-Data_RAID5'
			open 'smb://ecgs:19RueJosyWelter@192.168.64.120/hp-D3601-Data_RAID6'
			EchoTee "Wait for connectivity to HPserver"
			sleep 10
			i=$((i +1))
			echo $i
				if [ $i -gt 3 ]
					then 
						echo "Domuyo region" | mutt -s "Connection issue between terra3 to HP Server" -- maxime@ecgs.lu
						exit
				fi
		done
fi

EchoTee "Server connectivity ok" 

if [ 4 -gt 8 ]
then
	echo "Never here"
else

EchoTee ""
EchoTee "************-------Download deformation binary file from HP Server ---------****************"
EchoTee ""

#Copy linear rate ground deformation maps

# Copy Deformation Binary file in Local
cp ${UD_Defo_bin} ${W_GD_EW_UD}/MSBAS_LINEAR_RATE_UD.bin
cp ${EW_Defo_bin} ${W_GD_EW_UD}/MSBAS_LINEAR_RATE_EW.bin
cp ${LOS_Asc_Defo_bin} ${W_GD_Asc}/MSBAS_LINEAR_RATE_LOS_Asc.bin
cp ${LOS_Desc_Defo_bin} ${W_GD_Desc}/MSBAS_LINEAR_RATE_LOS_Desc.bin

# Extract last modification date of binary file
echo $(date -r ${UD_Defo_bin} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/GD_LR_UD_time.txt
echo $(date -r ${EW_Defo_bin} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/GD_LR_EW_time.txt
echo $(date -r ${LOS_Asc_Defo_bin} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/GD_LR_LOS_Asc_time.txt
echo $(date -r ${LOS_Desc_Defo_bin} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/GD_LR_LOS_Desc_time.txt

# Copy Deformation Binary Header file in Local
cp ${UD_Defo_bin}.hdr ${W_GD_EW_UD}/
cp ${EW_Defo_bin}.hdr ${W_GD_EW_UD}/
cp ${LOS_Asc_Defo_bin}.hdr ${W_GD_Asc}/MSBAS_LINEAR_RATE_LOS_Asc.bin.hdr
cp ${LOS_Desc_Defo_bin}.hdr ${W_GD_Desc}/MSBAS_LINEAR_RATE_LOS_Desc.bin.hdr




EchoTee ""
EchoTee "******** CREATION AMPLITUDE_COHERENCE_DEFORNMATION combine IMAGE (Ascending)*********"
EchoTee ""
#Download last 10 Amplitudes images for orbit A_18
EchoTee "Download of 10 more recent amplitude file is done for orbit A_18"
i=0
#for files in `find $A_18_Ampli -type f | tail -n 20`
find ${W_A_18_Amplitude} -name "*deg" -delete
for files in $(ls -t ${A_18_Ampli} | grep deg$ | head -n 10)
	do
		if [ $i -lt 10 ]
			then
				#echo "$files"
				cp -p ${A_18_Ampli}/$files $W_A_18_Amplitude >> $Logfile 2>&1
				i=$((i+1))
			else
				break
		fi
	done
find ${W_A_18_Amplitude} -name *"20190525_20200811"* -delete  # error on image
find ${W_A_18_Amplitude} -name "*hdr" -delete
files=$(ls -t ${A_18_Ampli} | grep hdr$ | head -n 1) >> $Logfile 2>&1
cp -p ${A_18_Ampli}/$files $W_A_18_Amplitude >> $Logfile 2>&1


EchoTee "$i amplitude files have been copied for orbit A_18"



EchoTee "Script Mask_Builder.py is called 4 times to create Coherence files for orbit A_18"


# Create the mask for each deformation file based on Linear rate binary file (Defo/Defo *0.8
# This python script create a mask for each linear rate deformation file. We use here the binary file and not the raster.

$W_Script_Path/Mask_Builder.py $UD_Defo_bin $W_Defo_Mask/UD_Defo_bin_Mask >> $Logfile 2>&1
$W_Script_Path/Mask_Builder.py $EW_Defo_bin $W_Defo_Mask/EW_Defo_bin_Mask >> $Logfile 2>&1
$W_Script_Path/Mask_Builder.py $LOS_Asc_Defo_bin $W_Defo_Mask/LOS_Asc_Defo_bin_Mask >> $Logfile 2>&1
$W_Script_Path/Mask_Builder.py $LOS_Desc_Defo_bin $W_Defo_Mask/LOS_Desc_Defo_bin_Mask >> $Logfile 2>&1

EchoTee "Amplitude_Average.py is called to create amplitude average binary file for orbit A_18"


#Script python will calculate the logarithm of each amplitude file in the AVG folder.
#Then the script calculates the average in the output file "AMP_AVERAGE"

$W_Script_Path/Amplitude_Average.py $W_A_18_Amplitude $W_A_18_Amplitude/A_18_Amplitude_Average >> $Logfile 2>&1

EchoTee "Mask and amplitude average binary file are created for orbit A_18"



#Creation of a header file with the same name as 'AmpAvg'

hdr=$(find $W_A_18_Amplitude -type f -name "*.hdr" | Head -n 1)
cp $hdr $W_A_18_Amplitude/A_18_Amplitude_Average.hdr >> $Logfile 2>&1


EchoTee "Creation of a header file for average amplitude is done for orbit A_18"

#Create the combination image include amplitude average, coherence mask and deformation 

EchoTee "SCRIPT FIJI START: Call 4 times fiji script to create the 4 final images (combined Amplitude, deformation with a mask)   "




#Call 4 times fiji script to create the 4 final images (combined Amplitude, deformation with a mask) 
MLR="MSBAS_LINEAR_RATE"
ACMLR="AMPLI_COH_MSBAS_LINEAR_RATE"
$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_A_18_Amplitude/A_18_Amplitude_Average $W_Defo_Mask/UD_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_UD.bin ${ACMLR}_UD >> $Logfile 2>&1
$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_A_18_Amplitude/A_18_Amplitude_Average $W_Defo_Mask/EW_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_EW.bin ${ACMLR}_EW >> $Logfile 2>&1
$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_A_18_Amplitude/A_18_Amplitude_Average $W_Defo_Mask/LOS_Asc_Defo_bin_Mask ${W_GD_Asc}/${MLR}_LOS_Asc.bin ${ACMLR}_LOS_Asc >> $Logfile 2>&1
#$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_A_18_Amplitude/A_18_Amplitude_Average $W_Defo_Mask/LOS_Desc_Defo_bin_Mask ${W_GD_Desc}/${MLR}_LOS_Desc.bin ${ACMLR}_LOS_Desc >> $Logfile 2>&1



EchoTee "SCRIPT FIJI END  -"
EchoTee "Thumbnail Creation for the amplitude-coherence images  -"

sips -Z $RadarSize $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_EW.jpg --out $W_A_18_Amplitude/mini  >> $Logfile 2>&1
sips -Z $RadarSize $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Asc.jpg --out $W_A_18_Amplitude/mini  >> $Logfile 2>&1
#sips -Z $RadarSize $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Desc.jpg --out $W_A_18_Amplitude/mini  >> $Logfile 2>&1
sips -Z $RadarSize $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_UD.jpg --out $W_A_18_Amplitude/mini  >> $Logfile 2>&1

EchoTee "Final combination of amplitude, coherence and deformation is done for orbit A_18"

EchoTee ""
EchoTee "******** CREATION AMPLITUDE_COHERENCE_DEFORNMATION combine IMAGE (Descending)*********"
EchoTee ""

#Download last 10 Amplitudes images for orbit D_83
find ${W_D_83_Amplitude} -name "*deg" -delete
i=0
for files in $(ls -t ${D_83_Ampli} | grep deg$ | head -n 10)
	do
		if [ $i -lt 10 ]
			then
				#echo "$files"
				cp -p ${D_83_Ampli}/$files $W_D_83_Amplitude >> $Logfile 2>&1
				i=$((i+1))
			else
				break
		fi
	done
find ${W_D_83_Amplitude} -name "*hdr" -delete
files=$(ls -t ${D_83_Ampli} | grep hdr$ | head -n 1) >> $Logfile 2>&1
cp -p ${D_83_Ampli}/$files $W_D_83_Amplitude >> $Logfile 2>&1

EchoTee "$i amplitude files have been copied for orbit D_83"
EchoTee "Amplitude_Average.py is called to create amplitude average binary file for orbit D_83"

$W_Script_Path/Amplitude_Average.py $W_D_83_Amplitude $W_D_83_Amplitude/D_83_Amplitude_Average >> $Logfile 2>&1

EchoTee "Amplitude average binary file are created for orbit D_83"


#Creation of a header file with the same name as 'AmpAvg'

hdr=$(find $W_D_83_Amplitude -type f -name "*.hdr" | Head -n 1)
#echo $hdr 
cp $hdr $W_D_83_Amplitude/D_83_Amplitude_Average.hdr >> $Logfile 2>&1


#Create the combination image include amplitude average, coherence mask and deformation 

EchoTee "SCRIPT FIJI START: Call 4 times fiji script to create the 4 final images (combined Amplitude, deformation with a mask) "

#Call 4 times fiji script to create the 4 final images (combined Amplitude, deformation with a mask) 
MLR="MSBAS_LINEAR_RATE"
ACMLR="AMPLI_COH_MSBAS_LINEAR_RATE"
#$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_D_83_Amplitude/D_83_Amplitude_Average $W_Defo_Mask/UD_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_UD.bin ${ACMLR}_UD >> $Logfile 2>&1
#$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_D_83_Amplitude/D_83_Amplitude_Average $W_Defo_Mask/EW_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_EW.bin ${ACMLR}_EW >> $Logfile 2>&1
#$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_D_83_Amplitude/D_83_Amplitude_Average $W_Defo_Mask/LOS_Asc_Defo_bin_Mask ${W_GD_Asc}/${MLR}_LOS_Asc.bin ${ACMLR}_LOS_Asc >> $Logfile 2>&1
$W_Script_Path/Fiji_Amp_Defo_Coh.sh $W_D_83_Amplitude/D_83_Amplitude_Average $W_Defo_Mask/LOS_Desc_Defo_bin_Mask ${W_GD_Desc}/${MLR}_LOS_Desc.bin ${ACMLR}_LOS_Desc >> $Logfile 2>&1

EchoTee "SCRIPT FIJI END "
EchoTee "Thumbnail Creation for the amplitude-coherence images  -"


#sips -Z $RadarSize $W_D_83_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_EW.jpg --out $W_D_83_Amplitude/mini  >> $Logfile 2>&1
#sips -Z $RadarSize $W_D_83_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Asc.jpg --out $W_D_83_Amplitude/mini  >> $Logfile 2>&1
sips -Z $RadarSize $W_D_83_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Desc.jpg --out $W_D_83_Amplitude/mini  >> $Logfile 2>&1
#sips -Z $RadarSize $W_D_83_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_UD.jpg --out $W_D_83_Amplitude/mini  >> $Logfile 2>&1


EchoTee "Final combination of amplitude, coherence and deformation is done for orbit D_83"


EchoTee "------------------------Create last amplitude JPEG file ------------------------"




find $WebSite/xDynImages/ -type f -delete   >> $Logfile 2>&1

$W_Script_Path/ImageCreator.sh ${W_A_18_Amplitude} ${WebSite}/xDynImages >> $Logfile 2>&1
$W_Script_Path/ImageCreator.sh ${W_D_83_Amplitude} ${WebSite}/xDynImages >> $Logfile 2>&1
#As we just created here above a tif file for the last amplitude (and not the average of the 10 last) we create the thumb for that image here
sips -Z $RadarSize $W_A_18_Amplitude/A_18_Amplitude_LastImage.jpg --out $W_A_18_Amplitude/mini/A_18_Amplitude_LastImage.jpg  >> $Logfile 2>&1
sips -Z $RadarSize $W_D_83_Amplitude/D_83_Amplitude_LastImage.jpg --out $W_D_83_Amplitude/mini/D_83_Amplitude_LastImage.jpg  >> $Logfile 2>&1


EchoTee ""
EchoTee "************---------ADD INFORMATIONS ON TIME SERIE GRAPHICS------******************"
EchoTee ""



#Copy Times series (only *_Combi.jpg)
find ${W_TS_EW_UD} -type f -delete #Remove first existing file
for files in `find $Common/zz_UD_EW_TS_Auto_3_0.04_Domuyo | grep "[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*" | grep ".eps"`
	do
		cp -p $files $W_TS_EW_UD >> $Logfile 2>&1
	done


# for files in `find $Common/zz_UD_EW_TS_Auto_3_0.04_Domuyo_NoCohThresh | grep "[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*" | grep ".eps"`
# 	do
# 		cp -p $files $W_TS_EW_UD >> $Logfile 2>&1
# 	done

						
#Pour les Asc LOS sac:
find ${W_TS_Asc} -type f -delete #Remove first existing file
for files in `find $Common/zz_LOS_TS_Asc_Auto_3_0.04_Domuyo | grep "[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*" | grep ".eps"`
	do
		cp -p $files $W_TS_Asc >> $Logfile 2>&1
	done


#Pour les Desc LOS sac:
find ${W_TS_Desc} -type f -delete #Remove first existing file
for files in `find $Common/zz_LOS_TS_Desc_Auto_3_0.04_Domuyo | grep "[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*" | grep ".eps"`
	do
		cp -p $files $W_TS_Desc >> $Logfile 2>&1
	done
	

EchoTee "Download and thumbnail creation for Time Series deformation graph is done" 


EchoTee "Remove all files in the Time_series folder"
find ${W_TS_all} -type f -delete
find ${W_TS_sorted} -type f -delete
find ${W_TS}/TS_sorted_maps -type f -name "*combi.jpg" -delete		#We keep the google maps picture for routine execution (too big data on google mapsview)
find ${W_TS}/TS_sorted_satview -type f -name "*combi.jpg" -delete	#We keep the google maps picture for routine execution (too big data on google satview)


EchoTee "Creation Times series for EW "
	
for files in $W_TS_EW_UD/*		#Rename the downloaded file to have deformation direction in the name 
	do
		files_new=$(echo "${files//Domuyo.eps/Domuyo_EW_UD.eps}")
		mv $files $files_new
	done
# for files in $W_TS_EW_UD/*		#Rename the downloaded file to have deformation direction in the name 
# 	do
# 		files_new=$(echo "${files//Domuyo_NoCohThresh.eps/Domuyo_EW_UD_NoCohThresh.eps}")
# 		mv $files $files_new
# 	done
for files in $(find $W_TS_EW_UD -type f -maxdepth 1 -name "*_EW_UD*")
	do
		$W_Script_Path/TimeSeriesInfo.sh $files $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_EW.jpg  >> $Logfile 2>&1
	done



EchoTee "Creation Times series for LOS descending"
	
for files in $W_TS_Desc/*		#Rename the downloaded file to have deformation direction in the name 
	do
		files_new=$(echo "${files//Domuyo.eps/Domuyo_LOS_Desc.eps}")
		mv $files $files_new
	done
	
for files in $(find $W_TS_Desc -type f -maxdepth 1 -name "*Domuyo_LOS_Desc.eps")   #Insert maps 
	do
		$W_Script_Path/TimeSeriesInfo.sh $files $W_D_83_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Desc.jpg >> $Logfile 2>&1
	done


EchoTee "Creation Times series for LOS ascending"
	
for files in $W_TS_Asc/*		#Rename the downloaded file to have deformation direction in the name 
	do
		files_new=$(echo "${files//Domuyo.eps/Domuyo_LOS_Asc.eps}")
		mv $files $files_new
	done

for files in $(find $W_TS_Asc -type f -maxdepth 1 -name "*Domuyo_LOS_Asc.eps")  #Insert maps 
	do
		$W_Script_Path/TimeSeriesInfo.sh $files $W_A_18_Amplitude/AMPLI_COH_MSBAS_LINEAR_RATE_LOS_Asc.jpg >> $Logfile 2>&1
	done



EchoTee "Rename timeLines_ into timeLine for LOS"

# treatment of the filename to get Files in directories in the right order for Web Site
for files in $(find $W_TS_all -name "*.jpg")
do
filemodif=$(echo ${files} | sed  's/timeLine._/timeLine_/') >> $Logfile 2>&1   #To convert "timeLines_" into "timeLine_" to get all the same
mv $files $filemodif >> $Logfile 2>&1
done





EchoTee "Creation Amplitude images with area and one amplitude image for each pair of position + thumbnail creation"

mv $W_A_18_Amplitude/A_18_Amplitude_Average_2.0.jpg $W_A_18_Amplitude/A_18_Amplitude_Average.jpg
mv $W_D_83_Amplitude/D_83_Amplitude_Average_2.0.jpg $W_D_83_Amplitude/D_83_Amplitude_Average.jpg


sips -Z $RadarSize $W_A_18_Amplitude/A_18_Amplitude_Average.jpg --out $W_A_18_Amplitude/mini  >> $Logfile 2>&1
sips -Z $RadarSize $W_D_83_Amplitude/D_83_Amplitude_Average.jpg --out $W_D_83_Amplitude/mini  >> $Logfile 2>&1



EchoTee "Sort time series graphics in areas and create Sentinel 1 amplitude image per areas"

find ${W_TS_sorted} -type f -delete
cp $W_A_18_Amplitude/A_18_Amplitude_Average_2.0.tif $W_TS/ >> $Logfile 2>&1
$W_Script_Path/ZoneMaker_1.0.sh ${W_TS} >> $Logfile 2>&1
$W_Script_Path/ZoneMaker_2.0.sh $W_TS/A_18_Amplitude_Average_2.0.tif $W_TS TS_sorted 1 >> $Logfile 2>&1


EchoTee "Create Google maps image per areas"

#Create all image from Googlemaps data
# find ${W_TS}/TS_sorted_maps -type f -name "*AmpliZoom.jpg" -delete
#cp ${WebSite_Doc}/terrain.tif $W_TS/ >> $Logfile 2>&1
#$W_Script_Path/ZoneMaker_2.0.sh $W_TS/terrain.tif $W_TS TS_sorted_maps 5 >> $Logfile 2>&1
#rm $W_TS/terrain.tif

EchoTee "Create Google sat image per areas"

# Create all image from Googlesatview data
# find ${W_TS}/TS_sorted_satview -type f -name "*AmpliZoom.jpg" -delete
#cp ${WebSite_Doc}/satview.tif $W_TS/ >> $Logfile 2>&1
#$W_Script_Path/ZoneMaker_2.0.sh $W_TS/satview.tif $W_TS TS_sorted_satview 5 >> $Logfile 2>&1
#rm $W_TS/satview.tif




EchoTee "-------------------------Read Last date on HP server-------------------------------------"


now=$(date +"%Y/%m/%d %H:%M:%S")
echo "Last web page synchronisation: $now" > $W_TS/Last_Date.txt 


# Read last date of points for the NS_EW differential displacement calculation
tag="Ascending"
$W_Script_Path/TS_ReadLastPoint.sh ${A_18_dir} $tag $W_TS/Last_Date.txt  >> $Logfile 2>&1

tag="Descending"
$W_Script_Path/TS_ReadLastPoint.sh ${D_83_dir} $tag $W_TS/Last_Date.txt >> $Logfile 2>&1




EchoTee " -------------------------Read the last modification time on downloaded file------------------"


files=$(ls -t $W_A_18_Amplitude | grep deg$ | head -n 1)
echo $(date -r ${W_A_18_Amplitude}/${files} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/A_Ampli_lastfile_time.txt

files=$(ls -t $W_D_83_Amplitude | grep deg$ | head -n 1)
echo $(date -r ${W_D_83_Amplitude}/${files} "+%Y-%m-%d %H:%M:%S") > $WebSite/xTimeData/D_Ampli_lastfile_time.txt



EchoTee " -------------------------Create KMz file------------------"

MLR="MSBAS_LINEAR_RATE"
$W_Script_Path/KMzCreator.sh $W_Defo_Mask/UD_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_UD.bin >> $Logfile 2>&1
$W_Script_Path/KMzCreator.sh $W_Defo_Mask/EW_Defo_bin_Mask ${W_GD_EW_UD}/${MLR}_EW.bin >> $Logfile 2>&1
$W_Script_Path/KMzCreator.sh $W_Defo_Mask/LOS_Asc_Defo_bin_Mask ${W_GD_Asc}/${MLR}_LOS_Asc.bin >> $Logfile 2>&1
$W_Script_Path/KMzCreator.sh $W_Defo_Mask/LOS_Desc_Defo_bin_Mask ${W_GD_Desc}/${MLR}_LOS_Desc.bin >> $Logfile 2>&1


EchoTee " -------------------------Find and display last pair------------------"




EchoTee "Last pair in orbit Ascending"
#define common variable for both orbit
Last_Pair_Dir="${WebSite}/Amp_Coh_Defo/Last_Pair_A_18"
#Delete current file in destination folder
find ${Last_Pair_Dir} -maxdepth 1 -type f -delete

#Define Path variables for orbit ascending
Interf_dir="${A_18_dir}/Geocoded/InterfResid"
Coh_dir="${A_18_dir}/Geocoded/Coh"

#Build interfero for ascending
for i in `seq 1 3`
do
	LASTSLV=`find ${A_18_dir} -maxdepth 1 -name "S1*" -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f 17 | sort | uniq | tail -$i | head -1`
	LASTMAS=`find ${A_18_dir} -maxdepth 1 -name "*${LASTSLV}_A" -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f13-17 | sort | tail -1 | cut -d _ -f 1`
	COHMAP=`find ${Coh_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*deg" -type f`
	COHMAP_hdr=`find ${Coh_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*hdr" -type f`
	INTERFMAP=`find ${Interf_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*deg" -type f`
	INTERFMAP_hdr=`find ${Interf_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*hdr" -type f`
	#EchoTee "i = $i  -- Pair $LASTSLV $LASTMAS"
	if [ ! -d ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV} ]
		then 
			EchoTee "i = $i  -- Pair $LASTSLV $LASTMAS"
			#Find last amplitude raw file and copy it in the working directory. (and the hdr file also)
			Last_Amplitude_A_18=$(find ${W_A_18_Amplitude} -type f -name "A_18_Amplitude_Average")
			cp ${Last_Amplitude_A_18} ${Last_Pair_Dir}
			cp ${Last_Amplitude_A_18}.hdr ${Last_Pair_Dir}
			Last_Amplitude_A_18=$(find ${Last_Pair_Dir} -type f -name "A_18_Amplitude_Average")
			mkdir ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}	#Create directory for this pair
			cp ${COHMAP} ${Last_Pair_Dir}
			cp ${COHMAP_hdr} ${Last_Pair_Dir}
			cp ${INTERFMAP} ${Last_Pair_Dir}
			cp ${INTERFMAP_hdr} ${Last_Pair_Dir}
			COHMAP=${Last_Pair_Dir}/$(basename ${COHMAP})
			INTERFMAP=${Last_Pair_Dir}/$(basename ${INTERFMAP})

			$W_Script_Path/Fiji_RawToJpeg.sh ${Last_Amplitude_A_18} ${COHMAP} ${INTERFMAP} Interf_${LASTMAS}_${LASTSLV} >> $Logfile 2>&1
			cp ${Last_Pair_Dir}/Interf_${LASTMAS}_${LASTSLV}.png ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
			cp ${Last_Pair_Dir}/temp1.txt ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
			cp ${Last_Pair_Dir}/CohMap_${LASTMAS}_${LASTSLV}.png ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
			find ${Last_Pair_Dir} -maxdepth 1 -type f -delete
		fi
done

# Keep only the 3 last interfero and coherence
N=$(find ${Last_Pair_Dir} -type d | wc -l)
if [[ $N -gt 4 ]]
	then
		echo "N = $N"
		LastDate=`find ${Last_Pair_Dir} -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f 7 | sort | tail -4 | head -1`
		echo $LastDate
		find ${Last_Pair_Dir} -type d -name "*_${LastDate}" -exec rm -r "{}" \;
		echo $filetodelete
fi

EchoTee "---------------------------------Last pair in orbit Descending"



#define common variable for both orbit
Last_Pair_Dir="${WebSite}/Amp_Coh_Defo/Last_Pair_D_83"
#Delete current file in destination folder
find ${Last_Pair_Dir} -maxdepth 1 -type f -delete

#Define Path variables for orbit descending
Interf_dir="${D_83_dir}/Geocoded/InterfResid"
Coh_dir="${D_83_dir}/Geocoded/Coh"



#Build interfero for descending
for i in `seq 1 3`
do
	LASTSLV=`find ${D_83_dir} -maxdepth 1 -name "S1*" -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f 17 | sort | uniq | tail -$i | head -1`
	LASTMAS=`find ${D_83_dir} -maxdepth 1 -name "*${LASTSLV}_D" -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f13-17 | sort | tail -1 | cut -d _ -f 1`
	COHMAP=`find ${Coh_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*deg" -type f`
	COHMAP_hdr=`find ${Coh_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*hdr" -type f`
	INTERFMAP=`find ${Interf_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*deg" -type f`
	INTERFMAP_hdr=`find ${Interf_dir} -maxdepth 1 -name "*${LASTMAS}_${LASTSLV}*hdr" -type f`
	#EchoTee "i = $i  -- Pair $LASTSLV $LASTMAS"
	if [ ! -d ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV} ]
		then 
		EchoTee "i = $i  -- Pair $LASTSLV $LASTMAS"
		#Find last amplitude raw file
		Last_Amplitude_D_83=$(find ${W_D_83_Amplitude} -type f -name "D_83_Amplitude_Average")
		cp ${Last_Amplitude_D_83} ${Last_Pair_Dir}
		cp ${Last_Amplitude_D_83}.hdr ${Last_Pair_Dir}
		Last_Amplitude_D_83=$(find ${Last_Pair_Dir} -type f -name "D_83_Amplitude_Average")
		mkdir ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}	#Create directory for this pair
		cp ${COHMAP} ${Last_Pair_Dir}
		cp ${COHMAP_hdr} ${Last_Pair_Dir}
		cp ${INTERFMAP} ${Last_Pair_Dir}
		cp ${INTERFMAP_hdr} ${Last_Pair_Dir}
		COHMAP=${Last_Pair_Dir}/$(basename ${COHMAP})
		INTERFMAP=${Last_Pair_Dir}/$(basename ${INTERFMAP})

		$W_Script_Path/Fiji_RawToJpeg.sh ${Last_Amplitude_D_83} ${COHMAP} ${INTERFMAP} Interf_${LASTMAS}_${LASTSLV} >> $Logfile 2>&1
		cp ${Last_Pair_Dir}/Interf_${LASTMAS}_${LASTSLV}.png ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
		cp ${Last_Pair_Dir}/temp1.txt ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
		cp ${Last_Pair_Dir}/CohMap_${LASTMAS}_${LASTSLV}.png ${Last_Pair_Dir}/${LASTMAS}_${LASTSLV}
		find ${Last_Pair_Dir} -maxdepth 1 -type f -delete
	fi
done
# Keep only the 3 last interfero and coherence
N=$(find ${Last_Pair_Dir} -type d | wc -l)
if [[ $N -gt 4 ]]
	then
		echo "N = $N"
		LastDate=`find ${Last_Pair_Dir} -type d | ${PATHGNU}/gsed "s/.\///g" | cut -d _ -f 7 | sort | tail -4 | head -1`
		echo $LastDate
		find ${Last_Pair_Dir} -type d -name "*_${LastDate}" -exec rm -r "{}" \;
		echo $filetodelete
fi

EchoTee ""
EchoTee "		 -------------------------END-------------------------------------"
EchoTee ""


fi






