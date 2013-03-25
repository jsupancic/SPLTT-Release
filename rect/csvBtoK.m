% JSS3 - 2012.6.28
% convert Babenko BBs to Kalal BBs in a CSV file
function csvBtoK(filename)
    b_track = csvread(filename);
    k_track = rectBtoK(b_track);
    csvwrite(filename,k_track);
end
