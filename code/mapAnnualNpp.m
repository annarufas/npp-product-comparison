function mapAnnualNpp(filenameModelledNpp,filenameModelledNppProcessed)

    nNppModels = length(filenameModelledNpp);
    nGapFillingMethods = 2;
    
    load(fullfile('data','processed',filenameModelledNppProcessed),...
        'globalNppStockSummary','nppModelClimatologyStruct')
    
    myColourScheme = [ones(1,3); jet(1000)];
    caxismin = 0; % mg C m-2 d-2
    caxismax = 1000; % mg C m-2 d-2
    cbString = 'NPP (mg C m^{-2} d^{-1})';
    isCommonColourBar = true;

    % The monthly NPP data arrays will be regridded to a commmon 1º lat x 1º lon
    qLat = linspace(-90,90,180); % query points for interpolation
    qLon = linspace(-180,180,360); % query points for interpolation
    [qX, qY, qT] = ndgrid(qLat, qLon, 1:12); % query grid with 12 time steps

    % Output annual arrays
    nppModelledAnnualMeanAll = NaN(numel(qLat),numel(qLon),nNppModels*nGapFillingMethods);
    nppModelledAnnualMeanGapFilled = NaN(numel(qLat),numel(qLon),nNppModels);
    globalNppStockSummaryGapFilled = cell(nNppModels,1);

    counter = 1;
    for iModel = 1:nNppModels 
        for iMethod = 1:nGapFillingMethods
            switch iMethod
                case 1, label = 'plain';
                case 2, label = 'gapfilled';
            end

            % Get data from the structure
            fileName = erase(filenameModelledNpp{iModel},'.mat');
            fieldName = [fileName, '_', label]; 
            data = nppModelClimatologyStruct.(fieldName).data;
            lat = nppModelClimatologyStruct.(fieldName).lat;
            lon = nppModelClimatologyStruct.(fieldName).lon;

            % Regrid to common 1º lat x 1º lon
            [Xpp, Ypp, Tpp] = ndgrid(lat, lon, (1:12)'); % original grid for the current dataset
            Favg = griddedInterpolant(Xpp, Ypp, Tpp, data);
            qNppAvg = squeeze(Favg(qX, qY, qT));

            % Compute the annual mean and store in the output array
            nppModelledAnnualMeanAll(:,:,counter) = mean(qNppAvg,3,'omitnan');
            counter = counter + 1;
            
            if (iMethod == 2)
                iDataset = (iModel - 1)*nGapFillingMethods + iMethod;
                titleStr = strrep(globalNppStockSummary{iDataset}, ' gapfilled', '');
                nppModelledAnnualMeanGapFilled(:,:,iModel) = mean(qNppAvg,3,'omitnan');
                globalNppStockSummaryGapFilled{iModel} = titleStr;
            end

        end % iMethod
    end % iModel

    % Plot the annual mean data for all methods using the custom plotting function
    plotOceanVariableMaps(nppModelledAnnualMeanAll,qLon,qLat,myColourScheme,cbString,...
        caxismin,caxismax,isCommonColourBar,globalNppStockSummary,'npp_annual_comp',[])

    % Plot the annual mean data for gap-filled data using the custom plotting function
    plotOceanVariableMaps(nppModelledAnnualMeanGapFilled,qLon,qLat,myColourScheme,cbString,...
        caxismin,caxismax,isCommonColourBar,globalNppStockSummaryGapFilled,'npp_annual_gapfilled',[])

end % mapAnnualNpp