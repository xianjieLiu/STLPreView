varying lowp vec4 fragColor;
varying lowp vec2 fragTextureCoordinate;
varying lowp vec3 fragNormal;
varying lowp vec3 fragPosition;

uniform sampler2D uniformTexture;

uniform highp float uniformShinines;

uniform highp vec3 uniformAmbientLightingColorMaterial;
uniform highp vec3 uniformDiffuseLightingColorMaterial;
uniform highp vec3 uniformSpecularLightingColorMaterial;

struct Light
{
    lowp vec3 Color;
    lowp vec3 Direction;
};

uniform Light uniformLight;

void main(void)
{
    //ambient lighting
    lowp vec3 ambientLightingColor = uniformLight.Color * uniformAmbientLightingColorMaterial;
    
    //diffuse lighting
    lowp vec3 normal = normalize(fragNormal);
    lowp float diffuseFactor = max(-dot(normal, uniformLight.Direction), 0.0);
    lowp vec3 diffuseLightingColor = uniformLight.Color * uniformDiffuseLightingColorMaterial * diffuseFactor;
    
    //specular lighting
    lowp vec3 eye = normalize(fragPosition);
    lowp vec3 reflection = reflect(uniformLight.Direction, normal);
    lowp float specularFactor = pow(max(1.0, -dot(reflection, eye)), uniformShinines);
    lowp vec3 specularLightingColor = uniformLight.Color * uniformSpecularLightingColorMaterial * specularFactor;
    
    gl_FragColor = texture2D(uniformTexture, fragTextureCoordinate) * vec4((ambientLightingColor + diffuseLightingColor + specularLightingColor), 1.0);
}