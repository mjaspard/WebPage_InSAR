#!/usr/bin/env python
# -*-coding:Utf-8 -*
#Comments: This script is called by Link.sh to check if pair of points choose by web user are coherent in ascending and descending orbit.
#	Arguments:
#		- Argument 14  = Coordinates of 2 points
#		- Argument 5 = Number of pixels in a row (must be adapted to region)
#		- Argument 6 =  Binary file mask ascending
#		- Argument 7 =  Binary file mask descending
#		- Argument 8 =  Output file with results
#		Action:
#			- Convert coordinates in integer.
#			- Calculate the pixel number in the with X and Y coordinate.
#			- Extract pixel value of both points in ascending and descending mask.
#			- Write the value in output folder. 
#
#####################################################################################
#import struct


import sys
import os
import numpy as np
import fnmatch

#Check argument number 

if len(sys.argv) != 9:
	print("Issue occured when Running python script... bad argument number")
	
#Variable definition for the treatment of amplitude files

X1 = sys.argv[1]
Y1 = sys.argv[2]
X2 = sys.argv[3]
Y2 = sys.argv[4]
Row = sys.argv[5]	
MaskAsc = sys.argv[6]	# Binary mask file
MaskDesc = sys.argv[7]	# Binary mask file
Results = sys.argv[8]	#output file

X1 = int(X1)
Y1 = int(Y1)
X2 = int(X2)
Y2 = int(Y2)
Row = int(Row)

Array_MaskAsc = np.fromfile(MaskAsc, dtype='float32')   #Read files as an array of float
Array_MaskDesc = np.fromfile(MaskDesc, dtype='float32')   #Read files as an array of float

PixNum= (Y1*Row)+X1
A1 = str(Array_MaskAsc.item(PixNum))

PixNum= (Y2*Row)+X2
B1 = str(Array_MaskAsc.item(PixNum))

PixNum= (Y1*Row)+X1
A2 = str(Array_MaskDesc.item(PixNum))

PixNum= (Y2*Row)+X2
B2 = str(Array_MaskDesc.item(PixNum))


dest = open(Results, "w+") 	# Open a binary writable file
# print(A1,B1,A2,B2, file = dest)
dest.write("Ascending coherence: Pt A_B: _"+A1+"_"+B1)
dest.write("\n")
dest.write("Descending coherence: Pt A_B: _"+A2+"_"+B2)
dest.close()


