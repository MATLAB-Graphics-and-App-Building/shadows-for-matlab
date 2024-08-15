function makeShadowModels (Directory, Range)
% Create several STL models suitable for 3D printing to create your
% own shadows in real-life.
%
% Default to placing models in an "stl" subdirectory.
%
% If input directory is "preview", then display on screen instead of
% creating an stl file.

% Copyright 2024 The MathWorks, Inc.
    
    arguments
        Directory (1,1) string = "stl"
        Range = 3:6
    end

    switch Directory
      case "preview"
        % Carry on
      otherwise
        if ~exist(Directory, 'dir')
            mkdir(Directory);
        end
    end

    for S=Range
        switch S
          case 3
            ps = shapegrid(S,8,'Radius',.75, 'EdgeThickness', .15);
            createShape(ps, "triangles", Directory, 'FootRadius', .56);
          case 4
            ps = shapegrid(S,7,'Radius',.7, 'EdgeThickness', .25);
            createShape(ps, "squares", Directory);
          case 5
            ps = shapegrid(S,6,'Radius',.6, 'EdgeThickness', .2);
            createShape(ps, "pentagons", Directory);
          case 6
            ps = shapegrid(S,5,'Radius',.6, 'EdgeThickness', .25);
            createShape(ps, "hexagons", Directory);
        end
    end
end

function createShape(ps, name, directory, opts)
% Create or preview the shape.
    arguments
        ps
        name
        directory
        opts.FootRadius = true
    end

    Radius = 60;  % mm
    Model = 2/Radius; % produces ratio that is 4 mm


    switch directory
      case 'preview'
        % Display a preview
        figure
        [tri, lz] = ps2stereographicsphere(ps);
        triMeshShadow(tri, [0 0 lz]);
        title(name);
      otherwise
        % Write out an STL file.
        fname = fullfile(directory, "sg_" + name + ".stl");
        % Create the model assuming the unit is millimeters
        tri = ps2stereographicsphere(ps, 'Radius', Radius, ... makes radius be 60mm
                                     'Model', Model,  ... mm
                                     'AddFeet', opts.FootRadius);
        % Write out the stl file.
        stlwrite(tri, fname);
        
    end
    
end

