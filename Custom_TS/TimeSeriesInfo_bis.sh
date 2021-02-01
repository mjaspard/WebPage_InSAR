#!/bin/zsh
#
#This script will perform the following action:
#		- Read the INPUT file and extract 2 coordinates present in the name of the file
#		- Mark with two cross this 2 points on the Apmlitude_Coherence_Deformation images
#		- Crop the images to have the points centered (Horiz and vertical)
#		- Resize this images 
#		-Insert this image in the Time series graphics.
#		- Insert also the both legend (color frame + interpretation)
#		- legend 1 must be in the same folder than argument2 with the name 'legend_xx.jpg' (xx= EW - UD - LOS_Asc LOS_Desc )
#		- legend 2 must be in a folder named 'Documents' 3 level higher than argument 2 file. 
#			-legend 2 file name must be = TS_Displ_xx.png for EW and UD and TS_Displ_LOS_xx.png for LOS (xx= Pos or Neg)
#		- Coordinates in the name of the eps file must be adapted to the resolution of the deformation image.
#
# Dependencies ghost-script should be install ( test by cmd: gs --version)
# 		- Brew Install ghostscript
#		- sudo chown -R `whoami` /usr/local/share/ghostscript
#		- brew link --overwrite ghostscript
# (Purpose is to avoid issue with convert command like ("error/convert.c/ConvertImageCommand/3273."))
#
#
#
#

#Read Arguments:

TimeLine=$1			# Argument 1 = eps file
AmpliCohDefo=$2		# Argument 1 = Deformation image in jpg with mandatory syntax 'AMPLI_COH_MSBAS_LINEAR_RATE_xx.jpg (xx= EW - UD - LOS_Asc LOS_Desc )
RequestId=$3

W_Documents_Path=$(echo $(dirname $(dirname $(dirname $(dirname ${AmpliCohDefo})))))/'Documents'
W_QGIS2WEB_Path=$(echo $(dirname $(dirname $(dirname ${TimeLine}))))
logo_master=${W_QGIS2WEB_Path}/logo_master.png
logo_ecgs=${W_QGIS2WEB_Path}/logo_ecgs.png

XXYY=$(echo `expr "$TimeLine" : '.*\(_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_[0-9][0-9][0-9]*_\)'`)   # Look for 4 consecutive coordinates of 3 digits each separate by "_"

echo $XXYY
for i in `seq 1 5`
do
array[$i]=$(echo $XXYY | cut -d '_' -f $i)		#Extract each coordinate in an array
done

X1=$((${array[2]} - 1000))	# Origin image is cropped at 1000 pixels from left and top
Y1=$((${array[3]} - 1000))
X2=$((${array[4]} - 1000))
Y2=$((${array[5]} - 1000))
echo "${array[*]}"

#Define the size of the crop LxH + posX + posY (posX and posY are the distance from the top left of the original image)

