function calculateGloballyIntegratedNpp(filenameInputNppModels,labelModels,...
    filenameOutputModelledNppProcessed)

% CALCULATEGLOBALLYINTEGRATEDNPP Calculates globally integrated net primary
% production (NPP) testing the effect of two interpolation methods (custom 
% and standard).

    nNppModels = length(labelModels);
    
    % Preallocate globally integrated NPP values
    globalNppStockSummary = cell(nNppModels*3,1); % summarised string representation of global NPP values
    nppModelClimatologyStruct = struct(); % structure to store processed NPP

    counter = 1;
    for iModel = 1:nNppModels
        productFileName = filenameInputNppModels{iModel};
        productName = labelModels{iModel};

        % Load raw NPP data
        load(fullfile('data','raw',strcat(productFileName,'.mat')),...
            'npp_lat','npp_lon','npp_avg') % mg C m-2 d-1

        % Calculate grid cell areas (m2) using Climate Data Toolbox
        [latGrid,lonGrid] = ndgrid(npp_lat,npp_lon); % cdtarea needs lat x lon (in that order)
        cellAreas = cdtarea(latGrid,lonGrid); % m2

        % Ensure NPP data dimensions match lat x lon (as in cellAreas)
        [nRowsNpp,nColsNpp,~] = size(npp_avg);
        if nRowsNpp > nColsNpp % dimensions are lon x lat x 12; transpose to lat x lon x 12
            nppGridOriginal = permute(npp_avg, [2, 1, 3]); 
        elseif nRowsNpp < nColsNpp
            nppGridOriginal = npp_avg;
        end

        % Perform two different interpolation methods on NPP data
        nppInterpolatedMethod1 = timeInterpolationCustom(nppGridOriginal,(1:12)); % custom time interpolation method
        nppInterpolatedMethod2 = timeInterpolationStandard(nppGridOriginal,(1:12)); % standard time interpolation method

        % Process and integrate data for each method
        for iMethod = 1:3
            switch iMethod
                case 1
                    label = 'plain';
                    nppData = nppGridOriginal;
                case 2
                    label = 'interpm1';
                    nppData = nppInterpolatedMethod1;
                case 3
                    label = 'interpm2';
                    nppData = nppInterpolatedMethod2;
            end

            % Replace NaN with 0 for summation purposes
            nppData(isnan(nppData)) = 0; 

            % Compute integrated global NPP stock
            nppStockMonthlyMean = nppData.*cellAreas; % mg C m-2 d-1 --> mg C d-1
            nppStockAnnualMean = mean(nppStockMonthlyMean,3).*(1e-3*1e-15*365); % mg C --> Pg C yr-1
            globalNppStock = sum(nppStockAnnualMean,'all'); % Pg C yr-1

            % Store results in the output string
            globalNppStockSummary{counter} = sprintf('%s %s: %.1f Gt C/yr', ...
                productName, label, globalNppStock);
            counter = counter + 1;

            % Save 3D data arrays in the output structure
            fieldName = [productFileName, '_', label];
            nppModelClimatologyStruct.(fieldName).data = nppData;
            nppModelClimatologyStruct.(fieldName).lat = npp_lat;
            nppModelClimatologyStruct.(fieldName).lon = npp_lon;

        end % iMethod
    end % iModel

    save(fullfile('data','processed',filenameOutputModelledNppProcessed),...
        'globalNppStockSummary','nppModelClimatologyStruct','-v7.3')
    
end % calculateGloballyIntegratedNpp