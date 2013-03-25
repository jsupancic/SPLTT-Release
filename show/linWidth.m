% JSS3 - 2012.7.5
% Compute the proper line with when showing N boxes
function width = linWidth(N)
    a = 7.5;
    b = -.05;
    width = a*exp(b*N);
    width = ceil(width);
end
