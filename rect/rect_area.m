% JSS3 - 2012.7.10
% Return area of a rectangle
function ar = rect_area(k_rect)
    width = k_rect(:,3) - k_rect(:,1);
    height = k_rect(:,4) - k_rect(:,2);
    ar = width .* height;
end
