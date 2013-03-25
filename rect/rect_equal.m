% JSS3 - 2012-06-03
% Are two rectangles equal?
function eq = rect_equal(rect1,rect2)
    eq = (gt_occluded(rect1) && gt_occluded(rect2)) || ...
         all(rect1(:,1:4) == rect2(:,1:4));
end
