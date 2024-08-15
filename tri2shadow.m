function [triOut, fva] = tri2shadow(triIn, L, Pv, Pdim, opts )
% Compute a triangulation that is the shadow cast by an input triangulation.
%
% triOut = tri2shadow(triIn, L)
% For the triangulation triIn, and the light position L create a new
% triangulation on the Zplane where Z=0 that represents the shadow of triIn.
%
% triOut = tri2shadow(triIn, L, Pv, Pdim)
% As above, but cast the shadow on a plane at value Pv, with a
% dimension Pdim indicating which dimension the plane is in.
%    If Pv=2, and Pdim=3 -> Zplane = 2
%    If Pv=-2, and Pdim=1 -> Xplane = -2
%
% Optional inputs
%   'Attenuation' - A value that says how far away from the light before the shadow
%                   dissapears.
%                   Missing shadow pts are removed from the output triangulation.
%                   This will return FaceVertex Attenuation data (can be used as alpha)
%   If Attenuation is not specified, but a 2nd output is requested, this value will be computed
%   as 1.5x distance from light to origin.
%    - 0 means no attenuation.
%    - inf means auto-compute attenuation
%
%  [triOut, FVA] = tri2shadow(triIn, L, 'Attenuation', atn)
%  Also return the FaceVertexAlphaData needed to represent the attenuation of the shadow.

% Copyright 2024 The MathWorks, Inc.

    arguments
        triIn = defaultTri()
        L = [ .2 .2 1.6 ]
        Pv = 0
        Pdim = 3
        opts.Attenuation = inf;
    end

    % Fix Attenuation if needed
    if nargout >= 2
        if isinf(opts.Attenuation)
            opts.Attenuation = vecnorm(L,2,2) * 2;
        end
    else
        opts.Attenuation = 0;
    end

    % Get points from the input
    pts = triIn.Points;
    cl = triIn.ConnectivityList;

    % Init vertex array for the shadow
    Spts = zeros(size(pts,1),3);

    % Offset used so Light can be assumed at 0,0
    offset = L;
    offset(Pdim) = Pv;

    % Mask used to cast onto the correct plane.
    Nmask = 1:3;
    Nmask(Pdim) = [];

    % Light position in plane dimension
    Ln = L(Pdim)-Pv;
    NLpt = L;
    NLpt(Pdim) = Ln;
    
    % Translate as if light is around the XY origin
    Npts = pts-offset;

    % Project X&Y onto the Z plane, and for shadow verts, set Z to 0.
    % Nmask allows casting onto any plane
    Spts(:,Nmask) = Npts(:,Nmask).*Ln./(Ln-Npts(:,Pdim));

    % Find vertices that are on the wrong side of the light, or
    % wrong side of the plane we are casting shadows onto.
    if 0 < Ln
        mask = Npts(:,Pdim)>Ln; % behind the light
        cmask= Npts(:,Pdim)<0;  % behind the plane of shadow
    else
        mask = Npts(:,Pdim)<Ln;
        cmask = Npts(:,Pdim)>0;
    end
    % Look for infs and mask out those too.
    mask = mask | logical(sum(~isfinite(Spts),2));
    
    if any(cmask)
        % Clamp all shadow points on wrong side of plane onto the plane.
        % This is imperfect, but fast
        Spts(cmask,:) = Npts(cmask,:);
        Spts(cmask,Pdim) = 0;
    end

    if any(mask)
        % There are some items in MASK that are infinite in some way.
        % Replace INFINITE with a value that is just fairly far away
        % so partial triangles still look OK around the edges.
        if opts.Attenuation
            myinf = opts.Attenuation*2;
        else
            myinf = 1000;
        end
        
        % Compute pts centered around the light, then normalize those pts
        % and extend to myinf.  This will make these PTS rational, and in the
        % right loose direction.
        Ipts = Npts-NLpt;
        Ipts(mask,Nmask) = Ipts(mask,Nmask)./vecnorm(Ipts(mask,Nmask),2,2) * myinf;
        
        % Replace bad values with our extrapolated version
        Spts(mask,:) = Ipts(mask,:)+NLpt;

        % Press onto shadow plane
        Spts(mask,Pdim) = 0;
    end

    % Translate everything back to original light location
    Spts = Spts+offset;
        
    % If we have an attenuation input, compute that.
    if opts.Attenuation
        ldist = vecnorm(Spts-L, 2, 2);
        fva = 1-(min(ldist, opts.Attenuation)/opts.Attenuation);
    else
        fva = [];
    end
    
    % Create the triangulation for the shadow
    if isempty(cl)
        tri = [];
    else
        warning('off', 'MATLAB:triangulation:PtsNotInTriWarnId')
        tri = triangulation(cl, Spts);
    end

    if nargout == 0
        if opts.Attenuation
            triMeshShadow(triIn, L, 'ShadowTri', tri, 'ShadowFVA', fva);
        else
            triMeshShadow(triIn, L, 'ShadowTri', tri);
        end
    else
        triOut = tri;
    end

end

function tri = defaultTri
    tri = triangulation([1 2 3; 1 2 4], ...
                        [ 2 1 .9
                          .2 .3 .8
                          3 -2 .2
                          -1 1 .6]);
end
