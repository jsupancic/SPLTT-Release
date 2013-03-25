% Copyright 2011 Zdenek Kalal
%
% This file is part of TLD.
% 
% TLD is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% TLD is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with TLD.  If not, see <http://www.gnu.org/licenses/>.
% 
% JSS3 - 2012.6.19
% Conf, now, comes from LK not from NN validator.
function [BB2 conf Valid] = tldTracking(BB1,I,J)
% Estimates motion of bounding box BB1 from frame I to frame J

% initialize output variables
BB2    = []; % estimated bounding 
conf   = []; % confidence of prediction
Valid  = 0;  % is the predicted bounding box valid? if yes, learning will take place ...

% estimate BB2
xFI    = bb_points(BB1,10,10,5); % generate 10x10 grid of points within BB1 with margin 5 px
xFJ    = lk(2,I,J,xFI,xFI); % track all points by Lucas-Kanade tracker from frame I to frame J, estimate Forward-Backward error, and NCC for each point
medFB  = median2(xFJ(3,:)); % get median of Forward-Backward error
medNCC = median2(xFJ(4,:)); % get median for NCC
idxF   = xFJ(3,:) <= medFB & xFJ(4,:)>= medNCC; % get indexes of reliable points
BB2    = bb_predict(BB1,xFI(:,idxF),xFJ(1:2,idxF)); % estimate BB2 using the reliable points only
% assert(~gt_occluded(BB2'))

%tld.xFJ = xFJ(:,idxF); % save selected points (only for display purposes)

% detect failures
%if ~bb_isdef(BB2) || bb_isout(BB2,size(I)), BB2 = []; return; end % bounding box out of image
%if medFB > 10, BB2 = []; return; end  % too unstable predictions

% JSS3 - compute the confidence
% get the valid points.
%keyboard;
xFI = xFI(1:2,idxF);
xFJ = xFJ(1:2,idxF);
total = size(xFI',1);
correct = sum(rect_contains(BB2',xFJ'));
conf = correct/total;

% failed prediction ?
if total < 1
    BB2 = BB1(1:4,:);
    conf = 0;
end
