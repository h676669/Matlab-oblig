% Taster:  QE: Venstre/H�yre  AD rulle  
% W S Opp/Ned  P/M : �k/Sent hastighet
% V - Endre Observarsjonspunkt
function FLYSIM
    %% Intro stuff
    close all
    
    %% Init Stuff - may be changed
    FRAMES      = 60;               % 2->
    SURFACES    = 50;               % 4 ->
    firstPerson = true;             % Do we start in 1st person view, or not?
    vel         = 800;              % Velocity
    kwt         = 1000;             % Battery Level
    posStart    =[-25000,0,3000];   % Start position
    forwardVec  = [1 0 0]';         % Initial direction of the plane
    colorP      = 'magenta';        % Color of plane
    scaleP      = 1.3;              % Scale plane 
    maxFart     = 1500;             % Max Speed of the plane
    telleframes = 0;                % Counts frames 
    
    textureDesert = imread('bilder\desert.jpg');
    textureSea = imread('bilder\sea.jpg');
    textureForrest = imread('bilder\forrest.jpg');
    textureMountain = imread('bilder\Mountain.jpg');
    textureIsland = imread('bilder\forrest.jpg');
        
    %% Other variables
    matRot   = eye(3);
    vert = 0;                       % Vertices of the airplane
    p1 = [];                        % The plane surfaces
    txtKwh = 0;                     % Control kwh
    txt1 = 0;                       % Control speed
    txt2 = 0;                       % Control height
    pos = posStart;
    rot = matRot;
    s1 = [];                        % Surface 1
    s2 = [];                        % Surface 2
    s3 = [];                        % Surface 3
    sufFlat = [];                   % Surface sea
    pe = 0;                         % Engine Sound
    as = 0;   
    fig = figure;
    hold on;
    fig.Position = [100 100 700 600];   % Size of program
    endret = false;                     % Texture change

    % Disable axis viewing, don't allow axes to clip the plane
    fig.Children.Visible = 'off';
    fig.Children.Clipping = 'off';
    fig.Children.Projection = 'perspective';
    
    InitControls();
    InitPlane();
    AddSky();
    AddSurface();
    AddIslands();
   
    %% Set keyboard callbacks and flags for movement.
    set(fig,'WindowKeyPressFcn',@KeyPress,'WindowKeyReleaseFcn', @KeyRelease);
    hold off
    axis([-10000 10000 -10000 10000 -10000 10000])
	tic
    told = 0;
    
    %% Read the enginee file and start the Engine
    EngineSound();
    
    %% Enter the main loop
    MainLoop();

    %% Enter the Mail Loop of Flying
    function MainLoop  
    while(ishandle(fig))
        tnew = toc;      
        rot = rot * matRot;
        %Update plane's center position.
        z = pos(3);
        pos = vel*(rot*forwardVec*(tnew-told))' + pos;
        %If empty battery - let the plane fall
        if (kwt < 0) % No more kwh
            pos(3) = z - 100;
        end
        %Update the plane's vertice new position and rotation
        p1.Vertices = (rot*vert')' + repmat(pos,[size(vert,1),1]); 
        % Check if plane crashes into grounds
        if TestCrash
            return
        end    
        UpdateCamera();
        told = tnew;
        pause(1/FRAMES);

        UpdateFuel();
        telleframes = telleframes + 1; 
        ShowInfo();     
        if(mod(telleframes, FRAMES) == 0)
            AlarmSound();
        end
    end
    end        
    %%
    function [fTC]= TestCrash()
        z = pos(3)-20;
        if  z < 0  || z < GetZ(s1, pos) || z < GetZ(s2,pos)
            Crash();
            fTC= true;
        elseif kwt < 0 
            Crash();
            fTC = true;
        elseif vel <= 100
            Crash();
            fTC = true; 
        else   
            fTC=false;
        end
    end
    %% Add some Islands
    function AddIslands
        %% Define a mountain island
        [x,y,z] = peaks(SURFACES);
        x = x * 3000+30000;
        y = y * 6000-4000;
        z = z * 1200 - 1300;
        s1=surf(x,y,z, ...
               'LineStyle','none','AmbientStrength',0.7);
        s1.FaceColor = 'texturemap';
        s1.CData = textureMountain;    
        
        %% Define a forrest island
        x = -2:2/sqrt(SURFACES):2;
        y = -4:2/sqrt(SURFACES):4;
        [X,Y] = meshgrid(x,y);
        Z = X.*(exp(-X.^2-Y.^2)+exp(-X.^2-(Y-2).^2));
        X = X * 4000;
        Y = Y * 3000;
        Z = Z * 2000;
        s2 = surf(X,Y,Z, 'LineStyle','none', ...
                     'SpecularStrength',0, ...
                     'AmbientStrength',0.7,'SpecularColorReflectance',1);
        s2.FaceColor = 'texturemap';
        s2.CData = textureForrest;

        %% Define a desert island
        % Spawn's behind start position
        [x1,y1,z1] = peaks(SURFACES);
        x1 = x1 * 3000-51000;
        y1 = y1 * 6000;
        z1 = z1 * 300;
        s3 = surf(x1,y1,z1, ...
               'LineStyle','none','AmbientStrength',0.7);
        s3.FaceColor = 'texturemap';
        s3.CData = textureDesert;
    end
    %% Update Camera positions and rotation
    function UpdateCamera()
        if firstPerson %First person view -- follow the plane from slightly behind.
            camupvec = rot*[0 0 1]';
            camup(camupvec);
            x = 1000;
            campos(pos' - x*rot*[1 0 -0.15]');
            camtarget(pos' + 100*rot*[1 0 0]');    
        else %Follow the plane from a fixed angle
            campos(pos + [-1500,500,500]);
            camtarget(pos);
        end 
    end
    %% Check kwh left
    function UpdateFuel
        if (kwt < 0)
            EngineStop();
        else
            kwt = kwt - 0.003 - vel*vel/10000000;
        end 
    end


    %% Show Flight Info
    function ShowInfo()
        if (isvalid(fig)==false) 
            return;
        end
        txtKwh.String = "KWh : " + int2str(kwt);  
        txt2.String = sprintf('Speed: %s  Height: %s', ...
            int2str(vel), int2str(pos(3)) );
        x = int2str(pos(1)); y = int2str(pos(2));
        txt1.String = sprintf('Coord: (X: %s, Y: %s)', x, y);
    end    
    %% Add Control panels
    function InitControls
        h = [];          
        inst = uipanel('Title','Instruments','Position',[.3 .01 .4 .15]);
        h(end+1)  = inst;

        fuel = uipanel('Title','Fuel','Position',[.75 .01 .2 .15]);
        fuel.Title = 'Battery: ';

        h(end+1)  = fuel;
        txtKwh = uicontrol(fuel,'Style','text','Position',[3,3,140,30]);
        h(end+1)  = txtKwh;
        txt1 = uicontrol(inst,'Style','text','Position',[3,3,250,30]);
        h(end+1)  = txt1;
        txt2 = uicontrol(inst,'Style','text','Position',[3,30,250,30]);
        h(end+1)  = txt2;
        set(h, 'FontSize', 14);
        set(h, 'BackgroundColor', 'green');
        EndreTexture = uicontrol('Style','pushbutton', ...
            'String','endre', 'Position', [35,185,100,35], ...
            'Callback', @f_Callback);

        function f_Callback(~,~)
            if (endret == false)
                s1.CData = textureDesert;
                s2.CData = textureSea;
                s3.CData = textureMountain;
                sufFlat.CData = textureIsland;
                endret = true; 
                disp("endre til standard")
                disp(endret);
            
            elseif (endret == true)
                s1.CData = textureMountain;
                s2.CData = textureForrest;
                s3.CData = textureDesert;
                sufFlat.CData = textureSea;
                endret = false; 
                disp("endre til ustnandar");
                disp(endret);
            end
        end
    end

    %% Initialize the plane
    function InitPlane()
        fv = stlread('a10.stl');    
        vert = 0;       
        delete(findobj('type', 'patch'));
        p1 = patch(fv,'FaceColor',       colorP, ...
         'EdgeColor',       'none',        ...
         'FaceLighting',    'gouraud',     ...
         'AmbientStrength', 0.35);
     
        % rotate(p1, [1 0 0 ], 180);
        p1.Vertices = p1.Vertices .* scaleP;
        vert = p1.Vertices;
    end
    %% Add the sky as a giant sphere (fly inside...)
    function AddSky
        [skyX,skyY,skyZ] = sphere(SURFACES);
        sky = surf(500000*skyX, 500000*skyY, 500000*skyZ, 'LineStyle','none');
        sky.FaceColor = 'cyan';
        light('Position',[-5000 0 0],'Style','local')
    end
    %% add flat ground (Ocean) going off to (basically) infinity.
    function AddSurface
        k = 100000 / SURFACES;
        [x,y] = meshgrid(-500000:k:500000);
        z = x .* 0;
        sufFlat = surf(x,y,z);
        sufFlat.FaceColor = 'texturemap';
        sufFlat.CData = textureSea;
        sufFlat.AlphaData = 0.1;
        camlight('headlight');
        camva(40); %view angle
    end
    %% Trap press Key
    function KeyPress(varargin)
        key = varargin{2}.Key;
         if (key=='v')
             firstPerson = ~firstPerson;
         elseif (key=='p' && vel <= maxFart) % Speed 
             vel = max(5, vel * 1.05);
         elseif (key=='m') % Slow down
             vel = vel * 0.95;
         elseif (key=='q')
             matRot = MR(0.05,0,0);
         elseif (key=='e')
             matRot = MR(-0.05,0,0);
         elseif (key=='w')
             matRot = MR(0, 0.05,0);
         elseif (key=='s')
             matRot = MR(0, -0.05,0);
         elseif (key=='a')
             matRot = MR(0, 0, 0.05);
         elseif (key=='d')
             matRot = MR(0, 0, -0.05);
         end           
    end
    %% Trap Key Release
    function KeyRelease(varargin)
         matRot = eye(3); % Unit Matrix
    end
    %% Rotation Matrix
    function M = MR(yaw,pitch,roll)
        % Rotate a graphics object along Z-Y-X axes in the earth frane 
        m1 = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
        m2 = [cos(pitch) 0 sin(pitch); 0 1 0; -sin(pitch) 0 cos(pitch)];
        m3 = [1 0 0; 0 cos(roll) -sin(roll); 0 sin(roll) cos(roll)];
        M = m3*m2*m1;
    end
    %% Make Engine Sound
    function EngineSound()
        [es,fs] = audioread('lyd\engine.wav');
        pe = audioplayer(es,fs);
        if isplaying(pe)
            stop(pe);        
        end
        play(pe);
    end
    %% Make Alarm sound
    function AlarmSound()
        [lyd1, lyd2] = audioread('lyd\beep-01a.wav');
        as = audioplayer(lyd1, lyd2);
        if(GetZ(p1, pos)>= 1500)
            play(as);
            stop(as);
        end
        disp(GetZ(p1, pos))
    end
    %% Engine Stop Sound
    function EngineStop()
        stop(pe);
    end    
    %% Crash Sound
    function Crash()
        [xs,f] = audioread('lyd\OOF.wav');
        pe = audioplayer(xs,f);
        play(pe);  
        p1.FaceColor = "Black";       
    end
    %% Get the Z of the surface given a position
    function z0 = GetZ(s, pos)
        z0 = interp2(s.XData,s.YData,s.ZData,pos(1),pos(2) );
    end
end