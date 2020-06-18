--[[
    Copyright (C) 2019  Florian Weischer

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
]]

include("/particle_system/initializers")
include("/particle_system/operators")
include("/particle_system/renderers")

-- TODO: These functions are only used by Source Engine particle operators and are merely placeholders until the system is complete.
-- Clean this up!
function RandomVectorInUnitSphere()
	-- Guarantee uniform random distribution within a sphere
	-- Graphics gems III contains this algorithm ("Nonuniform random point sets via warping")
	local u = math.randomf()
	local v = math.randomf()
	local w = math.randomf()

	local flPhi = math.acos( 1 - 2 * u )
	local flTheta = 2 * math.pi * v
	local flRadius = math.pow( w, 1.0 / 3.0 )

	local flSinPhi, flCosPhi;
	local flSinTheta, flCosTheta;
	flSinPhi = math.sin(flPhi)
	flCosPhi = math.cos(flPhi)

	flSinTheta = math.sin(flTheta)
	flCosTheta = math.cos(flTheta)

	local v = Vector()
	v.x = flRadius * flSinPhi * flCosTheta;
	v.y = flRadius * flSinPhi * flSinTheta;
	v.z = flRadius * flCosPhi;
	return v,flRadius;
end

function RandomVector(min,max)
	return Vector(
		math.randomf(min.x,max.x),
		math.randomf(min.y,max.y),
		math.randomf(min.z,max.z)
	)
end

local MAGIC_NUMBER = bit.lshift(1,15) -- gives 8 bits of fraction

local Four_MagicNumbers = MAGIC_NUMBER;


local idx_mask = 0xffff;

local MASK255 = idx_mask

local impulse_xcoords = {
    0.788235,0.541176,0.972549,0.082353,0.352941,0.811765,0.286275,0.752941,
    0.203922,0.705882,0.537255,0.886275,0.580392,0.137255,0.800000,0.533333,
    0.117647,0.447059,0.129412,0.925490,0.086275,0.478431,0.666667,0.568627,
    0.678431,0.313725,0.321569,0.349020,0.988235,0.419608,0.898039,0.219608,
    0.243137,0.623529,0.501961,0.772549,0.952941,0.517647,0.949020,0.701961,
    0.454902,0.505882,0.564706,0.960784,0.207843,0.007843,0.831373,0.184314,
    0.576471,0.462745,0.572549,0.247059,0.262745,0.694118,0.615686,0.121569,
    0.384314,0.749020,0.145098,0.717647,0.415686,0.607843,0.105882,0.101961,
    0.200000,0.807843,0.521569,0.780392,0.466667,0.552941,0.996078,0.627451,
    0.992157,0.529412,0.407843,0.011765,0.709804,0.458824,0.058824,0.819608,
    0.176471,0.317647,0.392157,0.223529,0.156863,0.490196,0.325490,0.074510,
    0.239216,0.164706,0.890196,0.603922,0.921569,0.839216,0.854902,0.098039,
    0.686275,0.843137,0.152941,0.372549,0.062745,0.474510,0.486275,0.227451,
    0.400000,0.298039,0.309804,0.274510,0.054902,0.815686,0.647059,0.635294,
    0.662745,0.976471,0.094118,0.509804,0.650980,0.211765,0.180392,0.003922,
    0.827451,0.278431,0.023529,0.525490,0.450980,0.725490,0.690196,0.941176,
    0.639216,0.560784,0.196078,0.364706,0.043137,0.494118,0.796078,0.113725,
    0.760784,0.729412,0.258824,0.290196,0.584314,0.674510,0.823529,0.905882,
    0.917647,0.070588,0.862745,0.345098,0.913725,0.937255,0.031373,0.215686,
    0.768627,0.333333,0.411765,0.423529,0.945098,0.721569,0.039216,0.792157,
    0.956863,0.266667,0.254902,0.047059,0.294118,0.658824,0.250980,1.000000,
    0.984314,0.756863,0.027451,0.305882,0.835294,0.513725,0.360784,0.776471,
    0.611765,0.192157,0.866667,0.858824,0.592157,0.803922,0.141176,0.435294,
    0.588235,0.619608,0.341176,0.109804,0.356863,0.270588,0.737255,0.847059,
    0.050980,0.764706,0.019608,0.870588,0.933333,0.784314,0.549020,0.337255,
    0.631373,0.929412,0.231373,0.427451,0.078431,0.498039,0.968627,0.654902,
    0.125490,0.698039,0.015686,0.878431,0.713725,0.368627,0.431373,0.874510,
    0.403922,0.556863,0.443137,0.964706,0.909804,0.301961,0.035294,0.850980,
    0.882353,0.741176,0.380392,0.133333,0.470588,0.643137,0.282353,0.396078,
    0.980392,0.168627,0.149020,0.235294,0.670588,0.596078,0.733333,0.160784,
    0.376471,0.682353,0.545098,0.482353,0.745098,0.894118,0.188235,0.329412,
    0.439216,0.901961,0.000000,0.600000,0.388235,0.172549,0.090196,0.066667
};

