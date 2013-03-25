% JSS3 2012-04-15
% get the local score weight
function L = track_dp_lcl()
    % HERE BE DRAGONS (paramters)
    global GBL_PARM_TRACK_DP_L;
    if isempty(GBL_PARM_TRACK_DP_L)
        %L = 15625;
        L = cfg('cost_dp_lcl');
        %L = 625;
    else
        L = GBL_PARM_TRACK_DP_L;
    end
end
