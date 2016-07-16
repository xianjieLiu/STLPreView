//
//  ZJLFModelPreviewController.m
//  ZJLFCommunity
//
//  Created by liuxianjie on 16/1/7.
//  Copyright © 2016年 紫晶立方科技有限公司. All rights reserved.
//

#import "LXJModelPreviewController.h"
#import "Vertex.h"
#import "BaseEffect.h"
#import "Model.h"


@interface LXJModelPreviewController ()

@property (nonatomic, strong)NSMutableArray *normalArray;
@property (nonatomic, strong)NSMutableArray *pointArray;
@property (nonatomic, assign)GLKMatrix4 rotMatrix;
@property (nonatomic, strong)UISwipeGestureRecognizer *leftSwip;
@property (nonatomic, strong)UISwipeGestureRecognizer *rightSwip;
@property (nonatomic, strong)UISwipeGestureRecognizer *downSwip;
@property (nonatomic, strong)UISwipeGestureRecognizer *upSwip;
@property (nonatomic, assign)GLKMatrix4 modelViewMatrix;
@property (nonatomic, assign)CGFloat scale;
@property (nonatomic, assign)CGFloat rember_scale;
@property (nonatomic, strong)UIView *bgView;
@property (nonatomic, assign)CGFloat progressRate;
@property (nonatomic, assign)float maxX;
@property (nonatomic, assign)float maxY;
@property (nonatomic, assign)float maxZ;
@property (nonatomic, assign)float minX;
@property (nonatomic, assign)float minY;
@property (nonatomic, assign)float minZ;
@property (nonatomic, assign)float translation_z;
@end


@implementation LXJModelPreviewController
{
    BaseEffect *_shader;
    Model *_stlModel;
    
    Vertex *treeVertices;
    
    GLKVector3 _anchor_position;
    GLKVector3 _current_position;
    GLKQuaternion _quatStart;
    GLKQuaternion _quat;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.scale = 1;
        self.rember_scale = 1;
        self.rotMatrix = GLKMatrix4Identity;
        
        GLKView *view = (GLKView *)self.view;
        view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        
        [EAGLContext setCurrentContext:view.context];
        
        self.rotMatrix = GLKMatrix4Identity;
        _quat = GLKQuaternionMake(0, 0, 0, 1);
        _quatStart = GLKQuaternionMake(0, 0, 0, 1);
        
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchGestureRecognizer:)];
        [self.view addGestureRecognizer:pinch];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panGestureRecognizer:)];
        [self.view addGestureRecognizer:pan];
        
        [self setupScene:nil];

    });
    
}

-(void)setupScene:(NSString *)filePath
{
    _shader = [[BaseEffect alloc] initWithVertexShader:@"VertexShader.glsl" fragmentShader:@"FragmentShader.glsl"];
    
    [_shader setProjectionMatrix:GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0), self.view.bounds.size.width / self.view.bounds.size.height, 1, 150)];
    
     NSString *filePath1 = [[NSBundle mainBundle] pathForResource:@"牛仔" ofType:@"stl"];
    
    NSData *data = [[NSData alloc]initWithContentsOfFile:filePath1];
    
    NSString *dataStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    _pointArray = [NSMutableArray arrayWithCapacity:0];
    _normalArray = [NSMutableArray arrayWithCapacity:0];
    
    if (!dataStr) {
        [self processBinaryWithData:data];
    } else {
        [self processASCIIWithDataStr:dataStr];
    }
    
    treeVertices=(Vertex*)malloc(self.pointArray.count * sizeof(Vertex));
    
    for (int i=0; i<self.pointArray.count; i++) {
        for (int n=0; n<4; n++) {
            treeVertices[i].Color[n] = 0.0f;
        }
        for (int j = 0; j<3; j++) {
            treeVertices[i].Normal[j] = [self.normalArray[i/3][j] floatValue];
        }
        for (int k = 0; k<3; k++) {
            treeVertices[i].Position[k] = [self.pointArray[i][k] floatValue];
        }
    }
    
    _stlModel = [[Model alloc]initWithName:"TreeModel" shader:_shader vertices:treeVertices vertexCount:(int)self.pointArray.count];
    [_stlModel setTranslation:GLKVector3Make(0.0f, -2.0f, 0.0f)];
}

