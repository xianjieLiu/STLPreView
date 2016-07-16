//
//  Model.m
//  OpenGLIntroColorScreen
//
//  Created by liuxianjie on 12/30/14.
//  Copyright (c) 2014 WizArt Interactive. All rights reserved.
//

#import "Model.h"

const GLKVector4 treeAmbientLightingColor = {1.000000f, 0.000000f, 0.000000f, 1.000000f};//环境
const GLKVector4 treeDiffuseLightingColor = {1.0000000f, 0.000000f, 0.000000f, 1.000000f};//弥漫性
const GLKVector4 treeSpecularLightingColor = {0.5000000f, 0.0000000f, 0.000000f, 1.0000000f};//镜面

const float treeShininess = 0.5;

@implementation Model
{
    char * _name;
    
    GLuint _vertexArrayObject;
    GLuint _vertexBuffer;
    
    int _vertexCount;
    
    BaseEffect* _shader;
}

-(instancetype)initWithName:(char *)name
                     shader:(BaseEffect *)shader
                   vertices:(Vertex *)vertices
                vertexCount:(int)vertexCount
{
    if((self = [super init]))
    {
        _name = name;
        _shader = shader;
        _vertexCount = vertexCount;
        
        [self setupAmbient];
        
        self.translation = GLKVector3Make(0, 0, 0);
        self.rotationX = 0.0f;
        self.rotationY = 0.0f;
        self.rotationZ = 0.0f;
//        self.scaleX = 0.05f;
//        self.scaleY = 0.05f;
//        self.scaleZ = 0.05f;
        
        //Generate vertex array objects
        glGenVertexArraysOES(1, &_vertexArrayObject);
        glBindVertexArrayOES(_vertexArrayObject);
        
        // Generate vertex buffer
        
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, (_vertexCount * sizeof(Vertex)), vertices, GL_STATIC_DRAW);
    
        // Enabling vertex attributes
        
        glEnableVertexAttribArray(VertexAttributePosition);
        glVertexAttribPointer(VertexAttributePosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
        
        glEnableVertexAttribArray(VertexAttributeColor);
        glVertexAttribPointer(VertexAttributeColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
        
        glEnableVertexAttribArray(VertexAttributeTextureCoordinate);
        glVertexAttribPointer(VertexAttributeTextureCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TextureCoordinate));
        
        glEnableVertexAttribArray(VertexAttributeNormal);
        glVertexAttribPointer(VertexAttributeNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Normal));
        glLineWidth(1);
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        
        glBindVertexArrayOES(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        
    }
    
    return self;
}

- (void)setupAmbient
{
    [self loadTexture:@"tree_1024x1024.png"];
    
    self.ambientLightingColor = GLKVector3Make(treeAmbientLightingColor.r, treeAmbientLightingColor.g, treeAmbientLightingColor.b);
    self.diffuseLightingColor = GLKVector3Make(treeDiffuseLightingColor.r, treeDiffuseLightingColor.g, treeDiffuseLightingColor.b);
    self.specularLightingColor = GLKVector3Make(treeSpecularLightingColor.r, treeSpecularLightingColor.g, treeSpecularLightingColor.b);
    self.materialShininess = treeShininess;

}

- (GLKMatrix4)modelMatrix
{
    GLKMatrix4 modelMatrix = GLKMatrix4Identity;

    modelMatrix = GLKMatrix4Translate(modelMatrix, self.translation.x, self.translation.y, self.translation.z);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotationX, 1, 0, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotationY, 0, 1, 0);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, self.rotationZ, 0, 0, 1);
    modelMatrix = GLKMatrix4Scale(modelMatrix, self.scaleX, self.scaleY, self.scaleZ);

    return modelMatrix;
}

- (void)updateWithDelta:(NSTimeInterval)delta
{
    
}

- (void)renderModelWithParentModelViewMatrix:(GLKMatrix4)parentModelViewMatrix andPaintStyle:(PaintStyle)style
{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(parentModelViewMatrix, _rotMatrix);
    
    _shader.modelViewMatrix = modelViewMatrix;
    
    [_shader setTexture:self.texture];
    [_shader setAmbientLightingColor:self.ambientLightingColor];
    [_shader setDiffuseLightingColor:self.diffuseLightingColor];
    [_shader setSpecularLightingColor:self.specularLightingColor];
    [_shader setMaterialShininess:self.materialShininess];
    
    [_shader prepareToDraw];
    
    glBindVertexArrayOES(_vertexArrayObject);
    if (style == PaintStyleTriangles) {
        glDrawArrays(GL_TRIANGLES, 0, _vertexCount);
    } else {
        glDrawArrays(GL_LINES, 0, _vertexCount);
    }
    glBindVertexArrayOES(0);
}

- (void)loadTexture:(NSString *)textureFileName
{
    NSError* error;
    NSString* path = [[NSBundle mainBundle]pathForResource:textureFileName ofType:nil];
    
    NSDictionary* options = @{ GLKTextureLoaderOriginBottomLeft: @YES };
    
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    
    if(textureInfo != nil)
    {
        self.texture = textureInfo.name;
    }
    else
    {
        NSLog(@"Error loading texture file: %@", error.localizedDescription);
    }
    
}

@end
