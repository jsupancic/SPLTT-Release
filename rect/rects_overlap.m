%% JSS3 2012.8.20
% Compute overlap between two lists of rectangles
function ols = rects_overlap(k_A,k_B)
    ols = zeros(size(k_A,1),1);
    for iter = 1:numel(ols)
        ols(iter) = rect_overlap(k_A(iter,:),k_B(iter,:));
    end    
end
