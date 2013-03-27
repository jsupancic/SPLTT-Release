% JSS3 2012-05-27
% predicate function to indicate if the current MATLAB
% has a display to show graphics on...
function yes = hasDisplay()
    yes = ~usejava('jvm') || feature('ShowFigureWindows');
end
