% JSS3 - 2012.6.15
% configure the paths...
function setpath(force)
    if nargin < 1
        force = 0;
    end
    
    fprintf('+setpath\n');
    persistent paths_set;
    if isempty(paths_set) || force
        restoredefaultpath
        addpath(genpath('./3rd_party'));
        addpath_recurse('.','','end');
        paths_set = 1;                
    end
    fprintf('-setpath\n');
end
