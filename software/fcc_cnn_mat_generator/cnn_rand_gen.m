function [data,weights] = cnn_rand_gen()
dta = fopen ("data_cnn.txt",'w');
wgt =  fopen ("weights_cnn.txt",'w');

data = randi([-127 127],128,128);
weights  = randi([-127 127],4,4);

% ----- wgt write --------
for i = 1:4*4
    fprintf(wgt , '%5d\n', weights(i));
end
% ----- data,bias,res write --------

for i = 1:128*128
    fprintf(dta , '%5d\n', data(i));
end 

fclose(dta);
fclose(wgt);


end