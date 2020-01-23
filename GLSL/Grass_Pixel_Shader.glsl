uniform vec4 uDiffuseColor;
uniform vec4 uAmbientColor;
uniform vec3 uSpecularColor;
uniform float uShininess;
uniform float uShadowStrength;
uniform vec3 uShadowColor;
uniform float uBumpScale;

uniform sampler2D sGrassTex0;
uniform sampler2D sGrassTex1;
uniform sampler2D sGrassTex2;
uniform sampler2D sGrassTex3;

uniform sampler2D sNormalMap0;
uniform sampler2D sNormalMap1;
uniform sampler2D sNormalMap2;
uniform sampler2D sNormalMap3;

in Vertex
{
	vec4 color;
	mat3 tangentToWorld;

	vec3 worldSpacePos;
	vec3 worldSpaceNorm;
	flat int cameraIndex;
	vec2 uv;
	vec3 randomSize;
	flat int instance;

} iVert;

float rand(float n){return fract(sin(n) * 43758.5453123);}


// Output variable for the color
layout(location = 0) out vec4 oFragColor[TD_NUM_COLOR_BUFFERS];
void main()
{
	// This allows things such as order independent transparency
	// and Dual-Paraboloid rendering to work properly
	TDCheckDiscard();


	//sampler2D sGrassTexture[4] = sampler2D[4](sGrassTex0,sGrassTex1,sGrassTex2, sGrassTex3);
	//sampler2D sNormalMaps[4] = sampler2D[4](sNormalMap0,sNormalMap1,sNormalMap2, sNormalMap3);

	// sampler2D sGrassTexture[4];
	// sGrassTexture[0] = sGrassTex0;
	// sGrassTexture[1] = sGrassTex1;
	// sGrassTexture[2] = sGrassTex2;
	// sGrassTexture[3] = sGrassTex3;

	// sampler2D sNormalMaps[4];
	// sNormalMaps[0] = sNormalMap0;
	// sNormalMaps[1] = sNormalMap1;
	// sNormalMaps[2] = sNormalMap2;
	// sNormalMaps[3] = sNormalMap3;


	//sGrassTexture[3] = sGrassTex3;


	vec4 outcol = vec4(0.0, 0.0, 0.0, 0.0);
	vec3 diffuseSum = vec3(0.0, 0.0, 0.0);
	vec3 specularSum = vec3(0.0, 0.0, 0.0);
	

	// REGION - TIM
	vec2 newUV = iVert.uv;
	newUV.y *= iVert.randomSize.y;
	newUV.x *= iVert.randomSize.x;
	


	vec4 grassTex;
	vec4 normalMap;
	int textureSelection = iVert.instance % 4;
	switch (textureSelection){
		case 0:
			grassTex = texture(sGrassTex0, newUV);
			normalMap = texture(sNormalMap0, newUV);
			break;
		case 1:
			grassTex = texture(sGrassTex1, newUV);
			normalMap = texture(sNormalMap1, newUV);
			break;
		case 2:
			grassTex = texture(sGrassTex2, newUV);
			normalMap = texture(sNormalMap2, newUV);
			break;
		case 3:
			grassTex = texture(sGrassTex3, newUV);
			normalMap = texture(sNormalMap3, newUV);
			break;
		default:
			grassTex = texture(sGrassTex0, newUV);
			normalMap = texture(sNormalMap0, newUV);
			break;	
	}
	 

	vec3 worldSpaceNorm = normalize(iVert.worldSpaceNorm.xyz);
	vec3 norm = (2.0 * (normalMap.xyz - 0.5)).xyz;
	norm.xy = norm.xy * uBumpScale;
	norm = iVert.tangentToWorld * norm;
	vec3 normal = normalize(norm);

	vec3 viewVec = normalize(uTDMats[iVert.cameraIndex].camInverse[3].xyz - iVert.worldSpacePos.xyz );




	// END REGION -- TM


	// Flip the normals on backfaces
	// On most GPUs this function just return gl_FrontFacing.
	// However, some Intel GPUs on macOS have broken gl_FrontFacing behavior.
	// When one of those GPUs is detected, an alternative way
	// of determing front-facing is done using the position
	// and normal for this pixel.
	// if (!TDFrontFacing(iVert.worldSpacePos.xyz, worldSpaceNorm.xyz))
	// {
	// 	normal = -normal;
	// }

	// Your shader will be recompiled based on the number
	// of lights in your scene, so this continues to work
	// even if you change your lighting setup after the shader
	// has been exported from the Phong MAT
	for (int i = 0; i < TD_NUM_LIGHTS; i++)
	{
		vec3 diffuseContrib = vec3(0);
		vec3 specularContrib = vec3(0);
		TDLighting(diffuseContrib,
			specularContrib,
			i,
			iVert.worldSpacePos.xyz,
			normal,
			uShadowStrength, uShadowColor,
			viewVec,
			uShininess);
		diffuseSum += diffuseContrib;
		specularSum += specularContrib;
	}

	// Final Diffuse Contribution
	diffuseSum *= uDiffuseColor.rgb * iVert.color.rgb;
	vec3 finalDiffuse = diffuseSum;

	outcol.rgb += finalDiffuse;

	// Final Specular Contribution
	vec3 finalSpecular = vec3(0.0);
	specularSum *= uSpecularColor;
	finalSpecular += specularSum;

	outcol.rgb += finalSpecular;

	// Ambient Light Contribution
	outcol.rgb += vec3(uTDGeneral.ambientColor.rgb * uAmbientColor.rgb * iVert.color.rgb);
	outcol.rgb *= grassTex.rgb;

	// Apply fog, this does nothing if fog is disabled
	outcol = TDFog(outcol, iVert.worldSpacePos.xyz, iVert.cameraIndex);

	// Alpha Calculation
	float alpha = uDiffuseColor.a * iVert.color.a ;

	// Dithering, does nothing if dithering is disabled
	outcol = TDDither(outcol);

	outcol.rgb *= alpha;

	// Modern GL removed the implicit alpha test, so we need to apply
	// it manually here. This function does nothing if alpha test is disabled.
	TDAlphaTest(alpha);

	outcol.a = alpha;
	oFragColor[0] = TDOutputSwizzle(outcol);


	// TD_NUM_COLOR_BUFFERS will be set to the number of color buffers
	// active in the render. By default we want to output zero to every
	// buffer except the first one.
	for (int i = 1; i < TD_NUM_COLOR_BUFFERS; i++)
	{
		oFragColor[i] = vec4(0.0);
	}
}
