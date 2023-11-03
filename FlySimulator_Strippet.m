function FlySimulator_Strippet %% AEWS - Control Buttons
    fig=figure('Position',[100 100 900 500]);
    set(fig,'WindowKeyPressFcn',@KeyPress);   
    hold on;
    % Disable axis viewing, don't allow axes to clip the plane
    axis vis3d off;      
    fig.Children.Visible = 'off';
    fig.Children.Clipping = 'off';
    fig.Children.Projection = 'perspective';     
    % Init variables you may Change
    forwardVec = [1 0 0]'; %Vector of the plane's forward direction in plane frame
    pos = [-20000 0 100];       %Initial plane position
    vel = 300;               %Velocity or speed   
    tForrest = imread('forrest.jpg');
    % Add some cool islands
    [x,y,z] = peaks(100);
    surf(x*400,y*400,z*30-1,'LineStyle','none','FaceColor','texturemap','CData',tForrest);    
    surf(x*400+15000,y*400+3000,z*150-1,'LineStyle','none','FaceColor','texturemap','CData',tForrest); 
    % Make a big sea 
    xy = -100000:5000:100000;
    sufFlat=surf(xy,xy,0*ones(41));
    sufFlat.FaceColor = 'texturemap';
    sufFlat.CData = imread('sea.jpg');   
    rot = eye(3,3);        %Initial plane rotation - none
    vert = 0;
    p1 = [];
    matRot = eye(3);       % Unity Patrix
    InitPlane();           % Load the Aeroplane
    tic;                   % timing stuff
    told = 0;
    light('Position',[-20000 0 5000],'Style','local') % Lyskilde

    function UpdateCamera()
         campos(pos' - 2000*rot*[1 0 -0.04]');
         camtarget(pos' + 100*rot*[1 0 0]'); 
    end
    % Main Loop
    while(ishandle(fig))
         rot = rot * matRot;
         matRot = eye(3,3); 
         tnew = toc;  
         %Update the plane's vertices using the new position and rotation
         pos = vel*(rot*forwardVec*(tnew-told))' + pos;
         p1.Vertices = (rot*vert')' + repmat(pos,[size(vert,1),1]); 
         told = tnew;     
         UpdateCamera();
         pause(0.1);
    end
    %% Press a Key
    function KeyPress(varargin)
         key = varargin{2}.Key;
         if (key=='q')
             matRot = MR(0.05,0,0);
         elseif (key=='e')
             matRot = MR(-0.05,0,0);
         elseif (key=='w')
             matRot = MR(0,0.05,0);
         elseif (key=='s')
             matRot = MR(0,-0.05,0);
         end
    end
    %% Rotation Matrix
    function M = MR(yaw,pitch,roll)
        m1 = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
        m2 = [cos(pitch) 0 sin(pitch); 0 1 0; -sin(pitch) 0 cos(pitch)];
        m3 = [1 0 0; 0 cos(roll) -sin(roll); 0 sin(roll) cos(roll)];
        M = m3*m2*m1;
    end
    %% Initialize the plane
    function InitPlane()
        fv = stlread('a10.stl');       
        p1 = patch(fv,'FaceColor','red','EdgeColor','none', ...
            'FaceLighting','gouraud','AmbientStrength', 0.35 );
        vert = p1.Vertices;     
    end
end
% %          'FaceLighting',    'gouraud',     ...
