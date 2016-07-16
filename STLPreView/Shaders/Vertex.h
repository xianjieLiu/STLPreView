//
//  Vertex.h
//  OpenGLIntroColorScreen
//
//  Created by Streetwizard on 12/30/14.
//  Copyright (c) 2014 WizArt Interactive. All rights reserved.
//

typedef enum
{
    VertexAttributePosition = 0,
    VertexAttributeColor,
    VertexAttributeTextureCoordinate,
    VertexAttributeNormal
} VertexAttributes;

typedef struct
{
    GLfloat Position[3];
    GLfloat Color[4];
    GLfloat TextureCoordinate[2];
    GLfloat Normal[3];
} Vertex;
