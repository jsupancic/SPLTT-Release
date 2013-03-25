% JSS3 2012-04-14
% JSS3 multiple rectangle support 2012-5-14
% Computes the intersection over union overlap
% for two Kalal format rectangles
function overlap = rect_overlap(k_rect1, k_rect2)
    if gt_occluded(k_rect1) && gt_occluded(k_rect2)
        overlap = 1;
    elseif xor(gt_occluded(k_rect1),gt_occluded(k_rect2))
        overlap = 0;
    else        
        rect1 = rectKtoB(k_rect1);
        rect2 = rectKtoB(k_rect2);
        
        % intersection of rectangle 1 and rectangle 2
        intersection = rectint(rect1,rect2);
        % area of rectangle 1
        area1 = rect1(:,3) .* rect1(:,4); % a = w*h
                                          % area of rectangle 2
        area2 = rect2(:,3) .* rect2(:,4); % a = w*h
        
        % union over intersection
        overlap = intersection ./ (area1+area2-intersection);
    end
end
