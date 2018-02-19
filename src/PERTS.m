clear;

%% Parameter of experiment
fdir = '../dataset/iso/';
lens_x = 10; % number of lenslet
lens_y = 10;
start_dep = 150;
end_dep = 150;
step_dep = 1;
pitch = 2;   % pitch of lenslet
sx = 36;     % sensor size of horizontal axis
focal_length = 50;  % focal length of main lens

%% import elemental image
infile=[fdir 'merged_image.png'];    outfile=[fdir, 'PERTS/'];
mkdir(outfile);
ei=uint8(imread(infile));  [v h d]=size(ei);
eny = v/lens_y; enx = h/lens_x; 
% Calculate real focal length
f_ratio=36/sx;          % focal length ratio compared with Full frame camera
sy = sx * (v/h);
F=focal_length*f_ratio;       % Effective focal length

%% perts
time=[];
mspace=[];

% Reconstruction
for dep=start_dep:step_dep:end_dep
    tic;
    min_space = 0;
    x=dep*sx/F;   % projection area for each elemental image
    y=dep*sy/F;
    xe=x/enx;   % projection area for each pixel
    ye=y/eny;
    % x and y directional matrix
    x_v=1:h;    y_v=1:v;
    % marginal floating point for convenience of computation
    fp_x=1/(2^((lens_x-1)/2));    
    fp_y=1/(2^((lens_y-1)/2));
    % calculate the position value in the x and y directions
    px=(xe.*((x_v-enx.*floor(x_v./(enx+fp_x)))-0.5)) + (pitch.*floor(x_v./(enx+fp_x)));    
    py=(ye.*((y_v-eny.*floor(y_v./(eny+fp_y)))-0.5)) + (pitch.*floor(y_v./(eny+fp_y)));
    % Sorting the position of projected pixel on reconstruction plane in x and y directions
    [sort_x, sort_xi]=sort(px);    
    [sort_y, sort_yi]=sort(py);
    % Calculation : Minimum space (Minimum space will be 1px distance in reconstructed image)
    dx = diff(sort_x);
    dy = diff(sort_y);
    min_space = min([dx dy])
    
    % pixel rearrangement
    temp=ei(:,sort_xi,:);
    img=temp(sort_yi,:,:);  %img is sort image
    
    dx = [dx 0];
    dy = [dy 0];
    
    % Calculation : Pixel Size on the Projection Plane
    pixel_x = round(xe/min_space);
    pixel_y = round(ye/min_space);
    
    Pixel_arr_x = uint16(zeros(enx*lens_x*2,1));
    Pixel_arr_y = uint16(zeros(eny*lens_y*2,1));
    count = 1;
    Ix=1;
    for x = 1:2:enx*lens_x*2
        Pixel_arr_x(x) = pixel_x;
        Pixel_arr_x(x+1) = round(dx(count)/min_space);
        Ix = Ix + Pixel_arr_x(x+1);
        count = count + 1;
    end
    count = 1;
    Iy=1;
    for y = 1:2:eny*lens_y*2
        Pixel_arr_y(y) = pixel_y;
        Pixel_arr_y(y+1) = round(dy(count)/min_space);
        Iy = Iy + Pixel_arr_y(y+1);
        count = count + 1;
    end
   
    % memory allocation
    Ix = Ix + Pixel_arr_x(enx*lens_x*2-1)-1;
    Iy = Iy + Pixel_arr_y(eny*lens_y*2-1)-1;
    out = uint16(zeros(Iy,Ix,3));
    Intensity = uint8(zeros(Iy,Ix));
    
    % pixel resizing
    posx=1;
    imgx=1;
    for x=1:2:enx*lens_x*2
        imgy=1;
        posy=1;
        for y=1:2:eny*lens_y*2
            out(posy:posy+Pixel_arr_y(y)-1,posx:posx+Pixel_arr_x(x)-1,:) =...
                out(posy:posy+Pixel_arr_y(y)-1,posx:posx+Pixel_arr_x(x)-1,:) + repmat(uint16(img(imgy,imgx,:)),Pixel_arr_y(y),Pixel_arr_x(x));
            Intensity(posy:posy+Pixel_arr_y(y)-1,posx:posx+Pixel_arr_x(x)-1) =...
                Intensity(posy:posy+Pixel_arr_y(y)-1,posx:posx+Pixel_arr_x(x)-1) + uint8(ones(Pixel_arr_y(y),Pixel_arr_x(x)));
            posy = posy + Pixel_arr_y(y+1);
            imgy=imgy+1;
        end
        posx = posx + Pixel_arr_x(x+1);
        imgx=imgx+1;
    end
    elapse = toc
    time=[time elapse];
    mspace =[mspace min_space];
    
    % resize the reconstructed image to match CIIR aspect ratio
    Shx = round((enx*lens_x*pitch*F)/(sx*dep));
    Shy = round((eny*lens_y*pitch*F)/(sy*dep));
    CIIR_x = enx*lens_x+(lens_x-1)*Shx;
    CIIR_y = eny*lens_y+(lens_y-1)*Shy;
    out2 = uint8(out./uint16(repmat(Intensity,1,1,3)));
    
    imwrite(imresize(out2,[CIIR_y CIIR_x]), [outfile, num2str(dep), 'mm.png']);
    display(['----- Processing is completed at ', num2str(dep), 'mm display plane. -----']);
end
csvwrite([fdir 'PERTS/time.csv'],time);
csvwrite([fdir 'PERTS/min.csv'],mspace);
