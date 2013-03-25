% JSS3 2012-5-30
% function which returns configuration information
function p = cfg(option)    
    if strcmp(option,'correct_overlap')
        p = .25;
    elseif strcmp(option,'sample_negatives')
        % sample some negatives from around the positive
        % rather than search over all possible negatives.
        p = 0;
    elseif strcmp(option,'C')
        p = .1; % default is .1;        
    elseif strcmp(option,'cluster_name')
        p = 'wildHOG';
    elseif strcmp(option,'dp_min_time_occluded')
        p = 25;
    elseif strcmp(option,'use_lk')
        p = 1;
    elseif strcmp(option,'cost_dp_lcl');
        % this is meaningless legacy option
        p = 1; 
    else
        fprintf('bad option name\n');
        assert(false);
    end    
end