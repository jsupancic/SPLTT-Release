function feat = features(im,sbin,featCode)
% res = features(im,sbin)
% Let [imy,imx] = size(impatch)
% -Result will be (imy/8-1) by (imx/8-1) by (4+9) for 
% 9 orientation bins and 4 normalizations for every 8x8 pixel-block
% -This won't produce exact same results as features.cc because this
% uses hard-binning rather than soft binning
memo = [cfg('tmp_dir') 'features/' ...
        'imHash=' hashMat(im) ...
        'sbin=' num2str(sbin) ...
        'featCode=' num2str(featCode) '.mat'];
MEMO = 0;
if exist(memo,'file') && MEMO
    load(memo,'feat');
    return;
end

MEX = 1;
if MEX
    feat = features_c(im,sbin,featCode);
    if MEMO
        save(memo,'feat');
    end
    return;
end

% Crop/pad image to make its size a multiple of sbin
[ty,tx,tz] = size(im);
imy = round(ty/sbin)*sbin;
if imy > ty,
  im = padarray(im,[imy-ty 0 0],'post');
elseif imy < ty,
  im = im(1:imy,:,:);
end
imx = round(tx/sbin)*sbin;
if imx > tx,
  im = padarray(im,[0 imx-tx 0],'post');
elseif imx < tx,
  im = im(:,1:imx,:);
end
im = double(im);
n  = (imy-2)*(imx-2);

% Pick the strongest gradient across color channels
dy  = im(3:end,2:end-1,:) - im(1:end-2,2:end-1,:); dy = reshape(dy,n,3); 
dx  = im(2:end-1,3:end,:) - im(2:end-1,1:end-2,:); dx = reshape(dx,n,3);
len = dx.^2 + dy.^2;
[len,I] = max(len,[],2);
len = sqrt(len);
I   = sub2ind([n 3],[1:n]',I);
dy  = dy(I); dx = dx(I);

% Snap each gradient to an orientation
[uu,vv] = pol2cart([0:pi/9:pi-.01],1);
v = dy./(len+eps); u = dx./(len+eps);
[dummy,I] = max(abs(u(:)*uu + v(:)*vv),[],2);

% Spatially bin orientation channels
ssiz = [imy imx]/sbin;
feat = zeros(prod(ssiz), 9);
for i = 1:9,
  tmp = reshape(len.*(I == i),imy-2,imx-2);
  tmp = padarray(tmp,[1 1]);
  feat(:,i) = sum(im2col(tmp,[sbin sbin],'distinct'))';
end

% Compute features for all overlapping 2x2 windows
ind  = reshape(1:prod(ssiz),ssiz);
ind  = im2col(ind,[2 2])';
n    = size(ind,1);
feat = reshape(feat(ind,:),n,4*9);

% Normalize and clip to .2
nn   = sqrt(sum(feat.^2,2)) + eps;
feat = bsxfun(@times,feat,1./nn);
feat = min(feat,.2);

% Re-align features so that 4*9 values refer to same 8x8 spatial bin
% Take projections along 4 normalization regions and 9 orientations
feat = reshape(feat,[ssiz-1 4 9]);
feat = cat(3,feat(2:end,2:end,1,:),feat(1:end-1,2:end,2,:),...
           feat(2:end,1:end-1,3,:),feat(1:end-1,1:end-1,4,:));
feat = cat(3,.5*reshape(sum(feat,3),[ssiz-2 9]),.2357*sum(feat,4)); 
