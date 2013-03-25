% JSS3 2012-04-13
% Translate a Kalal rectangle
function k_rect = rect_trans(k_rect,offset)
    k_rect([1,3]) = k_rect([1,3]) + offset(1);
    k_rect([2,4]) = k_rect([2,4]) + offset(2);
end
