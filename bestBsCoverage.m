function bestBsCoverage(elevation_map,lat_map,lng_map,R)
altAntena=30; %metros
passo=300;
tic
i=1:passo:size(lat_map(:));
% mesh(lng_map(1,:), lat_map(:,1), elevation_map);
% hold on
% plot3(lng_map(i),lat_map(i),elevation_map(i),'r.','markersize',10);
% hold off

%% visgrid(:,:,indx)
try
    load (['backup_vigrid_passo_' num2str(passo)]);
catch
    tic
    viewshed(elevation_map,R,lat_map(256),lng_map(256),9999999,1);
    maxVisgridTime=toc;
    s=seconds(round(length(i)*maxVisgridTime));
    s.Format = 'hh:mm:ss';
    fprintf('Maxima dura��o prevista: %s \n',s);
    for j = i
        visgrid(:,:,find(i==j))=logical(viewshed(elevation_map,R,lat_map(j),lng_map(j),altAntena,1));
    end
    ss=seconds(round(toc));
    ss.Format = 'hh:mm:ss';
    fprintf('Dura��o real: %s \n',ss);
    save(['backup_vigrid_passo_' num2str(passo)],'visgrid');
end

end
