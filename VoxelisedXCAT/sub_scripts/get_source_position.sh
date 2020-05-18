#! /bin/sh
## AUTHOR: Robert Twyman
## Script used to automatically gather GATE x,y,z source position from image interfile header.
## Script echo (returns) x y z variables.

ImageFilename=$1

if [ $# -ne 1 ]; then
  echo "Usage:"$0 "ImageFilename" 1>&2
  exit 1
fi

FirstEdges=`list_image_info $ImageFilename| awk -F: '/Physical coordinate of first edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $1, $2, $3}'` 1>&2
LastEdges=`list_image_info $ImageFilename| awk -F: '/Physical coordinate of last edge in mm/ {print $2}'|tr -d '{}'|awk -F, '{print $1, $2, $3}'` 1>&2

## Compute x,y
SourcePositionX=$(echo "$FirstEdges" | awk '{print $3}')
SourcePositionY=$(echo "$FirstEdges" | awk '{print $2}')

## Compute z = -(lz-fz)/2
FirstEdgeZ=$(echo "$FirstEdges" | awk '{print $1}')
LastEdgeZ=$(echo "$LastEdges" | awk '{print $1}')
SourcePositionZ=$(echo "$FirstEdgeZ $LastEdgeZ" | awk '{print -($2-$1)/2}')

## Used for return.
echo $SourcePositionX $SourcePositionY $SourcePositionZ
