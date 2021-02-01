#!/usr/bin/env python
# -*-coding:Latin-1 -*
#import struct
import sys
import os
import numpy as np
import fnmatch

#Check argument number 

if len(sys.argv) != 3:
	print("Issue occured when Running python script... bad argument number")
	
#Variable definition for the treatment of amplitude files

directory = sys.argv[1]
print(directory)
output = sys.argv[2]
print(output)
i=0;
B2=0;

for images in os.listdir(directory):   #Loop in directory folder
	if fnmatch.fnmatch(images, '*deg'):   #Check if filename end by *deg
		print(images)
		print('above the image file for amplitude')
		os.chdir(directory)			#Directory where we are going to work on
		B1 = np.fromfile(images, dtype='float32')   #Read files as an array of float
		B1 = np.log10(B1)
		B2 = B2 + B1					#Addition all array
		i = i + 1
		

print('ending addition amplitude ... number of treated file = ')
print(i)
B2 = B2/i;					#Divide by number of file to have the average
print('ending division amplitude...')
dest = open(output, "wb")	# Open a binary writable file
dest.write(B2)    #Write in this file the array
dest.close()		# Close the file
