function [resultFC,result_cnn,data,weights,weightsFC] = CNN_FCC()

dta = fopen("data.txt",'r');
wgt =  fopen("weights.txt",'r');
data = fscanf(dta,'%d',[128 128]);
weights = fscanf(wgt,'%d',[4 4]);

wgt_fc = fopen("weightsFC.txt",'r');
b_fc =  fopen("biasFC.txt",'r');
weightsFC = fscanf(wgt_fc,'%d',[125 125]);
biasFC = fscanf(b_fc,'%d',[125 1]);

res =  fopen("resultsCNN.txt",'w');
res_rl = fopen("results_real_cnn.txt",'w');
res_fc = fopen("resultsFC.txt",'w');

data_tran=transpose(data);
weights_tran=transpose(weights);

result_cnn=zeros(125*125,1);

a=0; %Jump col
b=0; %Jump row
% ------ Claculate --------
for k=1:125*125
    for j=1+a:4+a
        for i=1+b:4+b
            tmp_d=data(i,j);
            tmp_w=weights(i-b,j-a);
            result_cnn(k)=result_cnn(k)+data(i,j)*weights(i-b,j-a);
        end
    end
   if(mod(k,125)==0)
        a=a+1;
        b=0;
    else
        b=b+1;
    end
    
end
result_cnn = result_cnn+1; %bias
res_real=result_cnn ;

 for i = 1:size(res_real)
     fprintf(res_rl , '%5d\n', res_real(i));
 end

for i = 1:size(result_cnn)
in = result_cnn(i);
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
  %-------------FC PART-----------------------
 %----Reshape-----
 result_cnn = reshape(result_cnn,125,125);
  
  resultFC = weightsFC * result_cnn' + biasFC ; 
  for i = 1:size(resultFC)
  if (resultFC(i)<0)
     resultFC(i) = 0;
  end
  if (resultFC(i) > MAX_SCALED_OUTPUT_DATA_RANGE) 
     resultFC(i) = MAX_SCALED_OUTPUT_DATA_RANGE ;
  end
     resultFC(i) =floor(resultFC(i)/(2^LOG2_SCALE));
  end
  
  for i = 1:125
    fprintf(res_fc , '%5d\n', resultFC(i));
  end
  %-------------------------------------------
fclose(dta);
fclose(wgt);
fclose(res);
fclose(res_rl);
fclose(res_fc);

end