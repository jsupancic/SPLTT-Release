% JSS3 - 2012.7.10
% Return aspect ratio of a rectangle
function aspect = rect_aspect(k_rect)
    width = k_rect(:,3) - k_rect(:,1);
    height = k_rect(:,4) - k_rect(:,2);
    aspect = width ./ height;
end
