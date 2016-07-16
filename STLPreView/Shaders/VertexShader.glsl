
uniform highp mat4 modelViewMatrix;
uniform highp mat4 projectionMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec2 textureCoordinate;
attribute vec3 normal;

varying lowp vec4 fragColor;
varying lowp vec2 fragTextureCoordinate;
varying lowp vec3 fragNormal;
varying lowp vec3 fragPosition;

void main(void)
{
    fragColor = color;
    fragTextureCoordinate = textureCoordinate;
    gl_Position = projectionMatrix * modelViewMatrix * position;
    
    // NOTE: In order to convert normal data to camera coordinates
    // we multiply by the modelViewMatrix converting the normal to a 4 size vector
    // because the modelViewMatrix is a 4x4 size Matrix
    // and finally converting the resulting 4 size vector to a 3 size vector calling .xyz
    fragNormal = (modelViewMatrix * vec4(normal, 0.0)).xyz;
    
    fragPosition = (modelViewMatrix * position).xyz;
}