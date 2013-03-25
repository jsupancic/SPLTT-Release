% JSS3 2012-03-20
% JSS3 2012-5-14 extended to support multiple inputs.
% Function to tell if a gt matrix is valid
function occluded = gt_occluded(gt)      
    % only examine the first four elements
    gt = gt(:,1:4);
    
    % check for nan
    occluded = zeros(size(gt,1),1);
    
    % nan => occlusion
    occluded = occluded | any(isnan(gt),2);
end

