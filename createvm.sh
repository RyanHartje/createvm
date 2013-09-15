#!/bin/sh
#
# Written by Ryan Hartje
# ryanhartje.com
# 
# This script should accept the following arguments:
# $ createvm.sh [name] [CPUs] [RAM] [HDD size] [SSD size] 
# RAM in MB, all others in GB
# 
# The next version will include [Distribution]
#

# Configure log file here:
log="/var/log/createvmlog";

# Configure ISO folder here: # This feature not yet functional
# isoFolder="/vmfs/volumes/datastore1/ISO/";

# Create a greeting so that the script output can be seen from shell
echo;
echo "--------------------------------------------------";

if [ -z "$1" ];
then 
  echo "createvm [name] [CPUs] [RAM] [HDD size] [SSD size]";
else

echo "creating $1"
echo "$2 - CPUs / $3 GB Ram"
echo "$4GB HDD / $5GB SSD";

# Distro disabled until future version
#echo "Distro: $6";

echo "--------------------------------------------------";
echo; 
echo "$(date) Creating VM Environment for $1" >> $log;

# The first step should be to ensure our enviroment can support the addition of another unit
# Setup the folders and create disks
mkdir /vmfs/volumes/datastore1/$1
mkdir /vmfs/volumes/SSD/$1

echo "$(date) Checking Disk space";
echo;

hddUuid=$(ls -ahl /vmfs/volumes/|grep datastore1|awk '{print $11}');
hddSpace=$(df -h|grep $hddUuid|awk '{print $4}');
echo "Harddrive Uuid: $hddUuid";
echo "Harddrive Space: $hddSpace GB";

ssdUuid=$(ls -ahl /vmfs/volumes/|grep SSD|awk '{print $11}');
ssdSpace=$(df -h|grep $ssdUuid|awk '{print $4}');
echo "SSD Uuid: $ssdUuid";
echo "SSD Space: $ssdSpace GB";
echo ;

if [ $hddSpace -lt $4 ] ;
then
  echo "Not enough Disk space for the request";
  echo "$(date) Not enough HDD space to create vm $1. Call to script: createvm.sh $1 $2 $3 $4 $5 $6 " >> $log;
  exit; 
fi

if [ $ssdSpace -lt $5 ] ;
then
  echo "Not enough SSD space for the request";
  echo "$(date) Not enough SSD space to create vm $1. Call to script: createvm.sh $1 $2 $3 $4 $5 $6" >> $log;
  exit;
fi  

echo "$(date) Drive check complete, building new drives";
echo "$(date) Drive check complete, building new drives" >> $log;

# make sure we don't create empty drives

if [ $4 -gt 0 ] ;
then 
vmkfstools -c $4G -a lsilogic /vmfs/volumes/datastore1/$1/$1.vmdk -d thin
echo "$(date) HDD created - $4GB";
echo "$(date) HDD created - $4GB" >> $log;
fi

if [ $5 -gt 0 ] ;
then 
vmkfstools -c $5G -a lsilogic /vmfs/volumes/SSD/$1/$1.vmdk -d thin
echo "$(date) SSD created - $5GB";
echo "$(date) SSD created - $5GB" >> $log;
fi

echo "$(date) Creating configuration file";


# A future release will include allow you to add a distribution if you choose. For now, we'll comment this part out. 

#echo;
#echo "Please select distribution:";
#num=0;
#for i in '/vmfs/volumes/datastore1/ISO/'
#do
#    echo "[$num] - $i"; $num++;
#done
#distro=read;

configFile="/vmfs/volumes/datastore1/$1/$1.vmx";

echo 'config.version = "8"' >> $configFile;
echo 'virtualHW.version = "7"' >> $configFile;
echo 'vmci0.present = "TRUE"' >> $configFile;
echo displayName = "$1" >> $configFile;
echo 'floppy0.present = "FALSE"' >> $configFile;
echo numvcpus = "$2" >> $configFile;
echo 'scsi0.present = "TRUE"' >> $configFile;
echo 'scsi0.sharedBus = "none"' >> $configFile;
echo 'scsi0.virtualDev = "lsilogic"' >> $configFile;
echo memsize = "$3" >> $configFile;
echo 'scsi0:0.present = "TRUE"' >> $configFile;
echo scsi0:0.fileName = "$1.vmdk" >> $configFile;
echo 'scsi0:0.deviceType = "scsi-hardDisk"' >> $configFile;
echo 'scsi0:1.present = "TRUE"' >> $configFile; 
echo scsi0:1.fileName = "/vmfs/volumes/SSD/$1/$1.vmdk" >> $configFile; 
echo 'scsi0:1.deviceType = "scsi-hardDisk"' >> $configFile;

# You may configure an ISO to load with the server here if you choose.
#echo 'ide1:0.present = "TRUE"' >> $configFile;
#echo ide1:0.fileName = "$isoFolder$6" >> $configFile;
#echo 'ide1:0.deviceType = "cdrom-image"' >> $configFile;

echo 'ethernet0.present = "TRUE"' >> $configFile;
echo 'ethernet0.virtualDev = "e1000"' >> $configFile;
echo 'ethernet0.features = "15"' >> $configFile;
echo 'ethernet0.networkName = "VM Network"' >> $configFile;
echo 'ethernet0.addressType = "generated"' >> $configFile;
echo 'guestOS = "freebsd-64"' >> $configFile;

# Let's register and power on the new Vm to auto provision using the disc

vnum=`vim-cmd solo/registervm /vmfs/volumes/datastore1/$1/$1.vmx`
#echo "$(date) Successfully created vm $1 and assigned to esxvmid: $vnum" >> $log;

vim-cmd vmsvc/power.on $vnum

fi