- (void)processASCIIWithDataStr:(NSString *)dataStr
{
    int i = 0;
    
    NSArray *array1 = [dataStr componentsSeparatedByString:@"\n"];
    
    for (NSString *str in array1) {
        if ([str containsString:@"facet normal"]) {
            NSString *normalStr = [[str componentsSeparatedByString:@"facet normal "] lastObject];
            NSArray *normalArray = [normalStr componentsSeparatedByString:@" "];
            [_normalArray addObject:normalArray];
        }
        if ([str containsString:@"vertex"]) {
            
            NSString *pointStr = [[str componentsSeparatedByString:@"vertex"] lastObject];
            NSArray *pointArray = [pointStr componentsSeparatedByString:@" "];
            NSMutableArray *array = [NSMutableArray arrayWithArray:pointArray];
            
            for (int i = 0; i<array.count; i++) {
                NSString *str1 = array[i];
                if (str1.length == 0) {
                    [array removeObject:str1];
                }
            }
            
            if (i == 0) {
                _maxX = _minX = [array[0] floatValue];
                _maxY = _minY = [array[1] floatValue];
                _maxZ = _minZ = [array[2] floatValue];
            }
            
            [self adjustMaxMinFromX:[array[0] floatValue] andY:[array[1] floatValue] and:[array[2] floatValue]];
            [_pointArray addObject:array];
            
            i++;
        }
    }
    
    [self postExcute];
    [self TransLation_Z];
    
    
}
- (void)processBinaryWithData:(NSData *)data
{
    
    uint8_t *readBytes = (uint8_t *)[data bytes];
    int vertext_size = [self getIntWithLittleEndian:readBytes andOffset:80];
    
    for (int i= 0; i<vertext_size; i++) {
        //面的法向量
        NSMutableArray *subNormalArray= [NSMutableArray arrayWithCapacity:0];
        for (int j=0; j<3; j++) {
            
            float a = [self intBitToFloat:[self getIntWithLittleEndian:readBytes andOffset:84 + i * 50 + j * 4]];
            NSNumber *number = [[NSNumber alloc]initWithFloat:a];
            [subNormalArray addObject:number];
            
        }
        [_normalArray addObject:subNormalArray];
        
        //面的顶点
        for (int k = 0; k < 3; k++) {
            
            NSMutableArray *subPointArray = [NSMutableArray arrayWithCapacity:0];
            
            float x = [self intBitToFloat:[self getIntWithLittleEndian:readBytes andOffset:84 + i * 50 + 12 + k * 12]];
            float y = [self intBitToFloat:[self getIntWithLittleEndian:readBytes andOffset:84 + i * 50 + 12 + k * 12 + 4]];
            float z = [self intBitToFloat:[self getIntWithLittleEndian:readBytes andOffset:84 + i * 50 + 12 + k * 12 + 8]];
            if (i == 0 && k==0) {
                _maxX = _minX = x;
                _maxY = _minY = y;
                _maxZ = _minZ = z;
            }
            [self adjustMaxMinFromX:x andY:y and:z];
            
            NSNumber *xNumber = [[NSNumber alloc]initWithFloat:x];
            NSNumber *yNumber = [[NSNumber alloc]initWithFloat:y];
            NSNumber *zNumber = [[NSNumber alloc]initWithFloat:z];
            
            [subPointArray addObject:xNumber];
            [subPointArray addObject:yNumber];
            [subPointArray addObject:zNumber];
            
            [_pointArray addObject:subPointArray];
        }
        
        if ([subNormalArray[0] compare:[NSNumber numberWithFloat:0.0000000]]== NSOrderedSame &&
            [subNormalArray[1] compare:[NSNumber numberWithFloat:0.0000000]]== NSOrderedSame &&
            [subNormalArray[2] compare:[NSNumber numberWithFloat:0.0000000]]== NSOrderedSame) {
            
            float x1 = [_pointArray[i*3][0] floatValue];
            float y1 = [_pointArray[i*3][1] floatValue];
            float z1 = [_pointArray[i*3][2] floatValue];
            
            float x2 = [_pointArray[i*3+1][0] floatValue];
            float y2 = [_pointArray[i*3+1][1] floatValue];
            float z2 = [_pointArray[i*3+1][2] floatValue];
            
            float x3 = [_pointArray[i*3+2][0] floatValue];
            float y3 = [_pointArray[i*3+2][1] floatValue];
            float z3 = [_pointArray[i*3+2][2] floatValue];
            
            float z = 0.000000001;
            
            float x = ((z1-z2)*(y3-y1) - (z1-z3)*(y2-y1)) / ((x2-x1)*(y3-y1) - (x3-x1)*(y2-y1));
            float y = ((z1-z2)-(x2-x1)*x)/(y2-y1);
            
            [subNormalArray replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:x]];
            [subNormalArray replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:y]];
            [subNormalArray replaceObjectAtIndex:2 withObject:[NSNumber numberWithFloat:z]];
            
        }

    }
    [self postExcute];
    [self TransLation_Z];
    
    
}
- (void)postExcute
{
    
    float center_x=(_maxX+_minX)/2;
    float center_y=(_maxY+_minY)/2;
    float center_z=(_maxZ+_minZ)/2;
    
    for (NSMutableArray *array in _pointArray) {
        
        float x = [array[0] floatValue] - center_x;
        float y = [array[1] floatValue] - center_y;
        float z = [array[2] floatValue] - center_z;
        NSNumber *numberX = [[NSNumber alloc]initWithFloat:x];
        NSNumber *numberY = [[NSNumber alloc]initWithFloat:y];
        NSNumber *numberZ = [[NSNumber alloc]initWithFloat:z];
        
        [array replaceObjectAtIndex:0 withObject:numberX];
        [array replaceObjectAtIndex:1 withObject:numberY];
        [array replaceObjectAtIndex:2 withObject:numberZ];
        
    }
    
}

