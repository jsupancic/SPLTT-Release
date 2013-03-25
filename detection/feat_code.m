% JSS3 - 2012-6-1
% Convert string to code number
function code = feat_code(featName)
    if strcmp(featName,'color')
        code = 2;
    elseif strcmp(featName,'hog')
        code = 1;
    end
end
