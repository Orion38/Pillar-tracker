function tracker(expDir)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
interpolation_factor = 20;  % Interpollation of the edges.
sav=1;                      % If >0, save profile with tracked point every n images
loadBorders=1;              % Try to load the boarders if they already exist.
skip_tracking=0;            % Skip the tracking of the edges and load results from last run.
chk_bord=0;                 % Display the position of each edge used on the profile (to be used in case of automatic edge selection).
saveTable=1;                % Save the results in a xls file of the name of the experiment.
dis=1;                      % Display the evolution of distance between the pillars.
nbImgBefore=3;              % Numbers to use as reference before stimulation. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p=fullfile(expDir,'stacks');
listing=dir(fullfile(p,'*.tiff'));
if isempty(listing)
    listing=dir(fullfile(p,'*.tif'));
end
if isempty(listing)
    error("No TIFF file  found in the folder stack")
end

nbStack=length(listing);
[~,idx]=sort([listing.datenum]);

wellNames=cell(nbStack,1);

for i=1:nbStack
    fname(i)=string(listing(idx(i)).name);
    a=strsplit(listing(idx(i)).name,'.');
    wellNames{i}=a{1};
end
if 7~=exist(fullfile(expDir,'save'),"dir")
    mkdir(fullfile(expDir,'save'))
end

%% border selection
% Load the borders if asked and they exist
if loadBorders
    try
        load(fullfile(expDir,'save','lastBords'),'Peak1','Peak2','R1','R2');
        disp('Borders Loaded.')
    
    catch
        disp('Could not load the borders.')
        for i=1:nbStack
            disp(i)
            I=double(imread(fullfile(p,fname(i)), 1))/256;
            for j=2:nbImgBefore
                I=I+double(imread(fullfile(p,fname(i)), j))/256;
            end
            I=I/nbImgBefore;
            [profile,~]=profiler(I, interpolation_factor);
            [~,R1(:,i),Peak1(i),~,R2(:,i),Peak2(i)]=select_bord(I,...
                profile,interpolation_factor,chk_bord);
        end
        save(fullfile(expDir,'save','lastBords'),'R1','R2','Peak1','Peak2')
    end
else
    for i=1:nbStack
        I=double(imread(fullfile(p,fname(i)), 1))/256;
        for j=2:nbImgBefore
            I=I+double(imread(fullfile(p,fname(i)), j))/256;
        end
        I=I/nbImgBefore;
        [profile,~]=profiler(I, interpolation_factor);
        [~,R1(:,i),Peak1(i),~,R2(:,i),Peak2(i)]=select_bord(I,profile,...
            interpolation_factor,chk_bord);
    end
    save(fullfile(expDir,'save','lastBords'),'R1','R2','Peak1','Peak2')
end

%%
disp('Tracking starts ')

nFr=zeros(nbStack,1);
for i=1:nbStack
    info = imfinfo(char(fullfile(p,fname(i))));
    nFr(i) = numel(info);
end

nFrame=max(nFr);

if ~skip_tracking
    diff=zeros(nFrame,nbStack);
    bordD=zeros(nFrame,nbStack);
    bordG=zeros(nFrame,nbStack);

    for i=1:nbStack
        tic
        display(cat(2,num2str(i)))
        [diff(1:nFr(i),i),gap(i),bordG(1:nFr(i),i),bordD(1:nFr(i),i)]=...
            suivi(fname(i),p,nFr(i),interpolation_factor,sav,R1(:,i),...
            Peak1(i),R2(:,i),Peak2(i));
        toc
    end
    disp('Tracking finished')
    save(fullfile(expDir,'save','lastDiff'),'diff','gap','bordG','bordD')
else
    load(fullfile(expDir,'save','lastDiff'),'diff','gap')
    disp('Tracking skipped!')
end

%%
if saveTable
    T=array2table(cat(1,gap,zeros(1,length(gap)),diff),'VariableNames',wellNames);
    writetable(T,char(fullfile(expDir,'diff.xls')),'WriteRowNames',true);
    disp(cat(2,'Results save in table as ',cat(2,'.xls')))
end

%%
if dis
    figure
    plot(diff)
    title('Tracking result')
    xlabel('Time step')
    ylabel('Pillar relative position (px)')
    if ~isempty(wellNames)
        try
            legend(wellNames)
        catch
            warning('Cannot use wellNames ');
        end
    end
    if 7~=exist(fullfile(expDir,'figures'),"dir")
        mkdir(fullfile(expDir,'figures'))
    end
    savefig(fullfile(expDir,'figures','diff'))

end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function used

function [XR1,R1,Peak1,XR2,R2,Peak2]=select_bord(I,profile,interpolation_factor,chk_bord)
    
    [~,n]=size(I);
    X=1:1/interpolation_factor:n;
    
    % Show image
    figure('units','normalized','outerposition',[0 0 1 1]), 
    subplot(1,2,[1 2])
    imshow(I)
    axis on;
    hold on
    
    % Input both edges of the pillars
    xy=ginput(2);
    
    % Create profiles of the images to be identified
    Peak1=round((xy(1)-1)*interpolation_factor);
    XR1=Peak1-75*interpolation_factor:Peak1+75*interpolation_factor;
    R1=profile(XR1);
    
    Peak2=round((xy(2)-1)*interpolation_factor);
    XR2=Peak2-75*interpolation_factor:Peak2+75*interpolation_factor;
    R2=profile(XR2);
    
    close;
        
    if chk_bord
        figure, subplot(2,1,1), plot(X(XR1),R1)
        hold on
        plot(X(Peak1),profile(Peak1),'r+')
        subplot(2,1,2), plot(X(XR2),R2)
        hold on
        plot(X(Peak2),profile(Peak2),'r+')
    end
