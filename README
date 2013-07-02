To actually get this beast to run on your computer, you'll probably have to 
edit some of the matlab files in the config/ subdirectory.
(1) config/datapath.m should return the path where you have your videos stored.
    The path should point to a directory which includes a subdirectory for each video.
    E.g. $(datapath)/tiger2/.
    Each subdirectory should contain files with ground truth labelings and images similar
    to what MIL-Track uses. 
    As an example, see my track-data.zip file. 
(2) cluster_ctl is called like so cluster_ctl('on',...) or cluster_ctl('off',...)
    to enable or disable the matlab pool. I have three pools, with different characteristics,
    available to me so this function, heuristically, selects the best one. Depending on what 
    type of MATLAB pools you have, you'll need to rewrite this function. The simplest option
    would be to call "matlabpool open" when called with "on" and "matlabpool close" when 
    called with "off". 
(3) You should be able to compile by simplying calling "compile.m". I've tested this on Linux
    and it should work on other OSs... I welcome patches. 
(4) config/cfg.m : lets you stitch many of the parameters of the tracker. Of particular
    interest will be the option 'tmp_dir'. You'll want to point this to an empty directory
    which is writable. It is used for caching results. 

Then, you "should" be able to run it with a command similar to the following:
      addpath(genpath('.')); matlab_init('coke11'); track = track_online('coke11');

Alternatively, you might just use track_tbd('coke11'); which doesn't do any learning (after
  the first frame) or use a motion model. It is much faster and still performs quite well. 

