% JSS3 2012-04-11
% rebuild the compiled components
function compile()
    % compile TLD's LK module.
    addpath('3rd_party/TLD/');

    % Compile mex files
    % (a) mex version of features.m
    % (b) mex version of matlab's image resize
    % (c) QP solver            
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" detection/features_c.cc 
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" detection/mex_resize.cc 
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" detection/reduce.cc;
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" detection/nms_c.cc
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" -g -O -largeArrayDims qp/qp_one_c.cc   
    mex CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS" track_dp/dynprog_chain.cc
    lkcompile;

    % compile hashMat which requires openssl
    [void,args] = unix(['pkg-config --cflags --libs ' ...
                        'openssl'])
    cmd = sprintf('mex %s -g video/hashMat.cc -O %s','CXXFLAGS="-pedantic -Werror -I mex/ -O3 \$CXXFLAGS"',args);
    eval(cmd);       
end
