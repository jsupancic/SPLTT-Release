% JSS3 - 2012.6.15
% function to turn the cluster on or off.
% jobDesc: small, large, local (largest on one machine)
% This file has to be tuned to *your* computational resources.
%
% This simplest way to configure this is to just use a single
% parallel pool, in which case you just want to do 
% "matlabpool open" when option is "on"
% "matlabpool close" when option is "off"
%
% For me,
% "small" opens a small 8 to 12 processor pool using parallel
%     MATLAB toolbox.
% "local" opens a local pool of maximum size 48 cores on one
%     machine using the distributed toolbox.
% "large" opens a multi-machine distributed pool. This may be
%     undesirable for some tasks because (1) this pool can become a
%     bottleneck and (2) distributing data over the network is slow.
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
        
    % don't give the client more cores than it requested.
    if strcmp(option,'on')        
        matlabpool open;
    elseif strcmp(option,'off') && matlabpool('size') > 0
        matlabpool close;
    elseif strcmp(option,'killall')
        matlabpool close;
    end   
end

