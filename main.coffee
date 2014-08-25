#!vanilla

# Temp fix - to be done in puzlet.js.
Number.prototype.pow = (p) -> Math.pow this, p

# Global stuff

pi = Math.PI
sin = Math.sin
cos = Math.cos
min = Math.min
COS = (u) -> Math.cos(u*pi/180)
SIN = (u) -> Math.sin(u*pi/180)
R2 = Math.sqrt(2)

repRow = (val, m) -> val for [1..m]

{rk, ode} = $blab.ode # Import ODE solver


