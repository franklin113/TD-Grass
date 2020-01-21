uniform vec4 uDiffuseColor;
uniform vec4 uAmbientColor;
uniform vec3 uSpecularColor;
uniform float uShininess;
uniform float uShadowStrength;
uniform vec3 uShadowColor;
in vec4 T;


//Non- built in uniforms
uniform sampler2D sWind;
uniform float uWindIntensity;
uniform ivec2 uRes;
uniform vec3 uRotationAxis;
uniform float uRandomStiffness;
uniform vec4 uCamPosition;


out Vertex
{
	vec4 color;
	mat3 tangentToWorld;

	vec3 worldSpacePos;
	vec3 worldSpaceNorm;
	flat int cameraIndex;
	vec2 uv;
	vec3 randomSize;
	flat int instance;
} oVert;

mat3 GetRotationMatrix(in float _instanceRotation, in vec3 _axis){
	return TDRotateOnAxis(uWindIntensity*P.y*_instanceRotation, _axis);
}

float rand(float n){return fract(sin(n) * 43758.5453123);}

in vec3 randomsize;


mat3 GetLookatRotationMatrix( in vec3 _instancePosition, in vec3 _cameraPosition, in vec3 _upVector){
	vec3 fwd = normalize(_instancePosition - _cameraPosition);
	vec3 right = normalize(cross(fwd,_upVector));
	fwd = normalize(cross(_upVector,right));

	return mat3(right, _upVector, fwd);
}


vec3 GetCameraPosition(in int _cameraIndex){
	vec3 cameraPos = uTDMats[_cameraIndex].camInverse[3].xyz;
	return cameraPos;
}

vec3 GetCameraPosition(){
	int cameraIndex = TDCameraIndex();
	return GetCameraPosition(cameraIndex);
}

void main()
{


	oVert.randomSize = randomsize; // we are scaling our grass per instance


	int instance = TDInstanceID();
	oVert.instance = instance;
	ivec2 currPixel = ivec2(0);
	int numInstances = uRes.x * uRes.y;
	currPixel.x = instance % uRes.x;
	currPixel.y = int(instance / uRes.x);
	
	vec2 instanceRotation = texelFetch(sWind, currPixel,0).rg;
	oVert.uv = uv[0].st;
	instanceRotation += rand(instance)*uRandomStiffness-uRandomStiffness/2;


	// -- Camera
	int cameraIndex = TDCameraIndex();
	vec3 cameraPosition = GetCameraPosition(cameraIndex);
	// ---


	
	// ----- REGION -- Rotation matrix Define

	mat3 rotationMatrixX = GetRotationMatrix(instanceRotation.x-.5,vec3(1,0,0));
	mat3 rotationMatrixZ = GetRotationMatrix(instanceRotation.y-.5, vec3(0,0,1));

	mat3 finalRotationMatrix = rotationMatrixX + rotationMatrixZ;
	

	mat3 lookAtMatrix = GetLookatRotationMatrix(TDInstanceTranslate(),cameraPosition, vec3(0,1,0));
	mat3 lookAtMatrixN = GetLookatRotationMatrix(N,cameraPosition, vec3(0,1,0));

	// ---- END Rotation Matrix define

	// ----- REGION -- PERFORM ROTATION

	vec3 newPosition = P;
	vec3 newNormals = N;

	newPosition = lookAtMatrix * P;
	newNormals = -lookAtMatrix * N;

	newPosition = finalRotationMatrix * newPosition;
	newNormals = finalRotationMatrix * newNormals;
	// ---- END PERFORM ROTATION

	// REGION --- BUILT IN STUFF


	// First deform the vertex and normal
	// TDDeform always returns values in world space
	vec4 worldSpacePos = TDDeform(newPosition);  //  ----- TIM ---- P became newPosition
	vec3 uvUnwrapCoord = TDInstanceTexCoord(TDUVUnwrapCoord());
	gl_Position = TDWorldToProj(worldSpacePos, uvUnwrapCoord);


	// This is here to ensure we only execute lighting etc. code
	// when we need it. If picking is active we don't need lighting, so
	// this entire block of code will be ommited from the compile.
	// The TD_PICKING_ACTIVE define will be set automatically when
	// picking is active.
#ifndef TD_PICKING_ACTIVE

	oVert.cameraIndex = cameraIndex;
	oVert.worldSpacePos.xyz = worldSpacePos.xyz;

	oVert.color = TDInstanceColor(Cd);
	vec3 worldSpaceNorm = normalize(TDDeformNorm(newNormals));
	vec3 worldSpaceTangent = TDDeformNorm(T.xyz);
	
	oVert.worldSpaceNorm.xyz = worldSpaceNorm;
	oVert.tangentToWorld = TDCreateTBNMatrix(worldSpaceNorm, worldSpaceTangent, T.w);

#else // TD_PICKING_ACTIVE

	// This will automatically write out the nessessary values
	// for this shader to work with picking.
	// See the documentation if you want to write custom values for picking.
	TDWritePickingValues();

#endif // TD_PICKING_ACTIVE
}
