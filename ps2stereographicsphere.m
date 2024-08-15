function [newTri, lightZ] = ps2stereographicsphere(ps, opts)
% Compute a triangulation of a sphere that will project a shadow that matches input PS
%
% [newTri] = ps2stereographicsphere(PS) - Project polyshape PS onto a
%                                         sphere and return in a triangulation.
%
% newTri = ps2stereographicsphere(PS, 'Option', Value)
% Options:
%   ProjectionStyle
%    'north' - Project for a light at the north pole of the sphere (default)
%    'center' - Project for a light at the center of the sphere.
%
%   Model
%     0 - Triangulation has no depth.
%     >0 - Create a 3d model of the shape that could be 3d printed with thickness of Model.
%          value is ratio from outer edge to center.  1 means fully filled sphere.
%   AddFeet
%     When creating a model, add feet for it to stand on when you 3D print it.
%     Default to true if Model set >0
%
%   Radius
%     Radius of the sphere being created
%
%   Scale
%     Scale up the model when preparing a model to 3d print.
%
% Output Arguments
% [ newTri, lightZ ] = ps2stereographicsphere(...)
%
%  newTri - A new triangulation representing the shape that casts the shadow in PS
%  lightZ - The Z position of the light needed to cast the shadow PS for the
%           projected sphere shape.

% Copyright 2024 The MathWorks, Inc.

    arguments
        ps
        opts.ProjectionStyle = 'north'
        opts.Model = 0;
        opts.Radius = 1;
        opts.AddFeet = 0;
        opts.Scale = [ 1 1 ];
    end

    % Scale the polyshape
    ps = scale(ps, opts.Scale);
    
    % Convert our shadow shape into a tri mesh that has many triangles
    % so when it is mapped to a curved surface it looks good.
    tri = ps2mesh(ps);

    % Get points from the triangulation
    pts = tri.Points;

    switch opts.ProjectionStyle
      case 'north'
        % Stereographic projection with light in the north.
        % https://en.wikipedia.org/wiki/Stereographic_projection
        X=pts(:,1)/2;
        Y=pts(:,2)/2;
        H=X.^2+Y.^2;
        circpts = [ 2*X./(1+H), 2*Y./(1+H), (H-1)./(H+1) ];
        lightZ = 1;
      case 'center'
        % I invented this projection from the center of the sphere.
        alph = atan2(pts(:,2),pts(:,1));
        d=hypot(pts(:,1),pts(:,2));
        beta = atan2(1,d);
        circpts = [ cos(alph).*cos(beta), sin(alph).*cos(beta), -sin(beta) ];
        lightZ = 1;
      otherwise
        disp('Projection styles of "north" and "center" supported.')
        error('Unknown projection style %s.', opts.ProjectionStyle);
    end

    if opts.Radius ~= 1
        % Expanding a unit circle is easy!
        circpts = circpts*opts.Radius;
    end

    if opts.Model>0
        % Take all verts in circpts, and pull them toward the center of the circle
        % by the amount specified by Model.
        innercircpts = circpts*(1-opts.Model);

        % Add Feet?  Only in model mode, and only on outer edge.
        if opts.AddFeet
            if islogical(opts.AddFeet)
                fs = .5*opts.Radius;
            else
                fs = opts.AddFeet*opts.Radius;
            end
            mask = hypot(circpts(:,1),circpts(:,2)) <= fs & circpts(:,3) < 0;
            circpts(mask,3)=-opts.Radius;
        end
        
        ptsz = size(circpts,1);
        
        cl = tri.ConnectivityList();

        % For the connecting strip
        edges = tri.freeBoundary;
        range = 1:size(edges,1);      % All the boundary edges.
        
        newPts = [circpts; innercircpts];
        newFaces = [ cl;
                     fliplr(cl+ptsz) % Fix which face is facing out
                     edges(range,[2 1 2])+[0 0 ptsz]; % edges connecting outer/inner
                     edges(range,[1 1 2])+[0 ptsz ptsz];];

    else
        newPts = circpts;
        newFaces = tri.ConnectivityList();
    end

    % Push it just above the 0 plane
    newPts = newPts+[0 0 opts.Radius];
    lightZ = lightZ+opts.Radius;

    % Build it.
    newTri = triangulation(newFaces,newPts);
end


