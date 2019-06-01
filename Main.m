clearvars;clc;close all;
SAMPLES = 512;
alturaAntena=30;
% load('backup_Lisboa_512.mat')
 load('backup_Porto_512.mat')
% load('backup_512_new.mat')
% load('Antena400MhzGain13.mat');
disp('Displaying Data');
%% All Line-of-sight visibility points in terrain
latlim = [min(lat_map(:)), max(lat_map(:))];
lonlim = [min(lng_map(:)), max(lng_map(:))];
rasterSize = size(elevation_map);
%GEOREFCELLS Reference raster cells to geographic coordinates
R = georefpostings(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');

%% BBC
[BS1,BS2,BS3,BS4]=bestBsCoverage(elevation_map,lat_map,lng_map,R);
%------- Points
% points = maxElevation;
points = BS1;
points(2,:)=BS2;
points(3,:)=BS3;
points(4,:)=BS4;
%% BS1
[Prx_dBmBS1,visgridBS1]=Antena('BS1','Coverage Map - BS1',points(1,1),points(1,2),points(1,3),elevation_map,lat_map,lng_map,R);
%% BS2
[Prx_dBmBS2,visgridBS2]=Antena('BS2','Coverage Map - BS2',points(2,1),points(2,2),points(2,3),elevation_map,lat_map,lng_map,R);
%% BS3
[Prx_dBmBS3,visgridBS3]=Antena('BS3','Coverage Map - BS3',points(3,1),points(3,2),points(3,3),elevation_map,lat_map,lng_map,R);
%% BS4
[Prx_dBmBS4,visgridBS4]=Antena('BS4','Coverage Map - BS4',points(4,1),points(4,2),points(4,3),elevation_map,lat_map,lng_map,R);

%% PRX
%Prx_dBm=NaN(SAMPLES,SAMPLES);
Prx_dBm=Prx_dBmBS1;
Prx_dBm(visgridBS2)=Prx_dBmBS2(visgridBS2);
Prx_dBm(visgridBS3)=Prx_dBmBS3(visgridBS3);
Prx_dBm(visgridBS4)=Prx_dBmBS4(visgridBS4);

%% intrec��o pontos de visibilidade
%Sub=NaN(size(visgridBS1));
Sub=and(visgridBS1,visgridBS2);
Sub2=and(visgridBS1,visgridBS3);
Sub3=and(visgridBS2,visgridBS3);
Sub4=and(visgridBS2,visgridBS4);
Sub5=and(visgridBS4,visgridBS4);
Sub6=and(visgridBS1,visgridBS4);

%% Coverage Area 
orr=or(visgridBS1,visgridBS2);
orr=or(orr,visgridBS3);
orr=or(orr,visgridBS4);
numberOnes(:,1)=sum(sum(orr));
coverage=round((max(numberOnes/length(lng_map(:)))*100));
fprintf('Cobertura total: %d%% \n',coverage);

%% color devision
signalColor=colorLegend(Prx_dBm);
% mesh(lng_map(1,:), lat_map(:,1), elevation_map,signalColor);

%% Displays the data
figure('Name','BS1+BS2+BS3+BS4');
%subplot(1,2,1);
axis tight
mesh(lng_map(1,:), lat_map(:,1), elevation_map,signalColor);
hold on
title('Coverage Map - BS1 & BS2 & BS3 & BS4');
xlabel('Latitude (º)');
ylabel('Longitude (º)');
zlabel('Elevation (m)');
scatter3(points(1,1),points(1,2),points(1,3)+alturaAntena,'filled','v','m','SizeData',200);
scatter3(points(2,1),points(2,2),points(2,3)+alturaAntena,'filled','v','m','SizeData',200);
scatter3(points(3,1),points(3,2),points(3,3)+alturaAntena,'filled','v','m','SizeData',200);
scatter3(points(4,1),points(4,2),points(4,3)+alturaAntena,'filled','v','m','SizeData',200);
plot3(lng_map(Sub2),lat_map(Sub2),elevation_map(Sub2),'w.','markersize',5);
plot3(lng_map(Sub3),lat_map(Sub3),elevation_map(Sub3),'w.','markersize',5);
plot3(lng_map(Sub4),lat_map(Sub4),elevation_map(Sub4),'w.','markersize',5);
plot3(lng_map(Sub5),lat_map(Sub5),elevation_map(Sub5),'w.','markersize',5);
plot3(lng_map(Sub6),lat_map(Sub6),elevation_map(Sub6),'w.','markersize',5);
hold off
%subplot(1,2,2);
%imshow('z_Legend.jpg');

%% Antenna Patern Atenua��o 3d
load('Antena400MhzGain13.mat');
figure('Name','Antenna Patern Atenua��o 3D');
patternCustom(Antena400MhzGain13.Attenuation,Antena400MhzGain13.Vert_Angle,Antena400MhzGain13.Hor_Angle);

%% KML file
AA_func(lat_map(1),lat_map(SAMPLES,SAMPLES),lng_map(1),lng_map(SAMPLES,SAMPLES),Prx_dBm,'Coverage_map');

%% power image display
% imagesc(signalColor,[0 255]);


