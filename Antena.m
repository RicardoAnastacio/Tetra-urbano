function [Prx_dBmwithPrMin,visgridwithPrMin] = Antena(FigName,Title,BSpoint,elevation_map,lat_map,lng_map,R,f,Gtx1,Grx,Ptx,altAntena,prxMin,plotIndividualAntenna,model,type)
Gt=1;
Gr=1;
PointLong=BSpoint(1,1);
PointLat=BSpoint(1,2);
PointAlt=BSpoint(1,3);

load('Antena400MhzGain13.mat');
Ptxdb = 10*log10(Ptx/1e-3); % 100w
visgrid=logical(viewshed(elevation_map,R,PointLat,PointLong,altAntena,1));

%% dist
dist=deg2km(distance(PointLat,PointLong,lat_map,lng_map),'earth');
%disTerrestre=dist;
dist=sqrt(abs((PointAlt-dist)).^2+(dist.*1000).^2)/1000;

%% MODEL "LFS"
 LS=NaN(size(dist));
if model==1
    LS(visgrid)=PL_free(f,dist(visgrid),Gt,Gr);
end
if model==2
    LS(visgrid)=PL_Hata_modify(f,dist(visgrid).*1000,PointAlt+altAntena,elevation_map(visgrid),'URBAN');
end
if model==3
    LS(visgrid)=PL_IEEE80216d(f,dist(visgrid).*1000,type,PointAlt+altAntena,elevation_map(visgrid),'Okumura','MOD');
end
    
% LS(visgrid)=PL_Hata_modify(f,dist(visgrid).*1000,PointAlt+altAntena,elevation_map(visgrid),'URBAN');
% LS(visgrid)=PL_free(f,dist(visgrid),Gt,Gr);
% 
% 
% LS(visgrid)=PL_IEEE80216d(f,dist(visgrid).*1000,type,PointAlt+altAntena,elevation_map(visgrid),'Okumura','MOD');
%% 3D pattern antena
%Angle azimuth(lat1,lon1,lat2,lon2)
[az,elev,~] = geodetic2aer(lat_map,lng_map,elevation_map,PointLat,PointLong,(PointAlt+altAntena),wgs84Ellipsoid);
az1 = mod(round(az), 359);
elev1 = round(-elev + 90);
% az=round(az);
% elev= round(abs(elev-90));
at = reshape(Antena400MhzGain13.Attenuation, 360, [])';
Gtx = at(elev1 + az1.*181);

%% Prx
Prx_dBm=Ptxdb+Gtx+Gtx1+Grx-LS;
Prx_MinLogical=zeros(size(dist));
Prx_MinLogical(Prx_dBm>prxMin)=1;
%visgridwithPrMin(:,:,find(i==j))=and(A,visgrid(:,:,find(i==j)));
visgridwithPrMin(:,:)=and(Prx_MinLogical,visgrid(:,:));
Prx_dBmwithPrMin=NaN(size(dist));
Prx_dBmwithPrMin(visgridwithPrMin)=Prx_dBm(visgridwithPrMin);

% LFSssss=NaN(size(dist));
% tic
% for i=1:512
%     for j=1:512
%         dd=ismember(Antena400MhzGain13.Vert_Angle,elev(j,i)) & ismember(Antena400MhzGain13.Hor_Angle,az(j,i));
%         if(find(dd==1))
%             LFSssss(j,i)= Antena400MhzGain13.Attenuation(find(dd==1));
%         end
%     end
% end
% toc

%ang.hotizontal
% figure;
% mesh(lng_map(1,:), lat_map(:,1), az);

%ang.verical
% figure;
% mesh(lng_map(1,:), lat_map(:,1), elev);


if(plotIndividualAntenna)
    %% Coverage
    numberOnes(:,1)=sum(sum(visgrid));
    coverage=round((max(numberOnes/length(lng_map(:)))*100));
    %% color devision | Plot
    signalColor=colorLegend(Prx_dBmwithPrMin);
    figure('Name',FigName);
    subplot(1,2,1);
    axis tight
    mesh(lng_map(1,:), lat_map(:,1), elevation_map,signalColor);
    hold on
    title(strcat(Title,[' - Coverage: ',num2str(coverage),'%']));
    xlabel('Latitude (�)');
    ylabel('Longitude (�)');
    zlabel('Elevation (m)');
    scatter3(PointLong,PointLat,PointAlt+altAntena,'filled','v','m','SizeData',200);
    subplot(1,2,2);
    imshow('z_Legend.jpg');
    hold off
end
end