end

function [profile,X]=profiler(I, interpolation_factor)
    [m,n]=size(I);
    
%     I=reshape(I,[m n]);
    
    X=1/interpolation_factor:1/interpolation_factor:n;
    profile=sum(I(round(m/4):round(3*m/4),:));
    profile=interp1(1:n,profile,X);
end

function [diff,spacePillars,bordG, bordD]=suivi(fname,path,nFrame,interpF,save,R1,Peak1,R2,Peak2)
    interpolation_factor = interpF;
    
    temp=double(imread(fullfile(path,fname), 1))/256;
    imsize=size(temp);
    clear temp
    
    I=zeros(imsize(1),imsize(2),nFrame);
    Profile=zeros(imsize(2)*interpF,nFrame);
    
    for i=1:nFrame
        I(:,:,i)=double(imread(fullfile(path,fname), i))/256;
        Profile(:,i)=profiler(I(:,:,i), interpolation_factor);
    end
    
    bordG=zeros(nFrame,1);
    bordD=zeros(nFrame,1);
    
    [bordG(1),L]=err_minimizer(Profile(:,1),Peak1,R1,50,interpolation_factor);
    [bordD(1),R]=err_minimizer(Profile(:,1),Peak2,R2,50,interpolation_factor);
    
    R1=R1(round((length(R1)-1)/4):round((length(R1)-1)*3/4));
    R2=R2(round((length(R2)-1)/4):round((length(R2)-1)*3/4));
    
    for i=2:nFrame
        [bordG(i),L]=err_minimizer(Profile(:,i),bordG(i-1),R1,10,interpolation_factor);
        [bordD(i),R]=err_minimizer(Profile(:,i),bordD(i-1),R2,10,interpolation_factor);
    end
    spacePillars=mean(bordD(1:3)-bordG(1:3));
    diff=bordD-bordG-spacePillars;
    if save>0
        if 7~=exist(fullfile(path,'check'),"dir")
            mkdir(fullfile(path,'check'))
        end
    
           A=zeros(imsize(1),imsize(2),3);
           A(:,:,1)=reshape(I(:,:,1),[imsize(1) imsize(2)]);
           A(:,:,2)=reshape(I(:,:,1),[imsize(1) imsize(2)]);
           A(:,:,3)=reshape(I(:,:,1),[imsize(1) imsize(2)]);
           A(:,round(bordG(1)/interpolation_factor),1)=ones(imsize(1),1);
           A(:,round(bordG(1)/interpolation_factor),2)=zeros(imsize(1),1);
           A(:,round(bordG(1)/interpolation_factor),3)=zeros(imsize(1),1);
           A(:,round(bordD(1)/interpolation_factor),1)=zeros(imsize(1),1);
           A(:,round(bordD(1)/interpolation_factor),2)=ones(imsize(1),1);
           A(:,round(bordD(1)/interpolation_factor),3)=zeros(imsize(1),1);
           imwrite(A,char(fullfile(path,'check',fname)),'tiff');
       for i=save+1:save:nFrame
           A=zeros(imsize(1),imsize(2),3);
           A(:,:,1)=reshape(I(:,:,i),[imsize(1) imsize(2)]);
           A(:,:,2)=reshape(I(:,:,i),[imsize(1) imsize(2)]);
           A(:,:,3)=reshape(I(:,:,i),[imsize(1) imsize(2)]);
           A(:,round(bordG(i)/interpolation_factor),1)=ones(imsize(1),1);
           A(:,round(bordG(i)/interpolation_factor),2)=zeros(imsize(1),1);
           A(:,round(bordG(i)/interpolation_factor),3)=zeros(imsize(1),1);
           A(:,round(bordD(i)/interpolation_factor),1)=zeros(imsize(1),1);
           A(:,round(bordD(i)/interpolation_factor),2)=ones(imsize(1),1);
           A(:,round(bordD(i)/interpolation_factor),3)=zeros(imsize(1),1);
           imwrite(A,char(fullfile(path,'check',fname)),'tiff','WriteMode','append');
       end
    end
    diff=-diff/interpolation_factor;
    spacePillars=spacePillars/interpolation_factor;
end

function [I,err]=err_minimizer(profile,Peak,R,a,interpolation_factor)

    X=Peak-(a*interpolation_factor+(length(R)-1)/2):Peak+(a*interpolation_factor+(length(R)-1)/2);
    
    for i=1:length(X)-length(R)
        e=R-profile(X(i:length(R)+i-1));
        err(i)=var(e);
    end
    
    [~,I]=min(err);
    I=I+Peak-(a*interpolation_factor)-1;
end