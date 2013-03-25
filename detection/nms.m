% res = nms(boxes,overlap)
% Greedily removes blobs that intersect by more than overlap
function res = nms(boxes,overlap,scalex,scaley)
boxes = shrink(boxes,scalex,scaley);

res = nms_c(boxes,overlap);
res = flipdim(sortrows(res,5),1);
return;

if isempty(boxes),
  res = [];
else
  x1 = boxes(:,1);
  y1 = boxes(:,2);
  x2 = boxes(:,3);
  y2 = boxes(:,4);
  r  = boxes(:,5);
  area = (x2-x1+1) .* (y2-y1+1);

  [vals,I] = sort(r);
  pick = [];
  while ~isempty(I),
    last = length(I);
    i = I(last);
    pick = [pick; i];
    suppress = [last];
    for pos = 1:last-1,
      j = I(pos);
      xx1 = max(x1(i), x1(j));
      yy1 = max(y1(i), y1(j));
      xx2 = min(x2(i), x2(j));
      yy2 = min(y2(i), y2(j));
      w = xx2-xx1+1;
      h = yy2-yy1+1;
      if w > 0 && h > 0
        % compute overlap 
        o = w * h / area(j);
        % VOC criterion for overlap
        % o = w*h/ (area(i) + area(j) - w*h);
        if o > overlap
          suppress = [suppress; pos];
        end
      end
    end
    I(suppress) = [];
  end
  res = boxes(pick,:);
end

function box = shrink(box,sx,sy)
% box = shrink(box,scalex,scaley)

x1 = box(:,1);
y1 = box(:,2);
x2 = box(:,3);
y2 = box(:,4);
w  = x2-x1+1;
h  = y2-y1+1;

x1 = x1 + (w-1)/2 - (w*sx-1)/2;
y1 = y1 + (h-1)/2 - (h*sy-1)/2;
x2 = x1 + w*sx - 1;
y2 = y1 + h*sy - 1;

box(:,1:4) = [x1 y1 x2 y2];
