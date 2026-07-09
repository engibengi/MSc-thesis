set -e

if [ $# -ne 1 ];
then 
	echo "ERROR: wrong amount of parameters, the call syntax for this script is: ./run.sh compiled.elf" 1>&2
	exit 1
fi

COMPILED=$1

# Run code on simulator
/opt/snitch-rtl/bin/snitch_cluster.vlt $COMPILED