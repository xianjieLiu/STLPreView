//
//  RWTBaseEffect.m
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 9/3/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import "BaseEffect.h"
#import "Vertex.h"

@implementation BaseEffect
{
    GLuint _programHandle;
    
    GLuint _modelViewMatrixUniform;
    GLuint _projectionMatrixUniform;
    
    GLuint _textureUniform;
    
    GLuint _lightingColorUniform;
    GLuint _lightingDirectionUniform;
    
    GLuint _ambientLightingColorMaterialUniform;
    
    GLuint _diffuseLightingColorMaterialUniform;
    
    GLuint _specularLightingColorMaterialUniform;
    GLuint _specularLightingShininessMaterialUniform;
}

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    
    if (!shaderString)
    {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char* shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    
    if (compileSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        
        NSLog(@"%@", messageString);
        
        exit(1);
    }
    
    return shaderHandle;
}

- (void)compileVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    GLuint vertexShaderName = [self compileShader:vertexShader
                                         withType:GL_VERTEX_SHADER];
    
    GLuint fragmentShaderName = [self compileShader:fragmentShader
                                           withType:GL_FRAGMENT_SHADER];
    
    _programHandle = glCreateProgram();
    glAttachShader(_programHandle, vertexShaderName);
    glAttachShader(_programHandle, fragmentShaderName);
    
    glBindAttribLocation(_programHandle, VertexAttributePosition, "position");
    glBindAttribLocation(_programHandle, VertexAttributeColor, "color");
    glBindAttribLocation(_programHandle, VertexAttributeTextureCoordinate, "textureCoordinate");
    glBindAttribLocation(_programHandle, VertexAttributeNormal, "normal");
    
    glLinkProgram(_programHandle);
    
    self.modelViewMatrix = GLKMatrix4Identity;
    
    _modelViewMatrixUniform = glGetUniformLocation(_programHandle, "modelViewMatrix");
    
    _projectionMatrixUniform = glGetUniformLocation(_programHandle, "projectionMatrix");
    
    _textureUniform = glGetUniformLocation(_programHandle, "uniformTexture");
    
    _lightingColorUniform = glGetUniformLocation(_programHandle, "uniformLight.Color");
    _lightingDirectionUniform = glGetUniformLocation(_programHandle, "uniformLight.Direction");
    
    _ambientLightingColorMaterialUniform = glGetUniformLocation(_programHandle, "uniformAmbientLightingColorMaterial");
    
    _diffuseLightingColorMaterialUniform = glGetUniformLocation(_programHandle, "uniformDiffuseLightingColorMaterial");
    
    _specularLightingColorMaterialUniform = glGetUniformLocation(_programHandle, "uniformSpecularLightingColorMaterial");
    _specularLightingShininessMaterialUniform = glGetUniformLocation(_programHandle, "uniformShinines");
    
    GLint linkSuccess;
    glGetProgramiv(_programHandle, GL_LINK_STATUS, &linkSuccess);
    
    if (linkSuccess == GL_FALSE)
    {
        GLchar messages[256];
        
        glGetProgramInfoLog(_programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        
        exit(1);
    }
}

- (void)prepareToDraw
{
    //vertices
    glUseProgram(_programHandle);
    glUniformMatrix4fv(_modelViewMatrixUniform, 1, 0, self.modelViewMatrix.m);
    glUniformMatrix4fv(_projectionMatrixUniform, 1, 0, self.projectionMatrix.m);
    
    //texture
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.texture);
    glUniform1i(_textureUniform, 1);
    
    //lighting
    glUniform3f(_lightingColorUniform, 1.0f, 1.0f, 1.0f);
    
    //ambient lighting
    glUniform3f(_ambientLightingColorMaterialUniform, self.ambientLightingColor.r, self.ambientLightingColor.g, self.ambientLightingColor.b);
    
    //diffuse lighting
    GLKVector3 diffuseLightDirection = GLKVector3Normalize(GLKVector3Make(0.0f, 1.0f, -1.0f));
    glUniform3f(_lightingDirectionUniform, diffuseLightDirection.x, diffuseLightDirection.y, diffuseLightDirection.z);
    glUniform3f(_diffuseLightingColorMaterialUniform, self.diffuseLightingColor.r,  self.diffuseLightingColor.g,  self.diffuseLightingColor.b);
    
    //specular lighting
    glUniform3f(_specularLightingColorMaterialUniform, self.specularLightingColor.r, self.specularLightingColor.g, self.specularLightingColor.b);
    glUniform1f(_specularLightingShininessMaterialUniform, self.materialShininess);
}

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader
{
    if ((self = [super init]))
    {
        [self compileVertexShader:vertexShader fragmentShader:fragmentShader];
    }
    
    return self;
}

@end