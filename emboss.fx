/*******
bla
*******/

uniform int bParallaxDoDepthCheck <
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = "Depth Check";
	ui_tooltip = "EXPERIMENTAL! If enabled, shader compares parallax samples depth to avoid artifacts at object borders.";
> = 0;
uniform float fParallaxDepthCutoff <
	ui_type = "slider";
	ui_min = 0.000; ui_max = 0.0050;
	ui_label = "Depth Cutoff";
	ui_tooltip = "Preserves object edges from getting artifacts. If pixel depth difference of parallax samples is higher than that, pixel gets skipped.";
> = 0.0001;
uniform float fParallaxPower <
	ui_type = "slider";
	ui_min = 0.005; ui_max = 2.000;
	ui_label = "Power";
	ui_tooltip = "Amount of parallax.";
> = 0.666;
uniform float fParallaxOffset <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 2.000;
	ui_label = "Offset";
	ui_tooltip = "Pixel offset for parallax.";
> = 2.0;
uniform float iParallaxAngle <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 360.000;
	ui_label = "Offset Angle";
	ui_tooltip = "Pixel offset angle for parallax.";
> = 90.0;
uniform float fParallaxFade <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.000;
	ui_label = "Fadeout Distance";
> = 0.4;

#include "ReShade.fxh"

float4 PS_Parallax(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
        float2 offset;
	sincos(radians( iParallaxAngle), offset.y, offset.x);
	offset *= ReShade::PixelSize*fParallaxOffset;
	
	float centerdepth = ReShade::GetLinearizedDepth(texcoord);
	float3 centercolor = tex2D(ReShade::BackBuffer, texcoord).rgb;

	offset /= centerdepth + 1;

	float2 uv[2] = {texcoord - offset, texcoord + offset};

	float3 colorA = tex2D(ReShade::BackBuffer, uv[0]).rgb;	
	float3 colorB = tex2D(ReShade::BackBuffer, uv[1]).rgb;
	float depthA = ReShade::GetLinearizedDepth(uv[0]);	
	float depthB = ReShade::GetLinearizedDepth(uv[1]);

	float colDot = max(0, dot(centercolor * 2 - colorA - colorB, fParallaxPower));
	float luminance = dot(centercolor, float3(0.8,0.2,0.2));

	colDot *= saturate(1 - luminance*luminance);
	colDot *= saturate(1.00001-centerdepth/fParallaxFade);
	colDot = (max(abs(depthA-centerdepth),abs(depthB-centerdepth)) > fParallaxDepthCutoff && bParallaxDoDepthCheck) ? 0 : colDot;


	float4 res;
	res.rgb = centercolor - colDot;
	res.w = 1.0;
	return res;
}

technique Parallax_Tech
{
	pass Parallax
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Parallax;
	}
}