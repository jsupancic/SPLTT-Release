% JSS3 2012-04-11
% rebuild the compiled components
function compile()
    % Compile mex files
    % (a) mex version of features.m
    % (b) mex version of matlab's image resize
    % (c) QP solver    
    mex CXXFLAGS="-O3 \$CXXFLAGS" detection/features_c.cc 
    mex CXXFLAGS="-O3 \$CXXFLAGS" detection/mex_resize.cc 
    mex CXXFLAGS="-O3 \$CXXFLAGS" detection/reduce.cc;
    mex CXXFLAGS="-O3 \$CXXFLAGS" detection/nms_c.cc
    mex -g -O -largeArrayDims qp/qp_one_c.cc   
    mex CXXFLAGS="-O3 \$CXXFLAGS" track_dp/dynprog_chain.cc
    lkcompile;

    % compile hashMat which requires openssl
    [void,args] = unix(['pkg-config --cflags --libs ' ...
                        'openssl'])
    cmd = ['mex -g video/hashMat.cc -O ' args]
    eval(cmd);       
end
