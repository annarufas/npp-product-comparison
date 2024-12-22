function plotBarChartInsituVsModelled(combinedModelAndObsNpp,labelModels,labelLocations)

    nNppModels = length(labelModels);
    nLocs = length(labelLocations);

    myColorScheme = [brewermap(nNppModels,'*YlGn'); zeros(1,3)]; % add a row of black for 14C 
    legendLabels = [labelModels, {'^{14}C observations'}];

    yMax = [800, 800, 1600, 800]; % by location, mg C m-2 d-1

    figure()
    set(gcf,'Units','Normalized','Position',[0.01 0.05 0.45 0.50],'Color','w')
    haxis = zeros(nLocs,1);

    for iLoc = 1:nLocs

        haxis(iLoc) = subaxis(2,2,iLoc,'Spacing',0.02,'Padding',0.04,'Margin',0.07);
        ax(iLoc).pos = get(haxis(iLoc),'Position');
        if (iLoc == 1 || iLoc == 3)
            ax(iLoc).pos(1) = ax(iLoc).pos(1) - 0.04;
        elseif (iLoc == 2 || iLoc == 4)
            ax(iLoc).pos(1) = ax(iLoc).pos(1) - 0.07;
        end
        set(haxis(iLoc), 'Position', ax(iLoc).pos)

        myData = combinedModelAndObsNpp(:,:,iLoc); % 12 months x 6 (models+obs)

        h = bar(myData);
        ylim([0 yMax(iLoc)]);
        hold on

        % Set colors for each bar group
        for k = 1:length(h)
            h(k).FaceColor = myColorScheme(k, :); % assign custom color to each group
        end

        box on
        set(gca,'XTickLabel',{'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'});

        % Add labels and title
        ylabel('NPP (mg C m^{-2} d^{-1})');
        title(labelLocations(iLoc));

        % Add legend for models
        if (iLoc == 2)
            lg = legend(legendLabels,'NumColumns', 1,'Location','northeastoutside');
            lg.Position(1) = 0.825; lg.Position(2) = 0.72;
            lg.ItemTokenSize = [11,5];
            lg.FontSize = 11;
            set(lg,'Box','off');
        end

        grid on

    end

    saveFigure('npp_c14_vs_models')

end % plotBarChartInsituVsModelled