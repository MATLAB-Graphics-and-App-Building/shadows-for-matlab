function tri = wavydisc()
% Create geometry for a wavy disc.

% Copyright 2024 The MathWorks, Inc.
    
    sz=50;
    t=linspace(0,2,sz)';
    x=cospi(t);
    y=sinpi(t);
    z=cospi(t*4)/3;
    tri = triangulation([ 1:sz; 2:sz 1; [2:sz 1]+sz; (1:sz)+sz ]',...
                        [x y z+3; x*2 y*2 -z+3]);

end
