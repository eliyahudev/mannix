%dta = fopen("/u/e2017/lalazan/Desktop/Final_project/files2run/data.txt",'r');
%res =  fopen("/u/e2017/lalazan/Desktop/Final_project/results.txt",'w');

data = randi([0 255],128,128); % create dammy picture (matrix) 

%data = fscanf(dta,'%d',[128 128]);

data = transpose(data);

% ----- data,bias,res write --------
% 
% for i = 1:128*128
%     fprintf(dta , '%5d\n', data(i));
% end 

result = zeros(121*121,1); % vector
tmpData = zeros(8,8); % box to max

a=0; %Jump col
b=0; %Jump row
% ------ Claculate --------
for k=1:121*121 % values of result
            tmpData = data(a+1:a+8 , b+1:b+8); % to sample for debug
            result(k) = max(data(a+1:a+8 , b+1:b+8),[],'all');
   if(mod(k,121)==0)
        a=a+1;
        b=0;
    else
        b=b+1;
    end
    
end
% 
% for i = 1:size(result)
%     fprintf(res , '%5d\n', result(i));
% end
%   
% fclose(dta);
% fclose(res);
