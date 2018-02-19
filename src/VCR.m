clear all;
close all;
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
scaleup = 10;   % ratio of scale up

%% import elemental image
infile=[fdir 'merged_image.png'];    outfile=[fdir, 'VCR/'];
mkdir(outfile);
original_ei=uint8(imread(infile));  [v h d]=size(original_ei);
eny = v/lens_y; enx = h/lens_x; 
% Calculate real focal length
f_ratio=36/sx;          % focal length ratio compared with Full frame camera
sy = sx * (v/h);
focal_length = focal_length*f_ratio;

EI = zeros(eny*scaleup,enx*scaleup,d,lens_y*lens_x,'uint8');
for x=1:lens_x
    for y=1:lens_y
        EI(:,:,:,x+(y-1)*lens_y) = imresize(original_ei((y-1)*eny+1:y*eny,(x-1)*enx+1:x*enx,:),[eny*scaleup enx*scaleup]);
    end
end
[EIy, EIx, Color] = size(EI(:,:,:,1));
%% VCR
time=[];
for Zr = start_dep:step_dep:end_dep
    tic;
    Shx = round((EIx*pitch*focal_length)/(sx*Zr));
    Shy = round((EIy*pitch*focal_length)/(sy*Zr));
    
    Img = (double(zeros(EIy+(lens_y-1)*Shy,EIx+(lens_x-1)*Shx, Color)));
    Intensity = (uint16(zeros(EIy+(lens_y-1)*Shy,EIx+(lens_x-1)*Shx, Color)));
    for y=1:lens_y
        for x=1:lens_x
            Img((y-1)*Shy+1:(y-1)*Shy+EIy,(x-1)*Shx+1:(x-1)*Shx+EIx,:) = Img((y-1)*Shy+1:(y-1)*Shy+EIy,(x-1)*Shx+1:(x-1)*Shx+EIx,:) + im2double(EI(:,:,:,x+(y-1)*lens_y));
            Intensity((y-1)*Shy+1:(y-1)*Shy+EIy,(x-1)*Shx+1:(x-1)*Shx+EIx,:) = Intensity((y-1)*Shy+1:(y-1)*Shy+EIy,(x-1)*Shx+1:(x-1)*Shx+EIx,:) + uint16(ones(EIy,EIx,Color));
        end
    end
    elapse=toc
    time=[time elapse];
    display(['--------------- Z =  ', num2str(Zr), ' is processed ---------------']);
    Fname = sprintf('VCR/%dmm.png',Zr);
    imwrite(Img./double(Intensity), [fdir Fname]);
end
csvwrite([fdir 'VCR/time.csv'],time);