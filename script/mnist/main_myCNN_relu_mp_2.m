%% ex1 Train a 6c-2s-12c-2s-18c-2s Convolutional neural network 
% [28,28,1]->[24,24,6]->[12,12,6]->[8,8,12]->[4,4,12]->[10]
%         c 5        s 2        c 5 4     s 2        fc
%% data
clear all;
load mnist_uint8;

train_x = double(reshape(train_x',28,28,60000))/255;
test_x = double(reshape(test_x',28,28,10000))/255;
train_y = double(train_y');
test_y = double(test_y');
K = size(train_y,1);

s = RandStream('mt19937ar','Seed',1394);
RandStream.setGlobalStream(s);
%%
% rand('state',0);
% tr_ind = randsample(60000, 10000);
% train_x = train_x(:,:, tr_ind);
% train_y = train_y(:, tr_ind);
% te_ind = randsample(10000, 2000);
% test_x = test_x(:,:, te_ind);
% test_y = test_y(:, te_ind);
%% Image Mean Subtraction
tmp = cat(3, train_x, test_x);
mu = mean(tmp, 3);

train_x = bsxfun(@minus, train_x, mu);
test_x = bsxfun(@minus, test_x, mu);
%% init
h = myCNN();

%%% layers
% convolution, kernel size 5, #output map = 6
h.transArr{end+1} = trans_conv(5, 6); 
h.transArr{end}.hpmker = param_mgr_fmwl();
h.transArr{end}.hpmb = param_mgr_fmwl();

% max pool, scale 2
h.transArr{end+1} = trans_mp(2); 
% activation
h.transArr{end+1} = trans_act_relu(); % trick: after mp, less computations

% convolution, kernel size 5, #output map = 12, #input map subset size = 4
h.transArr{end+1} = trans_conv(5, 12, 6);
h.transArr{end}.hpmker = param_mgr_fmwl();
h.transArr{end}.hpmb = param_mgr_fmwl();

% max pool, scale 2
h.transArr{end+1} = trans_mp(2);
% activation
h.transArr{end+1} = trans_act_relu();

% full connection, #output map = #classes
h.transArr{end+1} = trans_fc(K);
h.transArr{end}.hpmW = param_mgr_fmwl();
h.transArr{end}.hpmb = param_mgr_fmwl();

%%% loss
h.lossType = loss_softmax();

%%% other parameters
h.batchsize = 50;
h.numepochs = 100;
%% train
% rand('state',0);
h = h.train(train_x, train_y);
%% test
pre_y = h.test(test_x);
[~,pre_c] = max(pre_y);
[~,test_c] = max(test_y);
err = mean(pre_c ~= test_c);
fprintf('err = %d\n', err);
%% results
%plot mean squared error
figure; plot(h.rL);

% fprintf('err = %d\n',err);
% assert(err<0.12, 'Too big error');