% JSS3 2012-04-20
% scale a rect by the given factors
function k_rect = rect_scale(k_rect,xScale,yScale)
    center = rect_center(k_rect);
    width = k_rect(:,3) - k_rect(:,1);
    height = k_rect(:,4) - k_rect(:,2);
    k_rect = rect_from_center(center,[xScale.*width yScale.*height]);
end
