% JSS3 - 2012.6.15
% function to turn the cluster on or off.
% jobDesc: small, large, local (largest on one machine)
function on = cluster_ctl(option,jobDesc,cores)    
    % NOP on a worker...
    if ~isempty(getCurrentTask) || ~usejava('jvm')
        return
    end
    
    % default arguments
    if nargin < 2
        jobDesc = 'large';
    end
    if nargin < 3
        cores = inf;
    end    
    
    % get the distributed configuration    
    [cfg,size] = getCfg(jobDesc);
    
    % don't give the client more cores than it requested.
    size = min(size,cores);    
    if strcmp(option,'on')        
        on =  1;        
        ensureClosed();
        matlabpool(cfg,'open',size);
        % share the client's home directory with the workers...
        home = getenv('HOME');
        cmd_set_home = ['setenv(''HOME'',''' home ''')'];
        pctRunOnAll(cmd_set_home);
        % send the paths to the pool...
        %if ~strcmp(jobDesc,'small')
        %pctRunOnAll setpath(1);
        %end
        setpath(1);
    elseif strcmp(option,'off')
        ensureClosed();
        on = 0;
    elseif strcmp(option,'killall')
        killall();
        on = 0;
    end   
end

function jms = get_jobmanagers()    
    % find all
    % jms = findResource('scheduler', 'type', 'jobmanager');
    % find just our local JM.
    jms = findResource('scheduler', 'type', 'jobmanager','configuration',cfg('cluster_name'));
end

% killall clusters
function killall()
    cfgs = get_jobmanagers();
    for iter = 1:numel(cfgs)
        matlabpool('close','force',cfgs(iter).Name);
    end
end

% Choose the right configuration to use...
function [cfg,size] = getCfg(jobDesc)
    if strcmp(jobDesc,'small')
        [cfg,size] = getSmallCfg();
    else
        cfgs = get_jobmanagers;
        size = cfgs(1).ClusterSize;
        cfg = cfgs(1);
    end
end

function [cfg,size] = getSmallCfg()
    cfg = findResource('scheduler', 'type', 'local');
    global G_VID_NAME;
    cfg.datalocation = ['~/.matlab/local_scheduler_data/' ...
                        G_VID_NAME];
    size = cfg.ClusterSize;
end

function ensureClosed()
    if matlabpool('size') > 0 % if the pool is open
        matlabpool close;
    end
end
