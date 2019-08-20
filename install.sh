#!/bin/bash
CheckSystemTools()
{
    wget -h > /dev/null 2>&1
    if [ $? -eq 127 ]; then 
        echo "MISSING wget on your system"
        MWGET=1
    else 
        MWGET=0
    fi

    gcc  > /dev/null 2>&1
    if [ $? -eq 127 ]; then 
        echo "MISSING gcc on your system"
        MGCC=1
    else 
        MGCC=0
    fi

    git  > /dev/null 2>&1
    if [ $? -eq 127 ]; then 
        echo "MISSING git on your system"
        MGIT=1
    else 
        MGIT=0
    fi

    tar  > /dev/null 2>&1
    if [ $? -eq 127 ]; then 
        echo "MISSING tar on your system"
        MTAR=1
    else 
        MTAR=0
    fi

    if [ ! -d $ROOTDIR ] && [ -z "${ROOTSYS}" ]; then 
        echo "MISSING ROOT installation"
        MROOT=1
    else
        MROOT=0
    fi

    if [ ! -d $MCDIR ]; then 
        echo "MISSING MasterClass installation"
        MMC=1
    else
        MMC=0
    fi

    local os=`uname`
    if [ "$OS" = "Linux" ]; then 
        lsb_release -i > /dev/null 2>&1
        if [ $? -eq 127 ]; then 
            echo "MISSING lsb_release on your system"
            MLSB=1
        else 
            MLSB=0
        fi
    fi 
    if [ $MWGET -eq 1 -o $MGCC -eq 1 -o $MGIT -eq 1 -o $MTAR -eq 1 ]; then 
        exit
    fi  
}
GetOSName2()
{
    OS=`uname`
    if [ "$OS" = "Linux" ]; then
        local dis=`lsb_release -i`
        OS=`echo ${dis#*:}`
        local ver=`lsb_release -r`
        ver=${ver#*:}
        ver=${ver%.*}
        OS=`echo $OS$ver gcc`
        local gccv=`gcc -dumpversion`
        gccv=${gccv%.*}
        OS=`echo $OS$gccv`
    elif [ "$OS" == "Darwin" ]; then 
        OS=OsX
        OS=$OS" "`sw_vers -productVersion`
        OS=${OS%.*}
    else 
        echo "!!!! ERROR: no root distribution for OS = $OS"      
        exit
    fi
}
GetOSName()
{
    OS=`uname`
    if [ "$OS" = "Linux" ]; then
        if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
            . /etc/os-release
            OS=$NAME
            local ver=$VERSION_ID
            OS=`echo $OS$ver gcc`
        elif type lsb_release >/dev/null 2>&1; then
            # linuxbase.org
            OS=$(lsb_release -si)
            local ver=$(lsb_release -sr)
            OS=`echo $OS$ver gcc`
        elif [ -f /etc/lsb-release ]; then
            # For some versions of Debian/Ubuntu without lsb_release command
            . /etc/lsb-release
            OS=$DISTRIB_ID
            local ver=$DISTRIB_RELEASE
            OS=`echo $OS$ver gcc`
        elif [ -f /etc/debian_version ]; then
            # Older Debian/Ubuntu/etc.
            OS=Debian
            local ver=$(cat /etc/debian_version)
            OS=`echo $OS$ver gcc`
        fi
    elif [ "$OS" == "Darwin" ]; then 
        OS=OsX
        OS=$OS" "`sw_vers -productVersion`
        OS=${OS%.*}
    else 
        echo "!!!! ERROR: no root distribution for OS = $OS"      
        exit
    fi
}
InstallRoot()
{
    GetOSName
    cd $INSTALDIR
    case $OS in 
        "OsX 10.14")
        root=root_v6.18.00.macosx64-10.14-clang100.tar.gz
        ;;
        "OsX 10.13")
        root=root_v6.18.00.macosx64-10.13-clang100.tar.gz
        ;;
        "Ubuntu 18 gcc7")
        root=root_v6.18.00.Linux-ubuntu18-x86_64-gcc7.4.tar.gz 
        ;;
        "Ubuntu 16 gcc5")
        root=root_v6.18.00.Linux-ubuntu16-x86_64-gcc5.4.tar.gz
        ;;
        "Ubuntu 14 gcc4")
        root=root_v6.18.00.Linux-ubuntu14-x86_64-gcc4.8.tar.gz
        ;;
        "Scientific 7 gcc4.8")
        root=root_v6.18.00.Linux-centos7-x86_64-gcc4.8.tar.gz
        ;;
        "Fedora 30 gcc9")
        root=root_v6.18.00.Linux-fedora30-x86_64-gcc9.1.tar.gz
        ;;
        "Fedora 29 gcc8")
        root=root_v6.18.00.Linux-fedora29-x86_64-gcc8.3.tar.gz
        ;;
        *) 
        echo "not binary root distribution for $OS; check here https://root.cern.ch/content/release-61800"
        exit
    esac
        wget https://root.cern/download/$root
        tar -zxvf $root
        rm $root
        source $INSTALDIR/root/bin/thisroot.sh
        echo "*****************************"
        echo root is installed at $ROOTSYS
        echo "*****************************"
}
SAVEDIR=`pwd`
if [ "$#" -eq 1 ]; then 
    INSTALDIR=$1
else 
    INSTALDIR=$HOME/MC
fi
export MCDIR=$INSTALDIR/MasterClass
export ROOTDIR=$INSTALDIR/root
CheckSystemTools
#Check if INSTALDIR exists 
if [ ! -d $INSTALDIR ]; then 
    mkdir -p $INSTALDIR
fi    
cd $INSTALDIR 
if [ $MROOT -eq 1 ]; then 
    InstallRoot
fi    
if [ $MMC -eq 1 ]; then 
#download source code from github into $HOME/MasterClass 
    git clone https://github.com/yschutz/MasterClass.git
else 
#update the existing version
    cd $MCDIR
    git pull
fi
#download the data if needed
if [ ! -d $MCDIR/Data-Masterclass/events ]; then 
    cd $MCDIR/Data-Masterclass
    wget http://alice-project-masterclass-data.web.cern.ch/alice-project-masterclass-data/events.tgz
    tar -zxvf events.tgz
    rm events.tgz
fi
#compile and link
cd $MCDIR 
LIBDIR=$MCDIR/library
if [ -d "$LIBDIR" ]; then
	cd $LIBDIR
	make
    retVal=$?
 	if [ $retVal -ne 0 ]; then
    	echo "!!!! Compilation Error !!!"
		cd $MCDIR
		exit $retVal
	fi
    echo $MCDIR
	cd $MCDIR
else
	echo "!!!! ERROR: $LIBDIR not found"
	exit 1
fi 
echo "************************************************************"
echo "Installation completed .... "
echo "To start the exercises: $MCDIR/MasterClassStart.sh"
echo "************************************************************"
cd $SAVEDIR
