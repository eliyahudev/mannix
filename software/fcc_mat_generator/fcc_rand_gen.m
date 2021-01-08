function [data,weights,bias,result] = fcc_rand_gen()
dta = fopen ("data.txt",'w');
wgt =  fopen ("weights.txt",'w');
b   = fopen ("bias.txt",'w');
res = fopen ("result.txt",'w');

data = randi([-127 127],128,1);
weights  = randi([-127 127],128,128);
bias = randi([-127*127 127*127],1,128);

result = weights * data + bias ; 
for i = 1:size(result)
    if(result(i)<0)
        result(i) = 0;
    end
end
% ----- wgt write --------
for i = 1:128*128
    fprintf(wgt , '%5d\n', weights(i))
end
% ----- data,bias,res write --------
for i = 1:128
    fprintf(dta , '%5d\n', data(i))
    fprintf(b , '%5d\n', bias(i))
    fprintf(res , '%5d\n', result(i))
end 
fclose(dta)
fclose(wgt)
fclose(b)
fclose(res)

end