local perm_a={
    66,147,106,213,89,115,239,25,171,175,9,114,141,226,118,128,41,208,4,56,
   180,248,43,82,246,219,94,245,133,131,222,103,160,130,168,145,238,38,23,6,
   236,67,99,2,70,232,80,209,1,3,68,65,102,210,13,73,55,252,187,170,22,36,
   52,181,117,163,46,79,166,224,148,75,113,95,156,185,220,164,51,142,161,35,
   206,251,45,136,197,190,132,32,218,127,63,27,137,93,242,20,189,108,183,
   122,139,191,249,253,87,98,69,0,144,64,24,214,97,116,158,42,107,15,53,212,
   83,111,152,240,74,237,62,77,205,149,26,151,178,204,91,176,234,49,154,203,
   33,221,125,134,165,124,86,39,37,60,150,157,179,109,110,44,159,153,5,100,
   10,207,40,186,96,215,143,162,230,184,101,54,174,247,76,59,241,223,192,84,
   104,78,169,146,138,30,48,85,233,19,29,92,126,17,199,250,31,81,188,225,28,
   112,88,11,182,173,211,129,194,172,14,120,200,167,135,12,177,227,229,155,
   201,61,105,195,193,244,235,58,8,196,123,254,16,18,50,121,71,243,90,57,
   202,119,255,47,7,198,228,21,217,216,231,140,72,34
};

local perm_b={
    123,108,201,64,40,75,24,221,137,110,191,142,9,69,230,83,7,247,51,54,115,
    133,180,248,109,116,62,99,251,55,89,253,65,106,228,167,131,132,58,143,
    97,102,163,202,149,234,12,117,174,94,121,74,32,113,20,60,159,182,204,29,
    244,118,3,178,255,38,6,114,36,93,30,134,213,90,245,209,88,232,162,125,
    84,166,70,136,208,231,27,71,157,80,76,0,170,225,203,176,33,161,196,128,
    252,236,246,2,138,1,250,197,77,243,218,242,19,164,68,212,14,237,144,63,
    46,103,177,188,85,223,8,160,222,4,216,219,35,15,44,23,126,127,100,226,
    235,37,168,101,49,22,11,73,61,135,111,183,72,96,185,239,82,18,50,155,
    186,153,17,233,146,156,107,5,254,10,192,198,148,207,104,13,124,48,95,
    129,120,206,199,81,249,91,150,210,119,240,122,194,92,34,28,205,175,227,
    179,220,140,152,79,26,195,47,66,173,169,241,53,184,187,145,112,238,214,
    147,98,171,229,200,151,25,67,78,189,217,130,224,57,172,59,41,43,16,105,
    158,165,21,45,56,141,139,215,190,86,42,52,39,87,181,31,154,193,211
};

local perm_c={
    97,65,96,25,122,26,219,85,148,251,102,0,140,130,136,213,138,60,236,52,
    178,131,115,183,144,78,147,168,39,45,169,70,57,146,67,142,252,216,28,54,
    86,222,194,200,48,5,205,125,214,56,181,255,196,155,37,218,153,208,66,
    242,73,248,206,61,62,246,177,2,197,107,162,152,89,41,6,160,94,8,201,38,
    235,228,165,93,111,239,74,231,121,47,166,221,157,64,77,244,29,105,150,
    123,190,191,225,118,133,42,10,84,185,159,124,132,240,180,44,1,9,19,99,
    254,12,207,186,71,234,184,11,20,16,193,139,175,98,59,113,27,170,230,91,
    187,46,156,249,108,195,171,114,14,188,82,192,233,24,32,241,87,164,90,43,
    163,245,92,40,215,55,226,15,3,112,158,250,172,22,227,137,35,128,145,247,
    161,119,80,217,189,81,7,63,202,120,223,83,179,4,106,199,229,95,53,50,33,
    182,72,143,23,243,75,18,173,141,167,198,204,58,174,237,17,129,238,127,
    31,101,176,36,30,110,209,34,203,135,232,68,149,49,134,126,212,79,76,117,
    104,210,211,224,253,100,220,109,116,88,13,151,154,69,21,51,103
};

