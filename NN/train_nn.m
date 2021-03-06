function model = train_nn(conf,Ws,bs,trn_dat,trn_lab,vld_dat,vld_lab)
% Son Tran 2015
[visNum,SZ] = size(trn_dat);
depth = length(conf.hidNum)+1;
fprintf('Training a NN with %d layer \n',depth);
labNum = size(unique(trn_lab),1);

if isempty(Ws)
 % Initialize Ws
    mm = max(visNum,conf.hidNum(1));
    model.Ws{1} = (1/mm)*(2*rand(visNum,conf.hidNum(1))-1);
    DW{1} = zeros(size(model.Ws{1}));
    for i=2:depth-1
        mm = max(conf.hidNum(i-1),conf.hidNum(i));
        model.Ws{i} = (1/mm)*(2*rand(conf.hidNum(i-1),conf.hidNum(i))-1);
        DW{i} = zeros(size(model.Ws{i}));
    end
    model.Ws{depth} = (1/conf.hidNum(depth-1))*(2*rand(conf.hidNum(depth-1),labNum)-1);
    DW{depth} = zeros(size(model.Ws{depth}));
else
    model.Ws = Ws;
    for i=1:depth, DW{i} = zeros(size(model.Ws{i})); size(model.Ws{i}); end
    clear Ws
end

if isempty(bs)
 % Initialize bs
    for i=1:depth-1
        model.bs{i} = zeros(conf.hidNum(i),1);
        DB{i} = model.bs{i};
    end
    model.bs{depth} = zeros(labNum,1);
    DB{depth} = model.bs{depth};
else 
    model.bs  = bs;
end
if conf.sNum == 0, conf.sNum = SZ; end
bNum = conf.bNum;
if conf.bNum == 0, bNum   = round(SZ/conf.sNum); end

plot_trn_acc = [];
plot_vld_acc = [];
plot_mse = [];

vld_best = 0;
es_count = 0;
acc_drop_count = 0;
vld_acc  = 0;
tst_acc  = 0;
e = 0;
running =1;

lr = conf.params(1);
while running
    MSE = 0;
    e = e+1;
   for b=1:bNum
       inx = (b-1)*conf.sNum+1:min(b*conf.sNum,SZ);
       batch_x = trn_dat(:,inx);
       batch_y = trn_lab(inx)'+1;
       sNum = size(batch_x,2);
       % Forward mesage to get output
       input{1} = bsxfun(@plus,model.Ws{1}'*batch_x,model.bs{1});
       actFunc=  str2func(conf.activationFnc{1});
       output{1} = actFunc(input{1});       
       for i=2:depth
           input{i} = bsxfun(@plus,model.Ws{i}'*output{i-1},model.bs{i});
           actFunc=  str2func(conf.activationFnc{i});
           output{i} = actFunc(input{i});
       end  
       %output{depth} = output{depth}
       % Back-prop update        
       y = discrete2softmax(batch_y,labNum);
       %disp([y output{depth}]);       
       
       err{depth} = (y-output{depth}).*deriv(conf.activationFnc{depth},input{depth});
       %err
       [~,cout] = max(output{depth},[],1);
       %sum(sum(batch_y+1==cout))
       MSE = MSE + mean(sqrt(mean((output{depth}-y).^2)));
       for i=depth:-1:2
           diff = output{i-1}*err{i}'/sNum;
           DW{i} = lr*(diff - conf.params(4)*model.Ws{i}) + conf.params(3)*DW{i};
           model.Ws{i} = model.Ws{i} + DW{i};
       
           DB{i} = lr*mean(err{i},2) + conf.params(3)*DB{i};
           model.bs{i} = model.bs{i} + DB{i};
           err{i-1} = (model.Ws{i}*err{i}).*deriv(conf.activationFnc{i},input{i-1});
       end
       diff = batch_x*err{1}'/sNum;        
       DW{1} = lr*(diff - conf.params(4)*model.Ws{1}) + conf.params(3)*DW{1};
       model.Ws{1} = model.Ws{1} + DW{1};       
       
       DB{1} = lr*mean(err{1},2) + conf.params(3)*DB{1};
       model.bs{1} = model.bs{1} + DB{1};       
   end
   
   % Get training classification error
   %trn_dat
   %model.Ws{1} = 0*model.Ws{1};
   %model.Ws{2} = 0*model.Ws{2};
   %pause
   
   cout = run_nn(conf.activationFnc,model,trn_dat); 
   %cout
   trn_acc = sum((cout'-1)==trn_lab)/size(trn_lab,1);
   cout = run_nn(conf.activationFnc,model,vld_dat);
   vld_acc = sum((cout'-1)==vld_lab)/size(vld_lab,1);
   fprintf('[Eppoch %4d] MSE = %.5f| Train acc = %.5f|Validation = %.5f\n',e,MSE,trn_acc,vld_acc);
   % Collect data for plot
   
   plot_trn_acc = [plot_trn_acc trn_acc];
   plot_vld_acc = [plot_vld_acc vld_acc];
   plot_mse     = [plot_mse MSE];
   %pause;
   
   %% EARLY STOPPING
   % PARAM DECAY
    early_stop;

    % Check stop
    if e>=conf.eNum, running=0; end
    
end
    fig1 = figure(1);
    set(fig1,'Position',[10,20,300,200]);
    plot(1:size(plot_trn_acc,2),plot_trn_acc,'r');
    hold on;
    plot(1:size(plot_vld_acc,2),plot_vld_acc);    
    legend('Training','Validation');
    xlabel('Epochs');ylabel('Accuracy');
    
    fig2 = figure(2);
    set(fig2,'Position',[10,20,300,200]);
    plot(1:size(plot_mse,2),plot_mse);    
    xlabel('Epochs');ylabel('MSE');
end