- (void)pinchGestureRecognizer:(UIPinchGestureRecognizer*) recognizer
{
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        _scale = _rember_scale * recognizer.scale;
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        _rember_scale = _scale;
    }
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)pan
{
    CGPoint location = [pan locationInView:self.view];
    CGPoint diff = [pan translationInView:self.view];
    
    float rotX = -1 * GLKMathDegreesToRadians(diff.y / 2.0);
    float rotY = -1 * GLKMathDegreesToRadians(diff.x / 2.0);
    
    bool isInvertible;
    GLKVector3 xAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(1, 0, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotX, xAxis.x, xAxis.y, xAxis.z);
    GLKVector3 yAxis = GLKMatrix4MultiplyVector3(GLKMatrix4Invert(_rotMatrix, &isInvertible), GLKVector3Make(0, 1, 0));
    _rotMatrix = GLKMatrix4Rotate(_rotMatrix, rotY, yAxis.x, yAxis.y, yAxis.z);
    
    _current_position = GLKVector3Make(location.x, location.y, 0);
    _current_position = [self projectOntoSurface:_current_position];
    
    [self computeIncremental];
    
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0/255.0, 0.0/255.0, 0.0/255.0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    GLKMatrix4 viewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0f, _translation_z);
    viewMatrix = GLKMatrix4Rotate(viewMatrix, GLKMathDegreesToRadians(20), 1, 0, 0);
    
    [_stlModel renderModelWithParentModelViewMatrix:viewMatrix andPaintStyle:PaintStyleTriangles];
}

