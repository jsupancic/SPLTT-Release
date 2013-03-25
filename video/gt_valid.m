% JSS3 2012-03-20
% JSS3 2012-5-14 : added support for multiple ground truths
% Function to tell if a gt matrix is valid
function valid = gt_valid(gt)
    valid = ones(size(gt,1),1);
    
    % check for bad size
    if(size(gt,2) < 4)
        valid = zeros(size(gt,1),1);
        return;
    end
    
    % check for all zero
    valid = valid & any(gt ~= 0,2);
end
