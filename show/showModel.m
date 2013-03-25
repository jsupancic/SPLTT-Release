% Display the HOG template
% Only the first argument is required.
function [hogPos,hogNeg] = showModel(ww,n,sc)

% can't show on the cluster worker.
if ~isempty(getCurrentTask)
    return
end

% the second two arguments are optinal.
if nargin >= 2
    sfigure(n);
    clf;
else
    n = 1;
end
if nargin < 3,
  %Set the scale so that the maximum weight is 255
  sc = max(abs(ww(:)));
end

sc = 255/sc;

siz = 20;

im1 = HOGpicture( ww,siz)*sc;
hogPos = im1;
im2 = HOGpicture(-ww,siz)*sc;
hogNeg = im2;

%Combine into 1 image
buff = 10;
im1 = padarray(im1,[buff buff],200,'both');
im2 = padarray(im2,[buff buff],200,'both');
im = cat(2,im1,im2);
im = uint8(im);
imagesc(im); colormap gray;
title(['HoG Model: ' n]);
%keyboard;

function im = HOGpicture(w, bs)
% HOGpicture(w, bs)
% Make picture of positive HOG weights.
global ORI_BINS;

% construct a "glyph" for each orientaion
bim1 = zeros(bs, bs);
%bim1(:,round(bs/2):round(bs/2)+1) = 1;
bim1(1:(round(size(bim1,1)./2)+1),round(20/2):round(20/2)+1) = 1;
bim = zeros([size(bim1) ORI_BINS]);
bim(:,:,1) = bim1;
for i = 2:ORI_BINS,
  bim(:,:,i) = imrotate(bim1, -(i-1)*20, 'crop');
end

% make pictures of positive weights bs adding up weighted glyphs
s = size(w);    
w(w < 0) = 0;    
im = zeros(bs*s(1), bs*s(2),3);
for i = 1:s(1),
  iis = (i-1)*bs+1:i*bs;
  for j = 1:s(2),
    jjs = (j-1)*bs+1:j*bs;          
    % draw the background
    if(size(w,3) > ORI_BINS+4)
        im(iis,jjs,1) = w(i,j,ORI_BINS+4+1);
        im(iis,jjs,2) = w(i,j,ORI_BINS+4+2);
        im(iis,jjs,3) = w(i,j,ORI_BINS+4+3);
    end
    
    % draw the lines
    for k = 1:ORI_BINS,
      im(iis,jjs,1) = im(iis,jjs,1) + bim(:,:,k) * w(i,j,k);
      im(iis,jjs,2) = im(iis,jjs,2) + bim(:,:,k) * w(i,j,k);
      im(iis,jjs,3) = im(iis,jjs,3) + bim(:,:,k) * w(i,j,k);
    end
  end
end


