//
//  RWTBaseEffect.h
//  HelloOpenGL
//
//  Created by Ray Wenderlich on 9/3/13.
//  Copyright (c) 2013 Ray Wenderlich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

@interface BaseEffect : NSObject

@property (nonatomic, assign) GLuint programHandle;

@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, assign) GLKMatrix4 projectionMatrix;

@property (nonatomic, assign) GLuint texture;

@property (nonatomic, assign) GLKVector3 ambientLightingColor;
@property (nonatomic, assign) GLKVector3 diffuseLightingColor;
@property (nonatomic, assign) GLKVector3 specularLightingColor;

@property (nonatomic, assign) float materialShininess;

- (id)initWithVertexShader:(NSString *)vertexShader
            fragmentShader:(NSString *)fragmentShader;
- (void)prepareToDraw;

@end
