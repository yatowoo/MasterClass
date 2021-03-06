#! /bin/bash
launch_root() 
{
	export OPT=$1
	root -l GUI.cxx
	RETVAL=$?
	return $RETVAL; 
}
export MCDIR="MMMMMM"
export ROOTDIR="RRRRRR"
if [ -z "${ROOTSYS}" ]; then
	if [ -d $ROOTDIR ]; then 
		source $ROOTDIR/bin/thisroot.sh
	else
		echo "!!!! ERROR ROOTSYS is unset, install ROOT";
    	exit;
	fi
fi
DIRSAVE=`pwd`
LIBDIR=$MCDIR/library
echo $ROOTSYS $MCDIR
if [ -d "$LIBDIR" ]; then
	cd $LIBDIR
	make
    retVal=$?
 	if [ $retVal -ne 0 ]; then
    	echo "Compilation Error!"
		cd ..
		exit $retVal
	fi
	cd ..
else
	echo "!!!! ERROR: $LIBDIR not found!"
	cd $DIRSAVE
	exit 1
fi 
SAVE=$LD_LIBRARY_PATH
CPATH=`pwd`	
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CPATH/library
RETVAL=1;
while [ $RETVAL -ne 0 ]; do  
	launch_root $RETVAL
	RETVAL=$?
done
export LD_LIBRARY_PATH=$SAVE
cd $DIRSAVE
