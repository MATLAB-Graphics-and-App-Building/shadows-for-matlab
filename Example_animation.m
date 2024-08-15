function Example_animation(opts)
% Example for animating shadows across the axes walls.
%
% Example_animation('fileName','FNAME.gif')
%   Specify a file name (.gif) to export the animation to.

% Copyright 2024 The MathWorks, Inc.
    
    arguments
        opts.Filename (1,1) string = ""
    end

    % Set up our shape
    pat = hexgrid;
    [tri, lightz] = ps2stereographicsphere(pat);
    H = triMeshShadow3(tri, [0 0 lightz]);
    zlim([0 6])
    
    % Identify a cute path for our light to travel on
    t = linspace(-1,1,100)';
    x = sinpi(t).*cospi(t/2);
    z = cospi(t).*cospi(t/2);
    lpath = [ -x*2 x*2 z*2 ] + [0 0 2];

    % Setup for our loop
    zrotstep = pi/size(lpath,1);
    cl = tri.ConnectivityList;
    pts = tri.Points';
    
    for i=1:size(lpath,1)
        % Rotate our triangulation
        M = makehgtform('zrotate',zrotstep*(i+1));
        rpts = M(1:3,1:3) * pts;

        % Update shadows with new light pos and rotated tri
        H.updateShadows(lpath(i,:), triangulation(cl, rpts'));

        if i==1
            gifwrite(opts.Filename, true, .5);
        else
            gifwrite(opts.Filename);
        end
    end
    
end

function gifwrite(fname, first, delay)
    arguments
        fname
        first=false
        delay=1/32
    end
    
    if fname==""
        pause(delay)
    else
        frame = getframe(gcf);
        
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);

        if first && first==1
            imwrite(imind,cm,fname,'gif', ...
                    'LoopCount',inf,...
                    'Delaytime',delay);
        else
            imwrite(imind,cm,fname,'gif',...
                    'WriteMode','append',...
                    'Delaytime',delay);
        end
    end
end

