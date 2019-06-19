clearvars;clc;close all;
SAMPLES = 512;
alturaAntena=30;
load('backup_512.mat');
disp('Displaying Data');

%% All Line-of-sight 5isibility points in terrain
latlim = [min(lat_map(:)), max(lat_map(:))];
lonlim = [min(lng_map(:)), max(lng_map(:))];
rasterSize = size(elevation_map);
%GEOREFCELLS Reference raster cells to geographic coordinates
R = georefpostings(latlim,lonlim,rasterSize,'ColumnsStartFrom','north');

%% BestBSCoverage
coverageTarget=75;
[BS]=bestBsCoverage(elevation_map,lat_map,lng_map,R,coverageTarget,alturaAntena);

Prx_dBmBS=NaN(size(lat_map));
visgridBS=NaN(size(lat_map));
for i=1:length (BS(:,1))
    [Prx_dBmBS(:,:,i),visgridBS(:,:,i)]=Antena(['BS',num2str(i)],['BS',num2str(i)],BS(i,:),elevation_map,lat_map,lng_map,R);
end
visgridBS=logical(visgridBS);


%% PRX
 Prx_dBm=Prx_dBmBS(:,:,1);
for i=1:length (BS(:,1))
    auxPrx=Prx_dBmBS(:,:,i);
    auxVisgrid=visgridBS(:,:,i);
    Prx_dBm(auxVisgrid)=auxPrx(auxVisgrid);
end

% powerByBestBS
combs=combinationsWithoutRepeating(length(BS(:,1)),length(BS(:,1)));
intersect=NaN(size(visgridBS(:,:,1)));
cenas1=NaN(size(visgridBS(:,:,1)));
cenas2=NaN(size(visgridBS(:,:,1)));
for i=1:length (combs(:,1))
    intersect(:,:,i)=and(visgridBS(:,:,combs(i,1)),visgridBS(:,:,combs(i,2)));
    auxPrx1=Prx_dBmBS(:,:,combs(i,1));
    auxPrx2=Prx_dBmBS(:,:,combs(i,2));
    auxVisgrid=logical(intersect(:,:,i));
    auxx1(auxVisgrid)=auxPrx1(auxVisgrid);
    auxx2(auxVisgrid)=auxPrx2(auxVisgrid);
    cenas1=logical(auxx1> auxx2);
    Prx_dBm(cenas1)=auxPrx1(cenas1);
    cenas2=logical(auxx2> auxx1);
    Prx_dBm(cenas2)=auxPrx2(cenas2);

end

for i=1:3
    figure;
    title=('teste');
    mesh(lng_map(1,:), lat_map(:,1), elevation_map,intersect(:,:,i));
end


%% Co-Canal
Sub=NaN(size(visgridBS(:,:,1)));
inter=NaN(size(visgridBS(:,:,1)));
fprintf('-----------------\n\n\n')
fprintf('Inter�ncia Co-Canal (Valor m�dio)\n')
fprintf('-----------------\n')
for i=1:length (BS(:,1))
    for j=1:length (BS(:,1))
        if(j~=i)
            Sub=and(visgridBS(:,:,i),visgridBS(:,:,j));
            CC=10.^((Prx_dBmBS(:,:,i))./10).*Sub;
            II=10.^((Prx_dBmBS(:,:,j))./10).*Sub;
            XX=CC./II;
            CI_=XX(XX<=1);
            %           CI=CI_(CI_>=0);% nao tenho a certeza se metemos esta linha ou nao (meti pq dava valor negativo sem ela)
            CI_m=mean(CI_,'omitnan');
            fprintf('BS%d c/ BS%d = %.2f \n',i,j,CI_m)
        end
    end
    fprintf('-----------------\n')
    inter(:,:,i)=Sub;
end


%% Coverage Area
coverageTotal=Prx_dBm;
coverageTotal(isnan(coverageTotal))=0;
coverageTotal=logical(coverageTotal);
numberOnes(:,1)=sum(sum(coverageTotal));
coverageTotal=round((max(numberOnes/length(lng_map(:)))*100));

%% color devision
signalColor=colorLegend(Prx_dBm);

%% Displays the data
figure('Name','Todas as BS');
%subplot(1,2,1);
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
% for i=1:length (Sub(1,1,:))
%     auxInter=logical(inter(:,:,i));
%     plot3(lng_map(auxInter(:)),lat_map(auxInter(:)),elevation_map(auxInter(:)),'o','markersize',1);
% end

hold off
%subplot(1,2,2);
%imshow('z_Legend.jpg');

%% Antenna Patern Atenua��o 3d
load('Antena400MhzGain13.mat');
figure('Name','Antenna Patern Atenua��o 3D');
patternCustom(Antena400MhzGain13.Attenuation,Antena400MhzGain13.Vert_Angle,Antena400MhzGain13.Hor_Angle);

%% KML file
exportKmlBsLocations(BS, 'BsLocations');
AA_func(lat_map(1),lat_map(SAMPLES,SAMPLES),lng_map(1),lng_map(SAMPLES,SAMPLES),Prx_dBm,'Coverage_map');
exportKmlBsLoS(BS, 'Los');

%% power image display
% imagesc(signalColor,[0 255]);