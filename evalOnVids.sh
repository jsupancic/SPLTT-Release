#!/bin/bash -x

FUNC=$1
INIT=$2

echo "starting evaluation..."
VIDS=$(ls ~/workspace/data)
SUITE='coke11 david motocross tiger2 girl panda pedestrian1 sylv tiger1 volkswagen faceocc faceocc2'
#SUITE='panda'
MATLAB=matlab
SERIAL='0'

# configure our X server
# Xnest still crashes randomly :-(
#nohup Xnest :1 -geometry 1280x1024 &
#export DISPLAY=:1
#wmaker &

# compile shared components
# 
# clear existing jobs
# $MATLAB -nodesktop -r "matlabpool close force; "
# compile the shared components.
# -nodisplay?
$MATLAB -nodesktop -r "addpath(genpath('.'),'-END'); cluster_ctl('killall'); compile; exit;"

# test the vids
#for VID in 'volkswagen'
#for VID in $VIDS
for VID in $SUITE
do
    ID="$FUNC-$VID-$(date +%Y%m%d)"

    if [ $SERIAL == 1 ]
    then
	SETUP="$INIT addpath(genpath('.')); cluster_ctl('on'); vidName='$VID';"
    else
	SETUP="$INIT addpath(genpath('.')); vidName='$VID';"
    fi
    RUN="track = $FUNC(vidName);"
    FINISH="save([cfg('tmp_dir') 'track_$ID.mat'],'vidName','track'); "
    F1FILE="[cfg('tmp_dir') 'f1=' num2str(f1) '_$ID.mat']"
    CMP_F1="f1 = score_track_file(vidName,track); save($F1FILE,'f1');"
    PROG="$SETUP $RUN $FINISH $CMP_F1 cluster_ctl('off'); exit;"
    echo $PROG
    #$MATLAB -nosplash -nodesktop -r '$PROG'
    screen -d -m -S $FUNC$VID nice -n 10 $MATLAB -nodisplay -nosplash -nodesktop -r "$PROG"
    sleep 5
    #screen -d -m -S $FUNC$VID $MATLAB -nodesktop -r "$FUNC('$VID');"
done

# restore the terimanl...
reset
