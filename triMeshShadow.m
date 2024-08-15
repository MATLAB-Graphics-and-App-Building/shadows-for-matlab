function hOut = triMeshShadow(tri, lightpos, opts)
% Display a triangulation with a light and shadow.
%
% triMeshShadow(tri) - Draw the triangulation TRI with a light and shadow.
%
% triMeshShadow(tri, lp) - Draw the triangulation with a light at position LP.
%
% Options:
%   ShadowTri - Provide the triangulation for the shadow
%   ShadowFVA - Provide the Alpha Data for the shadow attenuation
%   ShapeColor - Color for the triangulation shape
%   ShadowColor - Color of the shadow
%   ShadowAlpha - Alpha to use with shadow when FVA is not provided.
%   Attenuation - When triMeshShadow computes the shadow, range from light to shadow
%           within which the shadow is still visible.
%           0 means no attenuation.
%           inf means auto-compute attenuation

% Copyright 2024 The MathWorks, Inc.
    
    arguments
        tri = wavydisc
        lightpos = []
        opts.ShadowTri = []
        opts.ShadowFVA = []
        opts.ShapeColor = [ .2 .2 1 ] % blue ish
        opts.ShadowColor = [ .8 .8 .8 ] % gray
        opts.ShadowAlpha = .9
        opts.Attenuation = inf
        opts.Debug = false
    end    

    % Prepare our axes
    ax = newplot;

    % Compute a nice light location based on the input triangulation if no
    % light position was provided.
    if isempty(lightpos)
        [l,u] = bounds(tri.Points,1);
        % above, and back right.
        lightpos = mean([u;l]).*[1 1 2];
    end

    % Compute a nice Attenuation
    if isinf(opts.Attenuation)
        opts.Attenuation = vecnorm(lightpos,2,2) * 4;
    end
    
    % Compute the cast shadow, and draw it
    if isempty(opts.ShadowTri)
        [opts.ShadowTri, opts.ShadowFVA] = tri2shadow(tri, lightpos, 'Attenuation', opts.Attenuation);
    end
    if isempty(opts.ShadowFVA)
        fa = opts.ShadowAlpha;
    else
        fa = 'interp';
    end
    if isempty(opts.ShadowTri)
        h(1) = gobjects();
    else
        h(1) = patch(ax, 'Vertices', opts.ShadowTri.Points,...
                     'Faces', tri.ConnectivityList(), ... % Same as original triangulation
                     'FaceColor', opts.ShadowColor,...
                     'FaceAlpha', fa,...
                     'FaceVertexAlphaData', opts.ShadowFVA, ...
                     'AlphaDataMapping', 'none',...
                     'FaceLighting', 'none', ...
                     'EdgeColor', 'none');
    end
    
    % Draw our new shape using patch
    h(2) = patch(ax, 'Vertices', tri.Points,...
                 'Faces', tri.ConnectivityList(), ... % Same as original triangulation
                 'FaceColor', opts.ShapeColor,...
                 'EdgeColor', 'none');

    % Draw our light source
    h(3) = line(ax, 'XData', lightpos(1), 'YData', lightpos(2), 'ZData', lightpos(3),...
                'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'w');

    % Create an actual light source!
    h(4) = light(ax, 'Position', lightpos);

    % Better light reflectance props
    material(ax, [.6 .9 .3 2 .5])

    % Interaction behavior: Datatips aren't useful here
    set(gca,'Interactions', [ zoomInteraction
                              rotateInteraction
                              rulerPanInteraction ]);
    % Decorate the Axes
    view(ax, 3)
    daspect(ax, [1 1 1])
    grid(ax, 'on');
    box(ax, 'on');
    axis(ax,'padded');
    zl = zlim(ax);
    zlim(ax, [0 zl(2)]);
    set(ax,'projection','perspective')

    % Draw some debugging stuff
    if opts.Debug
        tri = ps.triangulation();
        pts = tri.Points;
        for idx=1:size(pts,1)
            line(ax, ...
                 'XData', [ pts(idx,1) 0 ],...
                 'YData', [ pts(idx,2) 0 ],...
                 'ZData', [ 0 LightZ ]);
        end
    end

    % Output argument
    if nargout == 1
        hOut = h;
    end
end


