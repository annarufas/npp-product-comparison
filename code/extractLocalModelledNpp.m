function nppModelLocalMonthlyMean = extractLocalModelledNpp(...
    filenameModelledNpp,filenameModelledNppProcessed,locationInformation)

    nNppModels = length(filenameModelledNpp);
    nLocs = height(locationInformation);
    
    % Load data
    load(fullfile('data','processed',filenameModelledNppProcessed),...
        'nppModelClimatologyStruct')

    % Initialise output array
    nppModelLocalMonthlyMean = NaN(12,nNppModels,nLocs);

    for iModel = 1:nNppModels

        % Get data from the structure
        fileName = erase(filenameModelledNpp{iModel},'.mat');
        fieldName = [fileName, '_plain']; 
        data = nppModelClimatologyStruct.(fieldName).data;
        lat = nppModelClimatologyStruct.(fieldName).lat;
        lon = nppModelClimatologyStruct.(fieldName).lon;

        % Prepare interpolation grid for the model's climatology data
        [Xpp, Ypp, Tpp] = ndgrid(lat, lon, (1:12)');
        Favg = griddedInterpolant(Xpp, Ypp, Tpp, data);

        for iLoc = 1:nLocs
            % Generate query grid for this location
            [qX, qY, qT] = ndgrid(locationInformation{iLoc,'latitude'},...
                locationInformation{iLoc,'longitude'}, (1:12)'); 
            % Extract data
            nppModelLocalMonthlyMean(:,iModel,iLoc) = squeeze(Favg(qX, qY, qT)); 
        end

    end

end % extractLocalModelledNpp
