% JSS3 - 2012-03-18
% convert rectnalge from [x1 y1 x2 y2] format
% to [x1 y1 w h]
function B = rectKtoB(K)
    B = [K(:,1) K(:,2) (K(:,3)-K(:,1)) (K(:,4)-K(:,2))];
end