local function GetLatticePointValue(idx_x,idx_y,idx_z)
	local ret_idx = perm_a[bit.band(idx_x,0xff) +1];
	ret_idx = perm_b[bit.band( idx_y + ret_idx , 0xff) +1];
	ret_idx = perm_c[bit.band( idx_z + ret_idx , 0xff) +1];
	return impulse_xcoords[ret_idx +1];
end
function NoiseV3(x,y,z)
	-- use magic to convert to integer index
	local x_idx = bit.band( MASK255, ( x+ Four_MagicNumbers ) );
	local y_idx = bit.band( MASK255, ( y+ Four_MagicNumbers ) );
	local z_idx = bit.band( MASK255, ( z+ Four_MagicNumbers ) );

	local lattice000 = 0
	local lattice001 = 0
	local lattice010 = 0
	local lattice011 = 0

	local lattice100 = 0
	local lattice101 = 0
	local lattice110 = 0
	local lattice111 = 0;

	-- FIXME: Converting the input vectors to int indices will cause load-hit-stores (48 bytes)
	--        Converting the indexed noise values back to vectors will cause more (128 bytes)
	--        The noise table could store vectors if we chunked it into 2x2x2 blocks.
	local xfrac = 0
	local yfrac = 0
	local zfrac = 0;

	local function do_pass()
    	local xi = ( x_idx );								
		local yi = ( y_idx );								
		local zi = ( z_idx );								
		 xfrac  = bit.band(xi , 0xff)*(1.0/256.0);						
		 yfrac  = bit.band(yi , 0xff)*(1.0/256.0);						
		 zfrac  = bit.band(zi , 0xff)*(1.0/256.0);						
		xi = bit.rshift(xi,8)
		yi = bit.rshift(yi,8)
		zi = bit.rshift(zi,8)
																			
		 lattice000  = GetLatticePointValue( xi,yi,zi );		
		 lattice001  = GetLatticePointValue( xi,yi,zi+1 );		
		 lattice010  = GetLatticePointValue( xi,yi+1,zi );		
		 lattice011  = GetLatticePointValue( xi,yi+1,zi+1 );	
		 lattice100  = GetLatticePointValue( xi+1,yi,zi );		
		 lattice101  = GetLatticePointValue( xi+1,yi,zi+1 );	
		 lattice110  = GetLatticePointValue( xi+1,yi+1,zi );	
		 lattice111  = GetLatticePointValue( xi+1,yi+1,zi+1 );	
	end

	do_pass( 0 );

	-- now, we have 8 lattice values for each of four points as m128s, and interpolant values for
	-- each axis in m128 form in [xyz]frac. Perfom the trilinear interpolation as SIMD ops

	-- first, do x interpolation
	local l2d00 = ( lattice000+ ( xfrac* ( lattice100- lattice000 ) ) );
	local l2d01 = ( lattice001+ ( xfrac* ( lattice101- lattice001 ) ) );
	local l2d10 = ( lattice010+ ( xfrac* ( lattice110- lattice010 ) ) );
	local l2d11 = ( lattice011+ ( xfrac* ( lattice111- lattice011 ) ) );

	-- now, do y interpolation
	local l1d0 = ( l2d00+ ( yfrac* ( l2d10- l2d00 ) ) );
	local l1d1 = ( l2d01+ ( yfrac* ( l2d11- l2d01 ) ) );

	-- final z interpolation
	local rslt = ( l1d0+ ( zfrac* ( l1d1- l1d0 ) ) );

	-- map to 0..1
	return ( 2.0* ( rslt- 0.5 ) );
end

