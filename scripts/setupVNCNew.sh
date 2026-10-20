#!/bin/bash

echo "Configuring VNC on `hostname`"
#VNC stuff
VNCNUM=`id -u $USER`
#VNCNUM=59539
if [ "$VNCNUM" -gt "59535" ];
then
  VNCNUM="$(($VNCNUM-59525))"
fi
if [[ `hostname` == *"gpvm"* ]] #only start VNC servers on the gpvms (i.e. not on the build machines)
then
#  export DISPLAY=localhost:$VNCNUM #Export the display to point to the VNC server
  export DISPLAY=":$VNCNUM" #Export the display to point to the VNC server
  if [ `lsof -i -P -n | grep $(expr 5900 + ${VNCNUM}) | wc -l` -eq 0 -o `lsof -i -P -n | grep $(expr 6000 + ${VNCNUM}) | wc -l` -eq 0 ] 
  then
    echo "vncserver :$VNCNUM not running.  Starting now...."
    vncserver :$VNCNUM -localhost -bs    #Check if the VNC server is running and start it if not (-localhost mandatory!)
  else
    echo "vncserver :$VNCNUM already running (hopefully owned by you).  Not attempting to start the vncserver..."
  fi
fi
SSHPORT=$(expr 5900 + ${VNCNUM})
SHORTENDEDHOSTNAME=`hostname | cut -d"." -f1`
SHORTENDEDHOSTNAMENONUMBER=`hostname | cut -d"." -f1 | grep -o '^[^[:digit:]]*'`
echo DISPLAY is set to $DISPLAY
echo the port needing forwarding with ssh is $SSHPORT
echo "the shortened hostname (for ssh'ing with) is $SHORTENDEDHOSTNAME"

printf "\nIf this is the first time running setupVNC.sh then you need to do some extra steps\n\n"
printf "Step 1) Copy the following text into your local (e.g. laptop's) \$HOME/.ssh/config.  If the config file does not exist, create it..  Do -NOT- copy this into the ${SHORTENDEDHOSTNAMENONUMBER}'s .ssh/config\n"
echo "#------------------------------------------"
echo "Host ${SHORTENDEDHOSTNAMENONUMBER}??"
echo "  HostName %h.fnal.gov"
echo "  User $USER"
echo "  ForwardAgent yes"
echo "  ForwardX11 yes"
echo "  ForwardX11Trusted yes"
echo "  GSSAPIAuthentication yes"
echo "  GSSAPIDelegateCredentials yes"
echo "  LocalForward 5901 localhost:$SSHPORT"
echo "#------------------------------------------"
printf "\nStep 2) Close this ssh connection.  Reconnect using \"ssh $SHORTENDEDHOSTNAME\" (and -NOT- \"ssh `hostname`\")"
printf "\nStep 3) Run (source) this script again"
printf "\nStep 4) Open your vnc client on your localmachine (e.g. laptop) and point it towards 'localhost:5901'.  On a mac, run 'open vnc://localhost:5901' in a new terminal window"
printf "\nNOTE - RELEVANT FOR SL7 CONTAINERS: source the script again once inside the container.  This is needed to export the DISPLAY environment variable\n"

