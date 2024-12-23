function mapMonthlyNpp(filenameModelledNpp,filenameModelledNppProcessed)

    nNppModels = length(filenameModelledNpp);

    load(fullfile('data','processed',filenameModelledNppProcessed),...
        'globalNppStockSummary','nppModelClimatologyStruct')

    myColourScheme = [ones(1,3); jet(1000)];
    caxismin = 0; % mg C m-2 d-2
    caxismax = 1000; % mg C m-2 d-2
    cbString = 'NPP (mg C m^{-2} d^{-1})';
    isCommonColourBar = true;
    labelMonths = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

    for iModel = 1:nNppModels   
        for iMethod = 1:3
            switch iMethod
                case 1, label = 'plain';
                case 2, label = 'interpm1';
                case 3, label = 'interpm2';
            end

            % Get data from the structure
            fileName = erase(filenameModelledNpp{iModel}, '.mat');
            fieldName = [fileName, '_', label]; 
            data = nppModelClimatologyStruct.(fieldName).data;
            lat = nppModelClimatologyStruct.(fieldName).lat;
            lon = nppModelClimatologyStruct.(fieldName).lon;

            % Plot the dataset for the current product and the current method
            iDataset = (iModel - 1)*3 + iMethod;
            figureName = ['npp_monthly_',fileName,'_',label];
            plotOceanVariableMaps(data,lon,lat,myColourScheme,cbString,caxismin,...
                caxismax,isCommonColourBar,labelMonths,figureName,globalNppStockSummary{iDataset})

        end % iMethod
    end % iModel

end % mapMonthlyNpp