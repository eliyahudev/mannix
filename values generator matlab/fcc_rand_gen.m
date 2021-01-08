function [weights,data,bias,result] = fcc_rand_gen()
wgt = fopen('weights.txt','w');
dta = fopen('data.txt','w');
b = fopen('bias.txt','w');
res = fopen('result.txt','w');

weights = randi([-127 127],128,128);
data = randi([-127 127],128,1);
bias = randi([-127*127 127*127],128,1);

result= weights * data + bias;

for i = 1:128*128
    fprintf(wgt , '%5d\n' , weights(i));
end
for i = 1:128
    fprintf(dta , '%5d\n' , data(i));
    fprintf(res , '%5d\n' , result(i));
    fprintf(b , '%5d\n' , bias(i));
end
fclose(wgt);
fclose(dta);
fclose(b);
fclose(res);
end