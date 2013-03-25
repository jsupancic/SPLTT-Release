% SFIGURE  Create figure window (minus annoying focus-theft).
%
% Usage is identical to figure.
%
% Daniel Eaton, 2005
% JSS3 2012.5.16 : cleaned up the format. 
%% See also "help figure"
function h = sfigure(h)
   % debug
   %'sfigure!'
   %keyboard;


   % functionality
   if nargin>=1
       if ishandle(h)
           set(0, 'CurrentFigure', h);
       else
           h = figure(h);
       end
   else
       h = figure;
   end
end
