clearvars;clc;close all;
SAMPLES = 512;
%%Variaveis
f= 400e6; %Hz
Gtx=1; %db
Grx=1; % dB
Ptx=100;%w
altAntena=30; %metros
prxMin=-90;
coverageTarget=95;
passo=3000;
load('backup_512.mat');

%% Map Resolution
fprintf('Map resolution = %.2fmetros \n',deg2km(distance(lat_map(11),lng_map(11),lat_map(12),lng_map(12)),'earth')*1000);

%% All Line-of-sight 5isibility points in terrain
latlim = [min(lat_map(:)), max(lat_map(:))];
lonlim = [min(lng_map(:)), max(lng_map(:))];
rasterSize = size(elevation_map);
%GEOREFCELLS Reference raster cells to geographic coordinates
R = georefpostings(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');

%% BestBSCoverage
[BS]=bestBsCoverage(elevation_map,lat_map,lng_map,R,passo,coverageTarget,f,Gtx,Grx,Ptx,altAntena,prxMin);
Prx_dBmBS=NaN(size(lat_map));
visgridBS=NaN(size(lat_map));
visgridALL=zeros(size(lat_map));
for i=1:length (BS(:,1))
    [Prx_dBmBS(:,:,i),visgridBS(:,:,i)] = Antena(['BS',num2str(i)],['BS',num2str(i)],BS(i,:),elevation_map,lat_map,lng_map,R,f,Gtx,Grx,Ptx,altAntena,prxMin);
    visgridALL=or (visgridALL,visgridBS(:,:,i));
end
visgridBS=logical(visgridBS);
[~,bestServerPixel]=max(Prx_dBmBS,[],3);
bestServerPixel(~visgridALL)=NaN;

figure('Name','BestServerPixel');
surf(lng_map(1,:), lat_map(:,1), elevation_map,'DisplayName','','HandleVisibility','off');
hold on
for i=1:length (BS(:,1))
    str=['BS',num2str(i)];
    plot3(lng_map(bestServerPixel==i),lat_map(bestServerPixel==i),elevation_map(bestServerPixel==i),'.','DisplayName',str);
end
legend;
title('BestServerPixel');
hold off

%% PRX
Prx_dBm=NaN(size(lat_map));
serverVisgrid=zeros(size(lat_map));
for i=1:length (BS(:,1))
    serverVisgrid=logical(bestServerPixel==i);
    auxprx=Prx_dBmBS(:,:,i);
    Prx_dBm(serverVisgrid)=auxprx(serverVisgrid);
end

%% Co-Canal
Sub=NaN(size(visgridBS(:,:,1)));
CoCanal = "-----------------";
CoCanal = [CoCanal ; "Inter�ncia Co-Canal (Valor m�dio)"];
CoCanal = [CoCanal ; "-----------------"];
for i=1:length (BS(:,1))
    for j=1:length (BS(:,1))
        if(j~=i)
            Sub=and(visgridBS(:,:,i),visgridBS(:,:,j));
            CC=10.^((Prx_dBmBS(:,:,i))./10).*Sub;
            II=10.^((Prx_dBmBS(:,:,j))./10).*Sub;
            XX=CC./II;
            CI_=XX(XX<=1);
            %           CI=CI_(CI_>=0);% nao tenho a certeza se metemos esta linha ou nao (meti pq dava valor negativo sem ela)
            CI_m=round(mean(CI_,'omitnan'),2);
            CoCanal = [CoCanal ; 'BS',num2str(i) 'c/ BS',num2str(j) '=',num2str(CI_m)];
            %             fprintf('BS%d c/ BS%d = %.2f \n',i,j,CI_m);
        end
    end
    CoCanal = [CoCanal ; "-----------------"];
end
disp(CoCanal);

%% Coverage Area
coverageTotal=logical(visgridALL);
numberOnes(:,1)=sum(sum(coverageTotal));
coverageTotal=round((max(numberOnes/length(lng_map(:)))*100));

%% color devision
signalColor=colorLegend(Prx_dBm);

%% Displays the data
figure('Name','Todas as BS');
subplot(1,2,1);
axis tight
mesh(lng_map(1,:), lat_map(:,1), elevation_map,signalColor);
hold on
title(strcat(['Coverage map : ',num2str(coverageTotal),'%']));
xlabel('Latitude (º)');
ylabel('Longitude (º)');
zlabel('Elevation (m)');
for i=1:length (BS(:,1))
    scatter3(BS(i,1),BS(i,2),BS(i,3)+10,'filled','v','m','SizeData',200);
end
hold off
subplot(1,2,2);
imshow('z_Legend.jpg');

%% Antenna Patern Atenua��o 3d
load('Antena400MhzGain13.mat');
figure('Name','Antenna Patern Atenua��o 3D');
patternCustom(Antena400MhzGain13.Attenuation,Antena400MhzGain13.Vert_Angle,Antena400MhzGain13.Hor_Angle);

%% KML file
exportKmlBsLocations(BS, 'BsLocations');
BestServerPixel(lat_map(1),lat_map(SAMPLES,SAMPLES),lng_map(1),lng_map(SAMPLES,SAMPLES),bestServerPixel,'BestServerPixel');
AA_func(lat_map(1),lat_map(SAMPLES,SAMPLES),lng_map(1),lng_map(SAMPLES,SAMPLES),Prx_dBm,'Coverage_map');
% exportKmlBsLoS(BS, 'Los');
