function mapAnnualNpp(filenameModelledNpp,filenameModelledNppProcessed)
    
    nNppModels = length(filenameModelledNpp);
    
    load(fullfile('data','processed',filenameModelledNppProcessed),...
        'globalNppStockSummary','nppModelClimatologyStruct')
    
    myColorScheme = [ones(1,3); jet(1000)];
    caxismin = 0; % mg C m-2 d-2
    caxismax = 1000; % mg C m-2 d-2
    cbString = 'NPP (mg C m^{-2} d^{-1})';
    isCommonColourBar = true;

    % The monthly NPP data arrays will be regridded to a commmon 1º lat x 1º lon
    qLat = linspace(-90,90,180); % query points for interpolation
    qLon = linspace(-180,180,360); % query points for interpolation
    [qX, qY, qT] = ndgrid(qLat, qLon, 1:12); % query grid with 12 time steps

    % Output annual array
    nppModelledAnnualMean = NaN(numel(qLat),numel(qLon),nNppModels*3);

    counter = 1;
    for iModel = 1:nNppModels 
        for iMethod = 1:3
            switch iMethod
                case 1, label = 'plain';
                case 2, label = 'interpm1';
                case 3, label = 'interpm2';
            end

            % Get data from the structure
            fieldName = [filenameModelledNpp{iModel}, '_', label]; 
            data = nppModelClimatologyStruct.(fieldName).data;
            lat = nppModelClimatologyStruct.(fieldName).lat;
            lon = nppModelClimatologyStruct.(fieldName).lon;

            % Regrid to common 1º lat x 1º lon
            [Xpp, Ypp, Tpp] = ndgrid(lat, lon, (1:12)'); % % original grid for the current dataset
            Favg = griddedInterpolant(Xpp, Ypp, Tpp, data);
            qNppAvg = squeeze(Favg(qX, qY, qT));

            % Compute the annual mean and store in the output array
            nppModelledAnnualMean(:,:,counter) = mean(qNppAvg,3,'omitnan');
            counter = counter + 1;

        end % iMethod
    end % iModel

    % Plot the annual mean data using the custom plotting function
    plotOceanVariableMaps(nppModelledAnnualMean,qLon,qLat,myColorScheme,cbString,...
        caxismin,caxismax,isCommonColourBar,globalNppStockSummary,'npp_annual',[])

end % mapAnnualNpp