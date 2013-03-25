function [feat, scale] = featpyramid(im, sbin, interval,f_features)
if nargin < 4
    f_features = @(scaled,sbin) features(scaled,sbin,feat_code('hog'));
end
if nargin >= 4 && isstr(f_features)
    f_features = @(scaled,sbin) features(scaled,sbin,feat_code(f_features));
end

% [feat, scale] = featpyramid(im, sbin, interval);
% Compute feature pyramid.
%
% sbin is the size of a HOG cell - it should be even.
% interval is the number of scales in an octave of the pyramid.
% feat{i} is the i-th level of the feature pyramid.
% scale(i) is the scaling factor used for the i-th level.
% feat{i+interval} is computed at exactly half the resolution of feat{i}.

sc = 2^(1/interval);
imsize = [size(im, 1) size(im, 2)];
max_scale = 1 + floor(log(min(imsize)/(5*sbin))/log(sc));
feat = cell(max_scale, 1);
scale = zeros(max_scale, 1);

% our resize function wants floating point values
im = double(im);
for i = 1:interval
    %im
  sf = 1/sc^(i-1);
  scaled = mex_resize(im, sf);
  % "first" 2x interval
  feat{i} = f_features(scaled, sbin);
  scale(i) = sc^(i-1);
  % remaining interals
  for j = i+interval:interval:max_scale
    scaled  = reduce(scaled);
    feat{j} = f_features(scaled, sbin);
    scale(j) = 2 * scale(j-interval);
  end
end
