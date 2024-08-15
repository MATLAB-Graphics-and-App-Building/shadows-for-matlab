function ps = hexgrid(row, col, radius)
% Create a polyshape hexgrid, where the polyshape represents the sides of the hexes.

% Copyright 2024 The MathWorks, Inc.

    arguments
        row = 9
        col = 8
        radius = .5;
    end

    % origin centered coordinates of one hex of size radius
    theta = linspace(0,2,7);
    xhex = sinpi(theta)*radius;
    yhex = cospi(theta)*radius;

    % Distance from center of edge center
    D = cosd(30)*radius; 
    % Width of hex grid
    WIDTH = col*D*2;
    % Height of hex grid
    HEIGHT = (row-1)*radius*1.5;
    
    ps = polyshape.empty();
    for i = 1:(col+1)
        j = i-1;
        for k = 1:row
            if i<=col || ~mod(k,2)
                m = k-1;
                % Compute x,y positions of one hax in hex location j,k
                % X coords are offset on alternating rows in Y
                xbuff = ((xhex+mod(k,2)*D)+D*2*j)'-WIDTH/2;
                % Each row in Y is nestled between corners of other rows
                % so Y offset is not 2xradius.
                ybuff = (yhex+1.5*radius*m)'-HEIGHT/2;

                ps(end+1) = polybuffer([xbuff ybuff], 'lines', radius/4); %#ok
            end
        end
    end
    ps = union(ps);

end

