clear all
close all
clc
warning off
path='peltierSLDO';
files=dir(fullfile(path,'*.mat'));

%Digital Twin parameters initial conditions
alpha=75e-3;
R=3.3;
K=0.35;
C=15;

for i=1:length(files)
    tic
    %load input output data
    load(strcat(path,'\',files(i).name))
    controlRef=[simout(:,3),simout(:,1)];
    refSetPoint=[simout(:,3),simout(:,4)+273.5];
    tempRef=[simout(:,3),simout(:,2)];
    tsim=length(simout(:,3))-1;
    %run SLDO optimization
    [pOpt, Info] = parameterEstimationOfflineDTOptim();
    paramHist{i}=pOpt;
    infoHist{i}=Info;
    %parameter extraction
    par1(i)=paramHist{i}(1).Value;
    par2(i)=paramHist{i}(2).Value;
    par3(i)=paramHist{i}(3).Value;
    par4(i)=paramHist{i}(4).Value;
    timeHist(i)=toc
end

figure()
subplot(2,2,1)
hist(par1,20)
subplot(2,2,2)
hist(par2,20)
subplot(2,2,3)
hist(par3,20)
subplot(2,2,4)
hist(par4,20)





