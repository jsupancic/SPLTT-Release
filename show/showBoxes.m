function showBoxes(im,boxes,clean)
% showBoxes(im,boxes)
if nargin < 3
    clean = 0;
end

cla;
if clean
    set(gca,'position',[0 0 1 1]) ;    
end
imagesc(im);

width = linWidth(size(boxes,1));

if ~isempty(boxes),
  % use light red line to show everyone
  if size(boxes,1) > 1
      showGhostBoxes(boxes(2:end,:),'r',width);
  end
  
  % plot the best box in dark blue.
  x1 = boxes(1,1);
  y1 = boxes(1,2);
  x2 = boxes(1,3);
  y2 = boxes(1,4);
  line([x1 x1 x2 x2 x1]',[y1 y2 y2 y1 y1]','color','b','linewidth', ...
       width*2);
  
  % plot numbers...
  if clean 
      return;
  end
  for boxIter = 1:size(boxes,1)
      boxTexts = {};
      curBox = boxes(boxIter,:);
      cen = deal(rect_center(curBox));
      % add the response?
      if size(boxes,2) > 4
          boxTexts{end+1} = ['resp = ' num2str(curBox(:,5))];
      end
      %if size(boxes,2) >= 6
      %    boxTexts{end+1} = ['occ = ' num2str(curBox(:,6))];
      %end
      %if size(boxes,2) >= 7
      %    boxTexts{end+1} = ['emg = ' num2str(curBox(:,7))];
      %end
      text(cen(1),cen(2),boxTexts,'Color','g');
  end
end

drawnow;
