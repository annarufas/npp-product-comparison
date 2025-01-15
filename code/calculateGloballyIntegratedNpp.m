function calculateGloballyIntegratedNpp(filenameInputModelledNpp,...
    filenameInputCustomMask,labelModels,filenameOutputModelledNpp)

% CALCULATEGLOBALLYINTEGRATEDNPP Calculates globally integrated net primary
% production (NPP) testing the effect of a gap-filling method.

    nNppModels = length(labelModels);
    nGapFillingMethods = 2;
    
    % Preallocate globally integrated NPP values
    globalNppStockSummary = cell(nNppModels*nGapFillingMethods,1); % summarised string representation of global NPP values
    nppModelClimatologyStruct = struct(); % structure to store processed NPP

    counter = 1;
    for iModel = 1:nNppModels
        productFileName = filenameInputModelledNpp{iModel};
        productName = labelModels{iModel};

        % Load raw NPP data, mg C m-2 d-1
        load(fullfile('data','raw',productFileName),'npp_lat','npp_lon','npp_avg')

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
        
        % Load mask
        load(fullfile('data','raw',filenameInputCustomMask),'mask','mask_lat','mask_lon')

        % Custom gap-filling method
        nppGapFilled = fillGapsInSurfaceOceanForcing(nppGridOriginal,mask,...
            npp_lat,npp_lon,mask_lat,mask_lon,(1:12)); 
        
        % Process and integrate data for each method
        for iMethod = 1:nGapFillingMethods
            if iMethod == 1
                label = 'plain';
                nppData = nppGridOriginal;
            else
                label = 'gapfilled';
                nppData = nppGapFilled;
            end

            % Replace NaN with 0 for summation purposes
            nppData(isnan(nppData)) = 0; 

            % Compute integrated global NPP stock
            nppStockMonthlyMean = nppData.*cellAreas; % mg C m-2 d-1 --> mg C d-1
            nppStockAnnualMean = mean(nppStockMonthlyMean,3).*(1e-3*1e-15*365); % mg C --> Pg C yr-1
            globalNppStock = sum(nppStockAnnualMean,'all'); % Pg C yr-1

            % Store results in the output string
            globalNppStockSummary{counter} = sprintf('%s %s: %.0f Gt C/yr', ...
                productName, label, globalNppStock);
            counter = counter + 1;

            % Save 3D data arrays in the output structure
            fieldName = [erase(productFileName, '.mat'), '_', label];
            nppModelClimatologyStruct.(fieldName).data = nppData;
            nppModelClimatologyStruct.(fieldName).lat = npp_lat;
            nppModelClimatologyStruct.(fieldName).lon = npp_lon;

        end % iMethod
    end % iModel

    save(fullfile('data','processed',filenameOutputModelledNpp),...
        'globalNppStockSummary','nppModelClimatologyStruct','-v7.3')
    
end % calculateGloballyIntegratedNpp