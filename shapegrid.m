function ps = shapegrid(nsides, depth, opts)
% Create a vaguely circular mesh of shapes with NSIDES sides.
%
% shapegrid(5, 3) - Create a grid of pentagons 3 deep.
%
% Options:
%   Radius - radius of each shape in the grid.
%   EdgeThickness - Thickness of the edge between shapes in the grid.
%   Gap - Factor to add a gap betwen shapes in the grid.
%   Filter - Buffer around new shape added within which to not add new shapes.
%   EdgeSkip - When adding new shapes to an edge, include every nth edge.

% Copyright 2024 The MathWorks, Inc.

    arguments
        nsides = 6
        depth = 2
        opts.Radius = .5
        opts.EdgeThickness = .25
        opts.Gap = 1
        opts.Filter = []
        opts.EdgeSkip = 1
    end

    theta=linspace(0,2,nsides+1)';
    xc=cospi(theta)*opts.Radius;
    yc=sinpi(theta)*opts.Radius;
    ang = diff(theta(1:2));

    cl = 2*opts.Radius*sinpi(ang/2); % length of chord
    D = sqrt(opts.Radius^2-(cl/2)^2); % Distance from center of chord (our edge) to center

    if isempty(opts.Filter)
        switch nsides
          case {3 4}
            filt=0;
          case 6
            filt=D;
          otherwise
            filt=opts.Radius;
        end
    else
        filt = opts.Filter;
    end
    
    function [ps, nc] = oneshape(center,x,y,dp)
    % Create a shape outline and return it (ps)
    % Return centers of all surrounding shapes for filtering (nc)
        ps = polybuffer([x y]+center, 'lines', opts.Radius*opts.EdgeThickness);
        % Compute next set of centers to add
        nc = [ cospi(theta(1:nsides)+ang/2*dp)*D*2*opts.Gap ...
               sinpi(theta(1:nsides)+ang/2*dp)*D*2*opts.Gap ] + center;
        % Strip out new sides closer to the interior.
        % Filter adds extra buffer to eliminate extra shapes when nsides is large.
        my_dist = vecnorm(center,2,2)+filt;
        nc_dist = vecnorm(nc,2,2);
        mask = nc_dist > my_dist;
        nc = nc(mask,:);
    end    


    [ps, nextcenters]=oneshape([0 0],xc,yc,1);
    centerlist = [ 0 0 ];

    for d=2:depth
        if mod(nsides,2)
            % If we have an odd number of sides, we need to rotate our angles.
            xc=cospi(theta+ang/2*(d-1))*opts.Radius;
            yc=sinpi(theta+ang/2*(d-1))*opts.Radius;
            dp = d;
        else
            % even sides - no modification needed
            dp = 1;
        end

        nc2 = zeros(0,2);
        for f = 1:opts.EdgeSkip:size(nextcenters,1)
            [ps(end+1), nc] = oneshape(nextcenters(f,:), xc, yc, dp); %#ok
            centerlist(end+1,:) = nextcenters(f,:); %#ok
            nc2 = [nc2; nc]; %#ok
        end
        nextcenters=uniquetol(nc2,opts.Radius/10,'ByRows',true);
        %disp(size(nextcenters,1))
    end
    
    ps = union(ps);

    if nargout == 0
        plot(ps)
        daspect([1 1 1]);
    end
end

