% JSS3 2012-04-13
% rect_zero_orig translates a rectangle so that it is rooted at the
% origin
function k_rect = rect_zero_orig(k_rect)
    k_rect([1,3]) = k_rect([1,3]) - k_rect(1);
    k_rect([2,4]) = k_rect([2,4]) - k_rect(2);
end
