/*
MIT License

Copyright (c) 2016 Tizian Zeltner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

vec3 adjust_color(vec3 color,float L,float Ld)
{
	return Ld *color /L;
}
vec3 clamped_value(vec3 color)
{
	return clamp(color,0.0,1.0);
}
float map(float x,float a,float d,float midIn,float midOut,float hdrMax)
{
	float b = (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
		((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
	float c = (pow(hdrMax, a * d) * pow(midIn, a) - pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
		((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
	return pow(x, a) / (pow(x, a * d) * b + c);
}
vec3 ward(vec3 color,float Lwa,float Ldmax,float exposure)
{
	// Source: https://github.com/tizian/tonemapper/blob/master/src/operators/ward.h
	float Lda = Ldmax / 2.0;
	float m = pow((1.219 + pow(Lda, 0.4)) / (1.219 + pow(Lwa * exposure, 0.4)), 2.5);
	float L = calc_luminance(color);
	float Ld = m * L / Ldmax;
	color = adjust_color(color, L, Ld);
	color = clamped_value(color);
	return linear_to_srgb(color);
}
vec3 tumblin_rushmeier(vec3 color,float Lavg,float Ldmax,float Cmax,float exposure)
{
	float log10Lrw = log(exposure * Lavg)/log(10.0);
	float alpha_rw = 0.4 * log10Lrw + 2.92;
	float beta_rw = -0.4 * log10Lrw*log10Lrw - 2.584 * log10Lrw + 2.0208;
	float log10Ld = log(Ldmax / sqrt(Cmax))/log(10.0);
	float alpha_d = 0.4 * log10Ld + 2.92;
	float beta_d = -0.4 * log10Ld*log10Ld - 2.584 * log10Ld + 2.0208;
	float L = calc_luminance(color);
	float Ld = pow(L, alpha_rw/alpha_d) / Ldmax * pow(10.0, (beta_rw - beta_d) / alpha_d) - (1.0 / Cmax);
	color = adjust_color(color, L, Ld);
	color = clamped_value(color);
	return linear_to_srgb(color);
}
vec3 schlick(vec3 color,float p,float Lmax,float exposure)
{
	color = p * color / (p * color - color + exposure * Lmax);
	return clamped_value(color);
}
vec3 amd(vec3 color,float a,float d,float midIn,float midOut,float hdrMax)
{
	color = vec3(map(color.x,a,d,midIn,midOut,hdrMax), map(color.y,a,d,midIn,midOut,hdrMax), map(color.z,a,d,midIn,midOut,hdrMax));
	color = clamped_value(color);
	return linear_to_srgb(color);
}
float gamma_correct_drago(float Ld,float start,float slope) {
	if (Ld <= start) {
		return slope * Ld;
	}
	else {
		return pow(1.099 * Ld, 0.9/GAMMA) - 0.099;
	}
}
vec3 drago(vec3 color,float Lwa,float Lwmax,float Ldmax,float b,float start,float slope,float exposure)
{
	float LwaP = exposure * Lwa / pow(1.0 + b - 0.85, 5);
	float LwmaxP = exposure * Lwmax / LwaP;
	color = color / LwaP;
	float L = calc_luminance(color);
	float exponent = log(b) / log(0.5);
	float c1 = (0.01 * Ldmax) / (log(1 + LwmaxP)/log(10.0));
	float c2 = log(L + 1) / log(2.0 + 8 * (pow(L / LwmaxP, exponent)));
	float Ld = c1 * c2;
	color = adjust_color(color, L, Ld);
	color = clamped_value(color);
	return vec3(gamma_correct_drago(color.r,start,slope), gamma_correct_drago(color.g,start,slope), gamma_correct_drago(color.b,start,slope));
}
vec3 filmic1(vec3 color)
{
	vec3 x = max(vec3(0.0), color - 0.004);
	color = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
	return clamped_value(color);
}
vec3 filmic2(vec3 color,float cutoff)
{
	vec3 x = color + (cutoff * 2.0 - color) * clamp(cutoff * 2.0 - color, 0.0, 1.0) * (0.25 / cutoff) - cutoff;
	color = (x * (6.2 * x + 0.5)) / (x * (6.2 * x + 1.7) + 0.06);
	return clamped_value(color);
}

float tp(float La) {
	float logLa = log(La)/log(10.0);
	float result;
	if (logLa <= -2.6) {
		result = -0.72;
	}
	else if (logLa >= 1.9) {
		result = logLa - 1.255;
	}
	else {
		result = pow(0.249 * logLa + 0.65, 2.7) - 0.72;
	}
	return pow(10.0, result);
}
float ts(float La) {
	float logLa = log(La)/log(10.0);
	float result;
	if (logLa <= -3.94) {
		result = -2.86;
	}
	else if (logLa >= -1.44) {
		result = logLa - 0.395;
	}
	else {
		result = pow(0.405 * logLa + 1.6, 2.18) -2.86;
	}
	return pow(10.0, result);
}
vec3 ferwerda(vec3 color,float Lwa,float Ldmax,float exposure)
{
	float Lda = Ldmax / 2.0;
	float L = calc_luminance(color);
	float mP = tp(Lda) / tp(exposure * Lwa);
	float mS = ts(Lda) / ts(exposure * Lwa);
	float k = (1.0 - (Lwa/2.0 - 0.01)/(10.0-0.01));
	k = clamp(k * k, 0.0, 1.0);
	float Ld = mP * L + k * mS * L;
	color = adjust_color(color, L, Ld);
	color = clamped_value(color);
	return linear_to_srgb(color);
}
float sigma_ia(float Ia, float Iav_a, float L,float c,float a,float f,float m,float Lav,float exposure)
{
	float Ia_local = c * Ia + (1.0 - c) * L;
	float Ia_global = c * Iav_a + (1.0 - c) * exposure * Lav;
	float result = a * Ia_local + (1.0 - a) * Ia_global;
	return pow(f * result, m);
}
vec3 reinhard_devlin(vec3 color,float c,float a,float f,float m,float Lav,vec3 Iav,float exposure)
{
	float L = calc_luminance(color);
	float sigmaIr = sigma_ia(color.r, exposure * Iav.x, L,c,a,f,m,Lav,exposure);
	float sigmaIg = sigma_ia(color.g, exposure * Iav.y, L,c,a,f,m,Lav,exposure);
	float sigmaIb = sigma_ia(color.b, exposure * Iav.z, L,c,a,f,m,Lav,exposure);
	color.r = color.r / (color.r + sigmaIr);
	color.g = color.g / (color.g + sigmaIg);
	color.b = color.b / (color.b + sigmaIb);
	color = clamped_value(color);
	return linear_to_srgb(color);
}
float tonemap(float x, float k,float c,float b,float s,float w,float t)
{
	if (x < c) {
		return k * (1.0-t)*(x-b) / (c - (1.0-t)*b - t*x);
	}
	else {
		return (1.0-k)*(x-c) / (s*x + (1.0-s)*w - c) + k;
	}
}
vec3 insomniac(vec3 color,float Lavg,float c,float b,float s,float w,float t)
{
	color = color / Lavg;
	float k = (1.0-t)*(c-b) / ((1.0-s)*(w-c) + (1.0-t)*(c-b));
	color = vec3(tonemap(color.r, k,c,b,s,w,t), tonemap(color.g, k,c,b,s,w,t), tonemap(color.b, k,c,b,s,w,t));
	color = clamped_value(color);
	return linear_to_srgb(color);
}
