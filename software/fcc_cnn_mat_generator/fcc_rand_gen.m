function [data,weights,bias,result] = fcc_rand_gen()
dta = fopen ("data.txt",'w');
wgt = fopen ("weights.txt",'w');
b   = fopen ("bias.txt",'w');
res_act = fopen ("result.txt",'w');
res = fopen ("result_pre.txt",'w');
data = randi([0 255],1,128);
weights  = randi([-127 127],128,128);
bias = randi([-127*127 127*127],1,128);

result = weights * data' + bias' ;
res_pre = result;
%-------Activation------------------------------------------------
WB_LOG2_SCALE = 7;  
UINT_DATA_WIDTH=8;
LOG2_RELU_FACTOR=1;
LOG2_SCALE = WB_LOG2_SCALE + LOG2_RELU_FACTOR;
MAX_SCALED_OUTPUT_DATA_RANGE = (2.^(UINT_DATA_WIDTH + LOG2_SCALE)) - 1;
for i = 1:size(result)
if (result(i)<0)
    result(i) = 0;
end
if (result(i) > MAX_SCALED_OUTPUT_DATA_RANGE) 
   result(i) = MAX_SCALED_OUTPUT_DATA_RANGE ;
end
 result(i) =floor(result(i)/(2^LOG2_SCALE));
end
% ----- wgt write --------
for j=1:128
    for i = 1:128
        fprintf(wgt , '%5d\n', weights(j,i))
    end
end
%----- data,bias,res write --------
for j=1:128
    for i = 1:128
     fprintf(dta , '%5d\n', data(i))
    end 
end

for i = 1:128
    fprintf(b , '%5d\n', bias(i))
    fprintf(res_act , '%5d\n', result(i))
    fprintf(res , '%5d\n', res_pre(i))
end
fclose(dta)
fclose(wgt)
fclose(b)
fclose(res_act)
fclose(res)

end