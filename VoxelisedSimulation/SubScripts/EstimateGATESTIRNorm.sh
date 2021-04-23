## #! /bin/sh
## AUTHOR: Robert Twyman
## AUTHOR: Kris Thielemans
## Copyright (C) 2020, 2021 University College London
## Licensed under the Apache License, Version 2.0

## Script is used to compute the normalisation factors for GATE data reconstruction.
## The current standard to do this is to forward project, in STIR and GATE (run simulations), a cylindrical activity, the size of the scanner FOV, without attenuation.
## The MeasuredData (sinogram) is obtained by unlisting the GATE output with the exclusion of randoms and scatter.

## This script forward projects the same activity cylinder in SITR to obtain model_data. 
## The script use find_ML_normfactors3D and apply_normfactors3D to compute the efficiency factors. 
## See find_ML_normfactors3D and apply_normfactors3D for more information.

## Due to algorithm limitations with find_ML_normfactors3D and apply_normfactors3D, the computation of the efficiency factors must be done with span-1 data.
## In many instances, this is not the datatype measured on the scanner, but for this script MeasuredData should be span-1.
## To obtain the normalisation sinogram in a different format, provide a norm_template. 
## This script will SSRB the efficiency factors into the shape of norm_template before inverting to provide the correct sinogram shaped normalisation sinogram.

if [ $# -lt 3 ]; then
	echo "Usage: EstimateGATESTIRNorm.sh OutputFilename MeasuredData FOVCylindricalActivityVolumeFilename [ norm_template ]"
	exit 1
fi 

set -e # exit on error
trap "echo ERROR in $0" ERR

OutputFilename=$1
MeasuredData=$2
FOVCylindricalActivityVolumeFilename=$3

if [ $# -ge 4 ]; then
	## Optional template norm
	norm_template=$4
else
	norm_template=0
fi

## Parameter file to use for STIR forward projection
forward_project_pars=${SGCPATH}/VoxelisedSimulation/SubScripts/forward_projector_proj_matrix_ray_tracing.par

## ML Normfactors loop numbers (Hardcoded for now)
outer_iters=5
eff_iters=6

## factors are the norm_filename_prefix generated by find_ML_normfactors3D and input for apply_normfactors3D
norm_factors="norm_factors"
eff_factors="eff_factors"

## Create the STIR (model) forward projection of the object.
model_data=STIR_forward


## Forward project using SITR to get model data
echo "Forward projecting (${FOVCylindricalActivityVolumeFilename}) with STIR to get model_data"
forward_project ${model_data} ${FOVCylindricalActivityVolumeFilename} ${MeasuredData} ${forward_project_pars} > /dev/null 2>&1
echo "stir_math is creating sinogram of ones."
stir_math -s --including-first --times-scalar 0 --add-scalar 1 ones.hs ${model_data}".hs"


## find ML normfactors
echo "Running STIR's find_ML_normfactors3D"
find_ML_normfactors3D ${norm_factors} ${MeasuredData} ${model_data}".hs" ${outer_iters} ${eff_iters}


## mutiply ones with the norm factors to get a sino
echo "Running STIR's apply_normfactors3D"
## This executable can error with `ERROR: Cannot do geometric factors in 3D yet`. This is likely due to being on the `release_4` branch of STIR
apply_normfactors3D ${eff_factors}"_span1" ${norm_factors} ones.hs 1 ${outer_iters} ${eff_iters}


## Creates the span-1 normalisation sinogram
echo "Inverting the eff_factors (span-1) to get a normalisation sinogram (span-1)"
stir_math -s --including-first --power -1 ${OutputFilename}"_span1" ${eff_factors}"_span1.hs"


## Creates the span-n normalisation sinogram if $span > 1
if [ ${norm_template} != 0 ]; then
	echo "SSRB the eff_factors_span1 to match the dimentions of '${norm_template}'"
	SSRB --template ${norm_template} ${eff_factors} ${eff_factors}"_span1.hs" 0
	stir_math -s --including-first --power -1 ${OutputFilename} ${eff_factors}".hs"
	echo "Compressed Normalisation sinogram is saved as: ${OutputFilename}"
else
	## No template given, rename the ${OutputFilename}"_span1.hs" to ${OutputFilename}
	stir_math -s ${OutputFilename} ${OutputFilename}"_span1.hs"
	echo "Normalisation sinogram is saved as: ${OutputFilename}"
fi

cleanup=1
if [ ${cleanup} == 1 ]; then
	echo "Cleaning up!"
	rm ${norm_factors}*
	for suffix in ".hs" ".s"; do
		rm "ones"${suffix}
		rm ${eff_factors}"_span1"${suffix}
		rm ${model_data}${suffix}
		if [ ${norm_template} == 0 ]; then
			echo "No norm_template so ${OutputFilename}_span1 and ${OutputFilename} are equal"
			rm ${OutputFilename}"_span1"${suffix}
		fi
	done
fi

exit 0
