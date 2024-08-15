function hOut = triMeshShadow3(tri, lightpos, opts)
% Display a triangulation with a light and shadows on all walls of the Axes.
%
% triMeshShadow3(tri) - Draw the triangulation TRI with a light and shadow.
%
% triMeshShadow3(tri, lp) - Draw the triangulation with a light at position LP.
%
% Options:
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
        opts.Bounds = []
        opts.ShapeColor = [ .2 .2 1 ] % blue ish
        opts.ShadowColor = [ .8 .8 .8 ] % gray
        opts.ShadowAlpha = 1
        opts.Attenuation = inf
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
        opts.Attenuation = vecnorm(lightpos,2,2) * 5;
    end

    % Draw our new shape using patch
    h.shape = patch(ax, 'Vertices', tri.Points,...
                    'Faces', tri.ConnectivityList(), ... % Same as original triangulation
                    'FaceColor', opts.ShapeColor,...
                    'EdgeColor', 'none');

    % Create a light to shine on the shape
    h.light = light(ax, 'Position', lightpos);

    % Draw our light source
    h.lightmark = line(ax, 'XData', lightpos(1), 'YData', lightpos(2), 'ZData', lightpos(3),...
                'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'w');

    % Basic axes setup
    view(ax, 3)
    daspect(ax, [1 1 1])
    box(ax,'on');
    axis(ax,'tight');
    if isempty(opts.Bounds)
        bx=axis(ax) + [ -4 4 -4 4 0 2 ];
        bx(5) = 0;
    else
        bx = opts.Bounds;
    end
    axis(ax,bx);

    % Prepare to draw shadows
    h.shadows = [];

    cast3Shadows()
    
    function castOneShadow(wallvalue, dim)
    % Compute the cast shadow, and draw it
    % Wallvalue is (presumably) one wall of the axes.
    % dim is the dimension (1 = X, 2 = Y, 3 = Z)
        
        [ShadowTri, ShadowFVA] = tri2shadow(tri, lightpos, wallvalue, dim, ...
                                            'Attenuation', opts.Attenuation);
        if isempty(ShadowFVA)
            fa = opts.ShadowAlpha;
        else
            fa = 'interp';
        end

        if numel(h.shadows) < dim
            h.shadows(dim) = patch(ax, 'Vertices', [], 'Faces', []);
        end

        if isempty(ShadowTri)
            set(h.shadows(dim),'visible','off');
        else
            faces = trimToLimits(ShadowTri, ax);

            if isempty(faces)
                set(h.shadows(dim),'visible','off');
            else
                set(h.shadows(dim), ...
                   'Visible','on',...
                   'Vertices', ShadowTri.Points,...
                   'Faces', faces, ...
                   'FaceColor', opts.ShadowColor,...
                   'FaceAlpha', fa,...
                   'FaceVertexAlphaData', ShadowFVA, ...
                   'AlphaDataMapping', 'none',...
                   'FaceLighting', 'none', ...
                   'EdgeColor', 'none', ...
                   'Tag', 'shadow');
            end
        end
    end

    function cast3Shadows()
    % Update all the shadows
        cp = ax.CameraPosition;
        ct = ax.CameraTarget;

        walls = [ selectWallFromCamera(xlim(ax), cp(1), ct(1));
                  selectWallFromCamera(ylim(ax), cp(2), ct(2));
                  selectWallFromCamera(zlim(ax), cp(3), ct(3)); ];
        
        castOneShadow(walls(1),1);
        castOneShadow(walls(2),2);
        castOneShadow(walls(3),3);
    end    

    function updateShadows(lp, newTri)
    % Move light to new position
        if nargin >= 1 && ~isempty(lp)
            lightpos = lp;
            set(h.light, 'Position', lightpos);
            set(h.lightmark, 'XData', lightpos(1), 'YData', lightpos(2), 'ZData', lightpos(3));
        end

        if nargin >= 2 && ~isempty(newTri)
            tri = newTri;
            set(h.shape, 'Vertices', tri.Points,...
                         'Faces', tri.ConnectivityList(), ... % Same as original triangulation
                         'FaceColor', opts.ShapeColor);
        end

        cast3Shadows();
    end
    
    h.updateShadows = @updateShadows;
    
    % Better light reflectance props
    material(ax, [.6 .9 .3 2 .5])

    % Interaction behavior: Datatips aren't useful here
    set(gca,'Interactions', [ zoomInteraction
                              rotateInteraction
                              rulerPanInteraction ]);
    % Decorate the Axes
    grid(ax, 'on');
    box(ax, 'on');
    set(ax,'projection','perspective')

    % Output argument
    if nargout == 1
        hOut = h;
    end
end

function [ cl_out ] = trimToLimits(tri, ax)
% Trim the input triangulation TRI connectivity list to only include
% triangles partially within the limits.

    pts = tri.Points;
    cl = tri.ConnectivityList;

    xl = xlim(ax);
    yl = ylim(ax);
    zl = zlim(ax);
    
    in_mask = pts(:,1)>=xl(1) & pts(:,1)<=xl(2) & ...
              pts(:,2)>=yl(1) & pts(:,2)<=yl(2) & ...
              pts(:,3)>=zl(1) & pts(:,3)<=zl(2);

    in_idx = find(in_mask);

    cl_mask = sum(ismember(cl, in_idx),2) >= 1;

    cl_out = cl(cl_mask,:);
end

function back_lim = selectWallFromCamera(lim, cp, ct)
% Pick the lower or upper limit based on camera postion and target for a single dimension.
    if cp > ct && ct > lim(1)
        back_lim = lim(1);
    elseif cp < ct && ct < lim(2)
        back_lim = lim(2);
    else
        back_lim = nan;
    end
end
