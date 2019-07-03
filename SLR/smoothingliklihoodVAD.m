clc;
clear all;

[s,fs] = audioread('D:\学习\资料\mine\测试\combine1.wav');
% plot(s,'k');
% x = s;
% noisename = 'whitenoise.wav'; 
noisename = 'factoryfloor1.wav'; 
[x,noise] = add_noisefile(s,noisename,5,fs);%信噪比
% figure;
% plot(x,'k');
alpha = 0.98;
beta = 0.9;%平滑似然比平滑常数
theta = 0.52;
wlen = 320;
inc = 160;
NFFT = 2*2^nextpow2(wlen);
win = hamming(NFFT);
X = fft(enframe(x,win,inc)',NFFT);%分帧加窗FFT
X = X(1:1+wlen/2,:);%傅里叶变换对称性

[bin,frame] = size(X);%频点和帧数

ksi_min = 10^(-35/10);
aa = 0.98;
mu = 0.98;
eta = 0.8;
j =1;%hangover scheme index
D = 30;
Nmean = zeros(bin,1);
% liklyhood = zeros(1,frame);
loglikly = zeros(1,frame);
vadflag = zeros(1,frame);
%假设声音信号开始部分为噪声，combine.wav开始部分为语音
for n = 1:1:6
    Nori = X(:,n);
    Nmean = Nmean + abs(Nori);
end
Noimean = Nmean/6;
Noimean2 = Noimean.^2;
for i = 1:1:frame
    Xf = X(:,i);
    Xfa2 = (abs(Xf)).^2;
%     gammak = Xfa2./Noimean2;

    gammak = min(Xfa2./Noimean2,40);  % limit post SNR to avoid overflows
   
    if i==1
        ksi=aa+(1-aa)*max(gammak-1,0);
        
    else
        ksi=aa*Xk_prev./Noimean2 + (1-aa)*max(gammak-1,0);     % a priori SNR
        ksi=max(ksi_min,ksi);  % limit ksi to -25 dB
    end
    Xk_prev = Xfa2;
    
    liklyhood = (1./(1+ksi)).*exp((ksi.*gammak)./(1+ksi));
%     loglikly(:,i) = sum(log(liklyhood))/bin;
%% smoothing 
    if i == 1
        loglikly(:,i) = sum(log(liklyhood))/bin;
    else
        loglikly(:,i) = sum(log(liklyhood))/bin;
        loglikly(:,i) = beta * loglikly(:,i-1) + (1-beta)*loglikly(:,i);
    end
%% vad decision
    if (loglikly(:,i) > theta)
        vadflag(:,i) = 1;
        
    else
        vadflag(:,i) = 0;
%         Noimean2 = alpha .* Noimean2 + (1-alpha).*Xfa2;
    end
%     if loglikly
%     end
%% hangover scheme 
    hangover(j) = vadflag(:,i);
    if sum(hangover) <= 1
        vadflag(:,i) = 0;
        Noimean2 = alpha .* Noimean2 + (1-alpha).*Xfa2;
    else
        vadflag(:,i) = 1;
    end 
    
    if j <= D - 1
       j = j + 1;
    else
        j = 1;
    end   
end
%% plot
timelikli = repmat(loglikly,160,1);
timelikli = timelikli(:);
timeflag = repmat(vadflag,160,1);
timeflag = timeflag(:);
plot(x,'k');
hold on;
% plot(timelikli,'b');
hold on;
plot(timeflag,'r');