- (void)update
{
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 1000.0f);
    [_shader setProjectionMatrix:projectionMatrix];
    _modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, -1.0f, -6.0f);
    
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(_quat);
    _modelViewMatrix = GLKMatrix4Multiply(_modelViewMatrix, rotation);
    
    _modelViewMatrix = GLKMatrix4Scale(_modelViewMatrix, _scale, _scale, _scale);
    _stlModel.rotMatrix = _modelViewMatrix;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.view];
    _anchor_position = GLKVector3Make(location.x, location.y, 0);
    
    _anchor_position = [self projectOntoSurface:_anchor_position];
    
    _current_position = _anchor_position;
    _quatStart = _quat;
    
}

- (void)computeIncremental {
    
    GLKVector3 axis = GLKVector3CrossProduct(_anchor_position, _current_position);
    float dot = GLKVector3DotProduct(_anchor_position, _current_position);
    
    float angle = acosf(dot);
    
    GLKQuaternion Q_rot = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    Q_rot = GLKQuaternionNormalize(Q_rot);
    
    // TODO: Do something with Q_rot...
    _quat = GLKQuaternionMultiply(Q_rot, _quatStart);
    
}
- (GLKVector3) projectOntoSurface:(GLKVector3) touchPoint
{
    float radius = self.view.bounds.size.width/3;
    GLKVector3 center = GLKVector3Make(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 0);
    GLKVector3 P = GLKVector3Subtract(touchPoint, center);
    
    // Flip the y-axis because pixel coords increase toward the bottom.
    P = GLKVector3Make(P.x, P.y * -1, P.z);
    
    float radius2 = radius * radius;
    float length2 = P.x*P.x + P.y*P.y;
    
    if (length2 <= radius2)
        P.z = sqrt(radius2 - length2);
    else
    {
        /*
         P.x *= radius / sqrt(length2);
         P.y *= radius / sqrt(length2);
         P.z = 0;
         */
        P.z = radius2 / (2.0 * sqrt(length2));
        float length = sqrt(length2 + P.z * P.z);
        P = GLKVector3DivideScalar(P, length);
    }
    
    return GLKVector3Normalize(P);
}

- (void)TransLation_Z
{
    float distance_x = _maxX - _minX;
    float distance_y = _maxY - _minY;
    float distance_z = _maxZ - _minZ;
    _translation_z = distance_x;
    if (_translation_z < distance_y) {
        _translation_z = distance_y;
    }
    if (_translation_z < distance_z) {
        _translation_z = distance_z;
    }
    _translation_z *= -2;
    
}

- (float)intBitToFloat:(int)bits
{
    int s = ((bits >> 31) == 0) ? 1 : -1;
    int e = ((bits >> 23) & 0xff);
    int m = (e == 0) ?
    (bits & 0x7fffff) << 1 :
    (bits & 0x7fffff) | 0x800000;
    float a = s * m * pow(2, e-150);
    return a;
}


- (int)getIntWithLittleEndian:(Byte *)stlBytes andOffset:(int)offset
{
    return (0xff & stlBytes[offset]) | ((0xff & stlBytes[offset + 1]) << 8) | ((0xff & stlBytes[offset + 2]) << 16) | ((0xff & stlBytes[offset + 3]) << 24);
}


- (void)adjustMaxMinFromX:(float)x andY:(float)y and:(float)z
{
    
    if (x > _maxX) {
        _maxX = x;
    }
    if (y > _maxY) {
        _maxY = y;
    }
    if (z > _maxZ) {
        _maxZ = z;
    }
    if (x < _minX) {
        _minX = x;
    }
    if (y < _minY) {
        _minY = y;
    }
    if (z < _minZ) {
        _minZ = z;
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)dealloc
{
    //[self removeObserver:self forKeyPath:@"completedUnitCount"];
//    _shader = nil;
//    _tree = nil;
}

@end
