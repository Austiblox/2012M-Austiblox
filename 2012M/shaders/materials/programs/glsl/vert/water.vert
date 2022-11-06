
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define float4x4 mat4
#define mul(x,y) (x * y)
#define saturate(x) clamp(x,0.0,1.0)

/////////////////////////////////////////////////////
// BEGIN COPY FROM CG SHADER


/************* DATA STRUCTS **************/


struct AppdataTerrain {
    float3 Position;
    float3 Normal;
    float2 UvHigh;
    float2 UvLow;
};

/* data passed from vertex shader to pixel shader */
struct WaterVertexOutput {
    float4 HPosition;
    float2 UvLayer1;
    float2 UvLayer2;
    float2 UvLow;
    float3 LightingColor;
};

/*********** vertex shader ******/

WaterVertexOutput WaterVS(AppdataTerrain IN,
    float4x4 WorldITXf, // our four standard "untweakable" xforms
	float4x4 WorldXf,
	float4x4 ViewIXf,
	float4x4 WvpXf,
	float4x4 WvXf,	
    float3 Lamp0Pos,
    float3 Lamp1Pos,
    float timeframe,
    float sintime,
    float3 ambientLight,
    float3 Lamp0Color,
    float3 Lamp1Color
) {
    WaterVertexOutput OUT;
		
	float4 Po = float4(IN.Position.xyz,1);
	float3 Pw = mul(WorldXf, Po).xyz;

	float normalLength = abs(IN.Normal.x + IN.Normal.y + IN.Normal.z);
	float speed = floor(normalLength);
	float hasNonZeroFlow = saturate(speed);
	float hasZeroFlow = 1.0 - hasNonZeroFlow;
	
	// encode: speed == 0 ? sintime : timeframe * speed
	float textureOffset = (hasNonZeroFlow * timeframe * speed) +
		hasZeroFlow * 0.125 * sintime;

	// encode: speed == 0 ? (x + offset, y) : (x, y + offset)
	float subsurfaceXCoord = IN.UvHigh.x - hasZeroFlow * 3.0 * textureOffset;
	float subsurfaceYCoord = IN.UvHigh.y - hasNonZeroFlow * 3.0 * textureOffset;

	float3 nNormal = normalize(IN.Normal);

	float normalDotLamp0 = dot(nNormal, Lamp0Pos);
	float normalDotLamp1 = dot(nNormal, Lamp1Pos);

	float light0DotNormal = saturate( normalDotLamp0 );
	float light1DotNormal = saturate( normalDotLamp1 );

	OUT.HPosition = mul(WvpXf,Po);
	OUT.UvLayer1 = float2(subsurfaceXCoord, subsurfaceYCoord);
	OUT.UvLayer2 = float2(IN.UvHigh.x, IN.UvHigh.y - 4.0 * textureOffset);
	OUT.UvLow = IN.UvLow;
	OUT.LightingColor = (light0DotNormal * Lamp0Color + light1DotNormal * Lamp1Color + ambientLight).xyz;

	return OUT;
}


////////////////////////////////////////////////////
// END COPY FROM CG SHADER

uniform float4x4 WorldITXf; // our four standard "untweakable" xforms
uniform float4x4 WorldXf;
uniform float4x4 ViewIXf;
uniform float4x4 WvpXf;
uniform float4x4 WvXf;
uniform float3 Lamp0Pos;
uniform float3 Lamp1Pos;
uniform float timeframe;
uniform float sintime;
uniform float3 ambientLight;
uniform float3 Lamp0Color;
uniform float3 Lamp1Color;

void main()
{
	AppdataTerrain IN;

	IN.Position = gl_Vertex.xyz;
	IN.Normal = gl_Normal;
	IN.UvHigh = gl_MultiTexCoord0.xy;
	IN.UvLow = gl_MultiTexCoord1.xy;

	WaterVertexOutput OUT = WaterVS( IN,
		WorldITXf, WorldXf, ViewIXf, WvpXf,
		WvXf, Lamp0Pos, Lamp1Pos, timeframe, sintime,
		ambientLight, Lamp0Color, Lamp1Color );

	gl_Position = OUT.HPosition;
	gl_FrontColor = vec4(OUT.LightingColor, 1);
	gl_TexCoord[0] = vec4(OUT.UvLayer1, 1, 1);
	gl_TexCoord[1] = vec4(OUT.UvLayer2, 1, 1);
	gl_TexCoord[2] = vec4(OUT.UvLow, 1, 1);
	
	// unlike CG, need to specify fixed function fog coord.
	// OUT.HPosition.w is the same metric used for part fogging (and is the
	// same metric used by fixed function fog after running CG vertex shader)
	gl_FogFragCoord = OUT.HPosition.w;
}
