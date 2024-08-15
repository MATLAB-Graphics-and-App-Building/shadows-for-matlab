function tri = ps2mesh(ps, ppu, z)
% Convert the polyshape PS into a triangulation that has been expanded.
% Expand the # of vertices along straight segments by PPU (points per unit)
%
% PS - input polyshape
% PPU - Points (vertices) per Unit - how many points/vertices to add when expanding.
%       Default to 10.
% Z - The Z coordinate the resulting triangulation will have.  Default to 0.
%
% Note: If you have Partial Differential Equasion Toolbox(TM) installed,
%       this function will use that, and the PPU you select may not be honored.

% Copyright 2024 The MathWorks, Inc.

    arguments
        ps (1,1) polyshape
        ppu (1,1) double = 10
        z (1,1) double = 0
    end

    % Error checking - make sure we don't accidentally ask for
    % something that will take a long time.
    % Use the area * ppu^2 to guess # of things.
    th = area(ps) * ppu^2;
    if th > 100000
        error('Predicted requested mesh size over 100,000.  Pick smaller ppu');
    end

    % If we have PDE toolbox installed, then use generateMesh
    v = ver('PDE');

    % If no PDE tlbx, lets just do a simple linear expand across the polyshape
    % edges and hope for the best.
    if isempty(v)
        % Expand the polyshape to have more pts so it maps to rounded shapes better
        ps = expand(ps, ppu);

        % Get the triangulation
        tri = ps.triangulation;
    else

        % We have PDE tlbx, so lets try using 'generateMesh'  To start, convert our
        % ps into a triangulation
        triIn = ps.triangulation();
        elements = triIn.ConnectivityList';
        nodes = triIn.Points';

        model = createpde(); % from an example
        geometryFromMesh(model, nodes, elements);

        %PDE hmax is how long one edge is.  Our input is vertices across 1 unit, so
        % that makes hmax 1/ppu.
        hmax=1/ppu;

        % hmax says how small to make the mesh.
        % geomentric order says linear asks for fewer points than the dflt.
        % We want a denser mesh, but also as few pts as possible. :P
        FM = generateMesh(model, 'Hmax', hmax, 'GeometricOrder', 'linear');

        [p,~,t] = meshToPet(FM);

        if nargin == 3
            p(3,:) = z;
        end
        
        warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
        tri = triangulation(fliplr(t(1:3,:)'), p');

    end
    
end

function ps = expand(psIn, ppu)
% Make all long straight edges in the polyshape be made of many short
% segments.  This is a backup fcn if PDE is not installed.

    % Get the regions
    r = regions(psIn);

    % New polyshape should keep all the extra pts we'll be adding.
    ps = polyshape();

    % Loop over all the regions
    for i=1:numel(r)
        [x,y] = boundary(r(i),1); % Exclude all the holes in this region

        ps = union(ps, expandedges(x,y,ppu), 'KeepCollinearPoints', true);
    end

    % Get the holes in those regions
    h = holes(psIn);
    
    % Loop over all the holes
    for i=1:numel(h)
        [x,y] = boundary(h(i),1);

        ps = subtract(ps, expandedges(x,y,ppu), 'KeepCollinearPoints', true);
    end
end

function ps = expandedges(x,y, ppu)
% Expand the edges for one polyregion

    if x(end)==x(1) && y(end)==y(1)
        inp = [ x y ];
    else
        inp = [ x(end) y(end) % This is a loop.
                x y ];
    end
    
    pts = [ ];
    for i=2:size(inp,1)
        d = norm(inp(i-1,:)-inp(i,:)); % distance between adjacent pts
        n = max(2,floor(ppu*d)); % n pts to increase it to
        if n==2
            pts = [ pts; %#ok
                    inp(i-1,:) ];
        else
            %disp expand
            xe = linspace(inp(i-1,1),inp(i,1),n)'; % interp
            ye = linspace(inp(i-1,2),inp(i,2),n)';
            % Add all but last pt to avoid dups
            pts = [ pts; %#ok
                    xe(1:end-1) ye(1:end-1) ];
        end
    end

    ps = polyshape(pts, 'KeepCollinearPoints', true);
end
