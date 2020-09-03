B = fir1(39,0.1);
BB = reshape(B,4,10);
a = randn(100,1);

y1 = filter(B,1,a);
y2 = conv(a,B(end:-1:1));

a1 = reshape(a,4,25);
a2 = reshape([0;a(1:end-1)],4,25);
a3 = reshape([0;0;a(1:end-2)],4,25);
a4 = reshape([0;0;0;a(1:end-3)],4,25);

for i=1:4
    r1(i,:) = conv(BB(i,end:-1:1),a1(i,:));
    r2(i,:) = conv(BB(i,end:-1:1),a2(i,:));
    r3(i,:) = conv(BB(i,end:-1:1),a3(i,:));
    r4(i,:) = conv(BB(i,end:-1:1),a4(i,:));
end
r(1,:) = sum(r1);
r(2,:) = sum(r2);
r(3,:) = sum(r3);
r(4,:) = sum(r4);
