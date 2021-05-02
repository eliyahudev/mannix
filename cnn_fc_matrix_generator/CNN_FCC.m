function [data,result_cnn,result_pool,resultFC,weights_cnn,weightsFC] = CNN_FCC(isgen)

%--------Explantion of sizes---------------
% 
%   Net of CNN->Pool->FC
%   sizes - data_cnn = 31X31 ->(filter of 5x5) ->
%   result_cnn = 27X27 -> filter_pool 3x3-> result_pool = 25X25 
%   resultFC with weights of 5X625 we get 5X1
%-------------------------------------------
%----matrix generation:------------------
if(isgen)
    data = randi([0 255],31,31);
    dta = fopen("data.txt",'w');
    [c,d]=size(data);
        for i = 1:c*d
           fprintf(dta , '%5d\n', data(i))
        end
        
    %-----------------------------------
    weights_cnn  = randi([-127 127],5,5);
    wgt =  fopen("weights.txt",'w');  
    [a,b]=size(weights_cnn);
        for i = 1:a*b
           fprintf(wgt , '%5d\n', weights_cnn(i))
        end
    %-----------------------------------
    wgt_fc = fopen("weightsFC.txt",'w');
    weightsFC = randi([-127 127],5,625);
    [a,b]=size(weightsFC);
        for i = 1:a*b
           fprintf(wgt_fc , '%5d\n', weightsFC(i))
        end
    %-----------------------------------
    b_fc =  fopen("biasFC.txt",'w');
    biasFC = randi([-127*127 127*127],5,1);
        for i = 1:size(biasFC)
           fprintf(b_fc , '%5d\n', biasFC(i))
        end
    %-----------------------------------
else
    %CNN
    dta = fopen("data.txt",'r');
    wgt =  fopen("weights.txt",'r');
    data = fscanf(dta,'%d',[31 31]);
    weights_cnn = fscanf(wgt,'%d',[5 5]);
    %FC
    wgt_fc = fopen("weightsFC.txt",'r');
    b_fc =  fopen("biasFC.txt",'r');
    weightsFC = fscanf(wgt_fc,'%d',[5 625]);
    biasFC = fscanf(b_fc,'%d',[5 1]);
end
bias_cnn = 1;

res =  fopen("resultsCNN.txt",'w');
res_pool = fopen("resultsPOOL.txt",'w');
res_rl = fopen("results_real_cnn.txt",'w');
res_fc = fopen("resultsFC.txt",'w');
%------------CNN--------------------------------
data_tran=transpose(data);
weights_tran=transpose(weights_cnn);
filter = 5;
result_cnn=zeros(27*27,1);

a=0; %Jump col
b=0; %Jump row
% ------ Calculate --------
for k=1:(size(result_cnn))
    for j=1+a:filter+a
        for i=1+b:filter+b
            tmp_d=data(i,j);
            tmp_w=weights_cnn(i-b,j-a);
            result_cnn(k)=result_cnn(k)+data(i,j)*weights_cnn(i-b,j-a);
        end
    end
   if(mod(k,sqrt(size(result_cnn)))==0)
        a=a+1;
        b=0;
    else
        b=b+1;
    end
    
end
result_cnn = result_cnn+bias_cnn; %bias
res_real=result_cnn ;
 for i = 1:size(res_real)
     fprintf(res_rl , '%5d\n', res_real(i));
 end
%Activation
for i = 1:size(res_real)
in = res_real(i);
WB_LOG2_SCALE = 7;  
UINT_DATA_WIDTH=8;
LOG2_RELU_FACTOR=1;
LOG2_SCALE = WB_LOG2_SCALE + LOG2_RELU_FACTOR;
MAX_SCALED_OUTPUT_DATA_RANGE = (2.^(UINT_DATA_WIDTH + LOG2_SCALE))-1;
if (in<0)
    relu_in = 0;
else
    relu_in = in;
end
 if (relu_in > MAX_SCALED_OUTPUT_DATA_RANGE) 
   relu_in = MAX_SCALED_OUTPUT_DATA_RANGE ;
 end
 result_cnn(i) = floor(relu_in/(2^LOG2_SCALE));  
end

for i = 1:size(result_cnn)
    fprintf(res , '%5d\n', result_cnn(i));
end
%---------------POOL---------------------------------
data = result_cnn;

%---------Explantion---------------------------------
% size of data out is row of data_in - tmpdata row +1
%----------------------------------------------------
data = reshape(data,[27,27]);
data = transpose(data);

result_pool = zeros(25*25,1); % vector
tmpData = zeros(3,3); % box to max
[m,n]=size(tmpData);
a=0; %Jump col
b=0; %Jump row
% ------ Claculate --------
for k=1:size(result_pool) % values of result
            tmpData = data(a+1:a+m , b+1:b+m); % to sample for debug
            result_pool(k) = max(data(a+1:a+m , b+1:b+m),[],'all');
   if(mod(k,sqrt(size(result_pool)))==0)
        a=a+1;
        b=0;
    else
        b=b+1;
    end
    
end

for i = 1:size(result_pool)
    fprintf(res_pool , '%5d\n', result_pool(i));
end
  

  %-------------FC PART-----------------------
 resultFC = zeros(5,1);
 resultFC = weightsFC * result_pool + biasFC; 
  for i = 1:size(resultFC)
  if (resultFC(i)<0)
     resultFC(i) = 0;
  end
  if (resultFC(i) > MAX_SCALED_OUTPUT_DATA_RANGE) 
     resultFC(i) = MAX_SCALED_OUTPUT_DATA_RANGE ;
  end
     resultFC(i) =floor(resultFC(i)/(2^LOG2_SCALE));
  end
  
  for i = 1:size(resultFC)
    fprintf(res_fc , '%5d\n', resultFC(i));
  end
  %-------------------------------------------
if (~isgen)
    fclose(dta);
    fclose(wgt);
end
fclose(res);
fclose(res_rl);
fclose(res_fc);
end