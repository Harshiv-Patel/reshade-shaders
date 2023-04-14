
#include "ReShade.fxh"

//tweakable variables
#define bEmbossDoDepthCheck	1	//[0 or 1] EXPERIMENTAL! If enabled, shader compares emboss samples depth to avoid artifacts at object borders.
#define fEmbossDepthCutoff 	0.008	//[0.0001 to 0.005] Preserves object edges from getting artifacts. If pixel depth difference of emboss samples is higher than that, pixel gets skipped. 
//#define fEmbossPower		0.666	//[0.1 to 2.0] Amount of embossing.	
//#define fEmbossOffset		2.0	//[0.5 to 5.0] Pixel offset for embossing.

uniform float fEmbossPower <
	ui_type = "slider";
	ui_min = 0.010; ui_max = 2.000;
	ui_label = "Power";
	ui_tooltip = "Amount of Pixel offset for embossing.";
> = 0.666;

uniform float fEmbossOffset <
	ui_type = "slider";
	ui_min = 1; ui_max = 5.000;
	ui_label = "Offset";
	ui_tooltip = "Amount of Offset.";
> = 2.0;

//end tweakable variables

texture2D texColor : COLOR;
texture2D texDepth : DEPTH;
sampler2D SamplerColor { Texture = texColor; };
sampler2D SamplerDepth
{
	Texture = texDepth;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	MipFilter = LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};


uniform float Timer < source = "timer"; >;
#define ScreenSize 	float4(BUFFER_WIDTH, BUFFER_RCP_WIDTH, float(BUFFER_WIDTH) / float(BUFFER_HEIGHT), float(BUFFER_HEIGHT) / float(BUFFER_WIDTH)) //x=Width, y=1/Width, z=ScreenScaleY, w=1/ScreenScaleY
#define PixelSize  	float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT)

struct VS_OUTPUT_POST
{
	float4 vpos  : POSITION;
	float2 txcoord : TEXCOORD0;
};

VS_OUTPUT_POST VS_PostProcess(in uint id : SV_VertexID)
{
	VS_OUTPUT_POST OUT;
	//OUT.txcoord.x = (id == 2) ? 2.0 : 0.0;
//	OUT.txcoord.y = (id == 1) ? 2.0 : 0.0;
//	OUT.vpos = float4(OUT.txcoord * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);
	return OUT;
}

float GetLinearDepth(float2 coords)
{
	float depth = tex2Dlod(SamplerDepth, float4(coords.xy,0,0)).x;
	depth = 1.f/(1000.f-999.f*depth);
	return depth;
}
	
float4 PS_Emboss(VS_OUTPUT_POST IN) : SV_Target
{
	float4 res = 0;
	float4 origcolor = tex2D(SamplerColor, IN.txcoord.xy);

	float3 col1 = tex2D(SamplerColor, IN.txcoord.xy - PixelSize.xy*fEmbossOffset).rgb;

	float3 col2 = origcolor.rgb;

	float3 col3 = tex2D(SamplerColor, IN.txcoord.xy + PixelSize.xy*fEmbossOffset).rgb;

#if(bEmbossDoDepthCheck != 0)
	//float depth1 = GetLinearDepth(IN.txcoord.xy - PixelSize.xy*fEmbossOffset);
	float depth1 = ReShade::GetLinearizedDepth(IN.txcoord.xy - PixelSize.xy*fEmbossOffset);
	
	//float depth2 = GetLinearDepth(IN.txcoord.xy);
	float depth2 = ReShade::GetLinearizedDepth(IN.txcoord.xy);
	
	//float depth3 = GetLinearDepth(IN.txcoord.xy + PixelSize.xy*fEmbossOffset);
	float depth3 = ReShade::GetLinearizedDepth(IN.txcoord.xy + PixelSize.xy*fEmbossOffset);
	
#endif
	
	float3 colEmboss = col1 * 2.0 - col2 - col3;

	float colDot = max(0,dot(colEmboss, 0.333))*fEmbossPower;

	float3 colFinal = col2 - colDot;

	float luminance = dot( col2, float3( 0.6, 0.2, 0.2 ) );

	res.xyz = lerp( colFinal, col2, luminance * luminance ).xyz;
	
#if(bEmbossDoDepthCheck != 0)
      if(max(abs(depth1-depth2),abs(depth3-depth2)) > fEmbossDepthCutoff) res = origcolor;
#endif
	//if(IN.txcoord.x < 0.5) res = origcolor;

	return res;

}

technique Emboss_2
{
	pass Emboss_2
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_Emboss;
	}
}