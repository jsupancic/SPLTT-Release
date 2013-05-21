% if you can't compile hashMat.cc
% you can just use this. The caching feature
% won't work properly but it's mainly usefull for
% development anyway. 
function h = hashMat_mat(m)
    chars = ['a':'z' 'A':'Z' '0':'9'];
    idxs = randi(numel(chars),[1 32]);
    h = chars(idxs);
end

