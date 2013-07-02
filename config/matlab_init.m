% JSS3 2012-5-15
% function to configure MATLAB for my code to run.
function [model,Jpos,C] = matlab_init(vidName)    
    % don't re-initialize unless we are just starting up or
    % switching  videos.
    global G_VID_NAME;
    if strcmp(G_VID_NAME,vidName) && nargout < 1
        % already initialized
        return;
    end
    G_VID_NAME = vidName;
    
    global G_HOME;
    G_HOME = getenv('HOME')
    
    % model details...
    global ORI_BINS;
    ORI_BINS = 18;
    
    %  where to save stuff?
    global G_LOG_PREFIX;
    G_LOG_PREFIX = [cfg('tmp_dir') date() num2str(now()) ...
                   '-' vidName '-'];
    
    % compile?
    compile();
    
    % clear the display
    format compact;
    %close all;
    lk(0);
    % the code uses a random number generator in qp_one.m
    % it is important that results be reproducible.
    if exist('rng') == 2
        rng(09221986,'twister');
    else 
        rand('seed',09221986);
    end
    if hasDisplay()
        % configure the image processing toolbox    
        iptsetpref('ImshowInitialMagnification', 'fit');
        % Don't open to many windows...
        set(0,'DefaultFigureWindowStyle','docked');
    end
    % configure the paths
    setpath();
    % protect against crashes without explanation...
    dbstop if error;
        
    % (a) Initialize model
    % (b) Train linear SVM with dual coordinate descent
    % (c) Run model on test images
    if nargout >= 1
        [model,Jpos,C] = genModel(vidName,nan);
    end
end
