function [W visB hidB] = training_dbm_first_l(conf,trn_dat)
%% initialization
visNum  = size(trn_dat,2);
hidNum  = conf.hidNum;
sNum  = conf.sNum;
lr    = conf.params(1);
N     = conf.N;                                                                     % Number of epoch training with lr_1                     

W     = 0.1*randn(visNum,hidNum);
DW    = zeros(size(W));
visB  = zeros(1,visNum);
DVB   = zeros(1,visNum);
hidB  = zeros(1,hidNum);
DHB   = zeros(1,hidNum);


%% Reconstruction error & evaluation error & early stopping
mse    = 0;
omse   = 0;
inc_count = 0;
MAX_INC = conf.MAX_INC;                                                                % If the error increase MAX_INC times continuously, then stop training
%% Average best settings
n_best  = 1;
aW  = size(W);
aVB = size(visB);
aHB = size(hidB);
%% Plotting
if conf.plot_, h = plot(nan); end
%% ==================== Start training =========================== %%
for e=1:conf.eNum
    if e== N+1
        lr = conf.params(2);
    end
    omse = mse;
    mse = 0;
    for j=1:conf.bNum
       visP = trn_dat((j-1)*conf.sNum+1:j*conf.sNum,:);
       %up
       hidP = logistic(2*visP*W + repmat(hidB,sNum,1));
       hidPs =  1*(hidP >rand(sNum,hidNum));
       hidNs = hidPs;
       for k=1:conf.gNum
           % down
           visN  = logistic(hidNs*W' + repmat(visB,sNum,1));
           visNs = 1*(visN>rand(sNum,visNum));
           % up
           hidN  = logistic(2*visNs*W + repmat(hidB,sNum,1));
           hidNs = 1*(hidN>rand(sNum,hidNum));
       end
       % Compute MSE for reconstruction
       rdiff = (visP - visN);
       mse = mse + sum(sum(rdiff.*rdiff))/(sNum*visNum);
       % Update W,visB,hidB
       diff = 2*(visP'*hidP - visNs'*hidN)/sNum;
       DW  = lr*(diff - conf.params(4)*W) +  conf.params(3)*DW;
       W   = W + DW;
       DVB  = lr*sum(2*visP - 2*visN,1)/sNum + conf.params(3)*DVB;
       visB = visB + DVB;
       DHB  = lr*sum(hidP - hidN,1)/sNum + conf.params(3)*DHB;
       hidB = hidB + DHB;
    end
    % Visualization
    if ~isempty(conf.vis_dir)        
        save_images(visN,strcat(conf.vis_dir,'1layer_rec_'),sNum,e,conf.row,conf.col);
    end
    % Plotting
    if conf.plot_
        mse_plot(e) = mse;
        axis([0 (conf.eNum+1) 0 5]);
        set(h,'YData',mse_plot);
        drawnow;
    end
    
    if mse > omse
        inc_count = inc_count + 1
    else
        inc_count = 0;
    end
    if inc_count> MAX_INC, break; end;
    fprintf('Epoch %d  : MSE = %f\n',e,mse);
end
end