L=$((($X2-$X1)*2))	# Define the lengt of the crop
L=${L#-}			# Keep absolute value

H=$((($Y2-$Y1)*2))	# Define the lengt of the crop
H=${H#-}			# Keep absolute value

if [ $H -gt $L ]; then L=$H ; fi	#To have a standart square for each combination of points a and b
									# We will continue only with L value (size of the square side)
#Force a minimum size for this Square to avoid extra zoom for points very close to each other
	if [ $L -lt 100 ] 
		then 
		L=100
		XX=15
		else
		XX=30 
		fi

	posX=$(((($X1+$X2)/2)-($L/2)))	# Define  X position from top left
	if [ $posX -le 0 ]
		then 
			posX=0
	fi
	posY=$(((($Y1+$Y2)/2)-($L/2)))	# Define  Y position from top left
	if [ $posY -le 0 ]
		then 
			posY=0
	fi

# Crop the image to the calculate value
echo " L = $L ++ H= $H  ++ posX = $posX ++ posY = $posY "

# Define the resize rate depending on the size of the square. We want a constant square of 350 pixels.
Tx=$(echo "scale=2;(36000/$L)" |bc)
echo " Taux = $Tx"
TxR=$(echo "scale=2;($Tx/100)" | bc)
#TxR=`echo "scale=2;(Tx/100)" | bc`
echo " Taux en % = "$TxR



PathOutput=`echo $(dirname  $(dirname ${TimeLine}))`


crop=$(echo "${TimeLine//.eps/_crop.jpg}")  #Define the name of the crop file
convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
convert $crop -resize $Tx% $crop						#Resize the image to fit on the Time Series




# Define a new reference for the cross mark related to square (X-posX) the depending of the resize (X* resize ratio) (Size in pixels must be multiplicate by ratio)
NewX1=$(echo "scale=2;(($X1-$posX)*$TxR)" |bc)
NewX2=$(echo "scale=2;(($X2-$posX)*$TxR)" |bc)
NewY1=$(echo "scale=2;(($Y1-$posY)*$TxR)" |bc)
NewY2=$(echo "scale=2;(($Y2-$posY)*$TxR)" |bc)


NewX1=${NewX1%.*}
NewX2=${NewX2%.*}
NewY1=${NewY1%.*}
NewY2=${NewY2%.*}

 	X11=$((NewX1-XX))
	X12=$((NewX1+XX))
	X21=$((NewX2-XX))
	X22=$((NewX2+XX))
	Y11=$((NewY1-XX))
	Y12=$((NewY1+XX))
	Y21=$((NewY2-XX))
	Y22=$((NewY2+XX))
	
echo " NeuX1 = $NewX1"
echo " NeuX2 = $NewX2"
echo " NeuY1 = $NewY1"
echo " NeuY2 = $NewY2"

Echo " _X1 - _X2 - _Y1 - _Y2 -_X11 - _X12 - _X21 - _X22 -_Y11 - _Y12 - _Y21 - _Y22"
Echo " $X1 - $X2 - $Y1 - $Y2 - $X11 - $X12 - $X21 - $X22 - $Y11 - $Y12 - $Y21 - $Y22"

#crop=$(echo "${TimeLine//.jpg/_crop.jpg}")  #Define the name of the crop file
#touch $crop
echo "*************$crop**************"
convert $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
convert $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
convert $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
convert $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop


combi=$(echo "${TimeLine//.eps/_combi.jpg}")		# Add extension _combi to the name of final file
echo $combi
touch $combi
convert -size 3300x2200 xc:white -type TrueColor $combi

convert -density 300 -rotate 90 ${TimeLine} ${TimeLine}.jpg
convert $combi ${TimeLine}.jpg -gravity northwest -geometry +330+100 -composite $combi
convert $combi $crop -gravity northwest -geometry +30+300 -composite $combi


# Add Legend to the Time serie image
Legend=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE/Legend}")	# Create the name of the real file "legend"
					
# Add to the combi file the legend after having rescaled the legend to the size of the thumb (350 px = )
convert ${Legend} -resize 35% Temp
convert $combi Temp -gravity northwest -geometry +25+670 -composite $combi


if [ $(basename ${Legend}) = 'Legend_EW.jpg' ]
then
	convert $combi -pointsize 30 -draw "text 45,290 'East-West deformation'" $combi
	
		
 	Legend2=${W_Documents_Path}/TS_Displ_Pos.png #Image to explain the sens of displacement between cross
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+780 -composite $combi
		
	
	Legend2=${W_Documents_Path}/TS_Displ_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+1170 -composite $combi
	
	
	AmpliCohDefo=$(echo "${AmpliCohDefo//AMPLI_COH_MSBAS_LINEAR_RATE_EW/AMPLI_COH_MSBAS_LINEAR_RATE_UD}")
	Legend=$(echo "${Legend//_EW.jpg/_UD.jpg}")
	convert $AmpliCohDefo -crop ${L}x${L}+${posX}+${posY} $crop	#Crop the image
	convert $crop -resize $Tx% $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $X11,$NewY1 $X12,$NewY1" $crop   #Build cross on a duplicate images $crop
	convert $crop -draw "stroke white stroke-width 3.5 line $NewX1,$Y11 $NewX1,$Y12" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $X21,$NewY2 $X22,$NewY2" $crop	#Build cross on a duplicate images $crop
	convert $crop -draw "stroke yellow stroke-width 3.5 line $NewX2,$Y21 $NewX2,$Y22" $crop	#Build cross on a duplicate images $crop

	convert $combi -pointsize 30 -draw "text 45,1790 'Up-down deformation' decorate UnderLine" $combi
	convert $combi $crop -gravity northwest -geometry +30+1600 -composite $combi
	convert ${Legend} -resize 35% Temp
	convert $combi Temp -gravity northwest -geometry +25+1970 -composite $combi

	
	
	
	


elif [ $(basename ${Legend}) = 'Legend_LOS_Asc.jpg' ]
then
	convert $combi -pointsize 30 -draw "text 45,290 'LOS-Ascending deformation' decorate UnderLine" $combi

	Legend2=${W_Documents_Path}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+780 -composite $combi
		
	
	Legend2=${W_Documents_Path}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+1170 -composite $combi
	
elif [ $(basename ${Legend}) = 'Legend_LOS_Desc.jpg' ]
then
	convert $combi -pointsize 30 -draw "text 45,290 'LOS-Descending deformation' decorate UnderLine" $combi

	Legend2=${W_Documents_Path}/TS_Displ_LOS_Pos.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+730 -composite $combi
		
	
	Legend2=${W_Documents_Path}/TS_Displ_LOS_Neg.png
 	echo "${Legend2}"
	convert ${Legend2} -resize 45% Temp
	convert Temp -crop 714x750 Temp
	convert $combi Temp -gravity northwest -geometry +15+1120 -composite $combi
fi

# Add logo Master + logo ecgs + internet adresse 
convert ${logo_master} -resize 120% Temp
convert $combi Temp -gravity northwest -geometry +50+10 -composite $combi
convert ${logo_ecgs} -resize 90% Temp
convert $combi Temp -gravity northwest -geometry +2600+10 -composite $combi
convert $combi -fill grey -pointsize 50 -draw "text 1150,80 'WebSite: http://terra2.ecgs.lu/defo-domuyo" $combi



rm -f ${TimeLine}.jpg
rm -f $crop
mv $combi ${PathOutput}/zRequest/${RequestId}/


 