function MatrixBuildRotationAboutAxis(vAxisOfRot,angleDegrees)
	local rad = math.rad(angleDegrees)
	local sin = math.sin(rad)
	local cos = math.cos(rad)

	local axisXSquared = vAxisOfRot.x *vAxisOfRot.x
	local axisYSquared = vAxisOfRot.z *vAxisOfRot.z
	local axisZSquared = vAxisOfRot.y *vAxisOfRot.y

	local mat = math.Mat3x4(
		axisXSquared + (1 - axisXSquared) * cos,
		vAxisOfRot.x * vAxisOfRot.y * (1 - cos) - vAxisOfRot.z * sin,
		vAxisOfRot.z * vAxisOfRot.x * (1 - cos) + vAxisOfRot.y * sin,
		0,

		vAxisOfRot.x * vAxisOfRot.y * (1 - cos) + vAxisOfRot.z * sin,
		axisYSquared + (1 - axisYSquared) * cos,
		vAxisOfRot.y * vAxisOfRot.z * (1 - cos) - vAxisOfRot.x * sin,
		0,

		vAxisOfRot.z * vAxisOfRot.x * (1 - cos) - vAxisOfRot.y * sin,
		vAxisOfRot.y * vAxisOfRot.z * (1 - cos) + vAxisOfRot.x * sin,
		axisZSquared + (1 - axisZSquared) * cos,
		0
	)

	--[[local mat = math.Mat3x4(
		-- Column 0:
		axisXSquared + (1 - axisXSquared) * cos,
		vAxisOfRot.x * vAxisOfRot.y * (1 - cos) + vAxisOfRot.z * sin,
		vAxisOfRot.z * vAxisOfRot.x * (1 - cos) - vAxisOfRot.y * sin,

		-- Column 1:
		vAxisOfRot.x * vAxisOfRot.y * (1 - cos) - vAxisOfRot.z * sin,
		axisYSquared + (1 - axisYSquared) * cos,
		vAxisOfRot.y * vAxisOfRot.z * (1 - cos) + vAxisOfRot.x * sin,

		-- Column 2:
		vAxisOfRot.z * vAxisOfRot.x * (1 - cos) + vAxisOfRot.y * sin,
		vAxisOfRot.y * vAxisOfRot.z * (1 - cos) - vAxisOfRot.x * sin,
		axisZSquared + (1 - axisZSquared) * cos,

		-- Column 3:
		0,
		0,
		0
	)]]
	return mat
end

function GetControlPointTransformAtTime(self,nControlPoint,flTime)
	local pose = self:GetParticleSystem():GetEntity():GetPose()
	-- TODO: Entity pose is confirmed to be required for ExplosionCore_MidAir, but NOT for flamethrower?
	return pose *(self:GetParticleSystem():GetControlPointPose(nControlPoint or 0,flTime) or phys.Transform())
end

function GetControlPointAtTime(self,nControlPoint,flTime)
	return GetControlPointTransformAtTime(self,nControlPoint,flTime):GetOrigin()
end

function GetControlPointPose(self,nControlPoint)
	local pose = self:GetParticleSystem():GetEntity():GetPose()
	--return self:GetParticleSystem():GetEntity():GetPose()
	return pose *(self:GetParticleSystem():GetControlPointPose(nControlPoint or 0) or phys.Transform())
end

function TransformAxis(self,srcAxis,localSpace,nControlPoint)
	if(localSpace == false) then return srcAxis end
	local pose = GetControlPointPose(self,nControlPoint or 0)
	pose:SetOrigin(Vector())

	local rot = pose:GetRotation()
	local right = rot:GetRight()
	local forward = rot:GetForward()
	local up = rot:GetUp()
	return -srcAxis.x *right +srcAxis.z *forward +srcAxis.y *up
end

--[[function ExponentialDecay(halflife,dt)
	-- log(0.5) == -0.69314718055994530941723212145818
	return math.exp( -0.69314718 / halflife * dt);
end]]

-- decayTo is factor the value should decay to in decayTime
function ExponentialDecay( decayTo, decayTime, dt )
	return math.exp( math.log( decayTo ) / decayTime * dt);
end

function SimpleSpline(value)
	local valueSquared = value *value
	-- Nice little ease-in, ease-out spline-like curve
	return (3 * valueSquared - 2 * valueSquared * value);
end

function SimpleSplineRemapValWithDeltasClamped(val,A,BMinusA,OneOverBMinusA,C,DMinusC)
	local cVal = (val -A) *OneOverBMinusA
	cVal = math.min(1.0,math.max(0,cVal))
	return C +(DMinusC *SimpleSpline(cVal))
end

FLT_EPSILON = 0.000001
function ReciprocalSaturate(a)
	return 1.0 /((a == 0.0) and FLT_EPSILON or a)
end

function ReciprocalEst(a)
	if(math.abs(a) < 0.0001) then return 0.0 end
	return 1.0 /a
end

function Reciprocal(a)
	if(math.abs(a) < 0.0001) then return 0.0 end
	return 1.0 /a
end

function PreCalcBiasParameter(biasParam)
	-- convert perlin-style-bias parameter to the value right for the approximation
	return Reciprocal(biasParam) -2.0
end

function Bias(val,precalcParam)
	return val /((precalcParam *(1.0 -val)) +1.0)
end

function GetPtDelta() return 0.04166666790843 end
function GetPrevPtDelta() return GetPtDelta() end

function fsel(c,x,y)
	if(c >= 0) then return x end
	return y
end

function RemapValClamped(val,a,b,c,d)
	if(a == b) then return fsel(val -b,d,c) end
	local cVal = (val -a) /(b -a)
	cVal = math.clamp(cVal,0.0,1.0)
	return c +(d -c) *cVal
end
