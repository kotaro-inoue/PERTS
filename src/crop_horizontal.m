%% static parameter
norm_posy = [3680, 4000]./4666;
norm_posx = [880, 3800]./4666;

%% setup parameter
fdir = '../dataset/iso/';
%method = 'VCR/';
method = 'PERTS/';
depth = 150;

%% crop
img = imread([fdir method num2str(depth) 'mm.png']);
[y,x,d] = size(img);
posy = round(norm_posy*y);
posx = round(norm_posx*x);
imwrite(img(posy(1):posy(2),posx(1):posx(2),:),[fdir method 'horizontal.png'])