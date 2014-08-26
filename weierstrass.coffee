a = 0
b = 2*pi
x = linspace a, b, 200 #;
f = (k) -> 1/2.pow(k)*sin(2.pow(k)*x)
w = x*0 #;
w +=  f(k) for k in [0..20] #;

plot x, w,
    xlabel: "x"
    ylabel: "w(x)"
    height: 160
    series: 
        shadowSize: 0
        color: "black"
        lines: lineWidth: 1
