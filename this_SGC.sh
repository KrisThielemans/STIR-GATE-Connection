# This file should be sourced, e.g. `source this_SGC.sh`

SGCPATH=$(cd "$(dirname "$0")"; pwd)/$(basename "$1")
SGCVoxelisedSimulation="${SGCPATH}/VoxelisedSimulation"
SGCDataCorrectionsComputation="${SGCPATH}/DataCorrectionsComputation"
SGCExampleReconstruction="${SGCPATH}/ExampleReconstruction"

export SGCPATH SGCVoxelisedSimulation SGCDataCorrectionsComputation SGCExampleReconstruction
export PATH=${SGCPATH}:${PATH}

echo " "
echo "SGCPATH enviromental variable is set as:"
echo "  ${SGCPATH}"
echo "and adding it to PATH."
echo " "
