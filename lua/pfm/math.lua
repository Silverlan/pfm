--[[
    Copyright (C) 2021 Silverlan

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

pfm.math = {}
function pfm.math.sqr(v) return v *v end
function pfm.math.sin_deg(v) return math.sin(math.rad(v)) end
function pfm.math.asin_deg(v) return math.deg(math.asin(v)) end
function pfm.math.cos_deg(v) return math.cos(math.rad(v)) end
function pfm.math.acos_deg(v) return math.deg(math.acos(v)) end
function pfm.math.tan_deg(v) return math.tan(math.rad(v)) end
function pfm.math.in_range(x,a,b) return (x >= a and x <= b) and 1 or 0 end
function pfm.math.ramp(value,a,b)
	if(a == b) then return a end
	return math.clamp((value -a) /(b -a),0,1)
end
function pfm.math.lerp(value,a,b) return math.lerp(a,b,value) end
function pfm.math.cramp(value,a,b) return math.clamp(pfm.math.ramp(value,a,b),0,1) end
function pfm.math.clerp(factor,a,b) return math.clamp(pfm.math.lerp(factor,a,b),a,b) end
function pfm.math.elerp(x,a,b) return pfm.math.ramp(3 *x *x -2 *x *x *x,a,b) end
function pfm.math.noise(a,b,c) return math.perlin_noise(Vector(a,b,c)) end
function pfm.math.rescale(X,Xa,Xb,Ya,Yb) return pfm.math.lerp(pfm.math.ramp(X,Xa,Xb),Ya,Yb) end
function pfm.math.crescale(X,Xa,Xb,Ya,Yb) return math.clamp(pfm.math.rescale(X,Xa,Xb,Ya,Yb),Ya,Yb) end
