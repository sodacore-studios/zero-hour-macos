#include "TerrainViewBounds.h"
#include <cstdio>
#include <cstdlib>
int main(){
 WorldHeightMap map; int cases=0, visiblePoints=0;
 for(float aspect:{4.f/3,16.f/9,21.f/9,32.f/9})
 for(float height:{310.f,600.f,1000.f})
 for(float pitchDeg:{20.f,37.5f,60.f})
 for(float yawDeg:{0.f,30.f,45.f,90.f,135.f,180.f}) {
  float p=pitchDeg*3.14159265f/180, y=yawDeg*3.14159265f/180;
  CameraClass c; float sy=sin(y),cy=cos(y),sp=sin(p),cp=cos(p);
  c.matrix={{{cy,-sy*sp,sy*cp},{sy,cy*sp,-cy*cp},{0,cp,sp}}};
  c.eye={sy*cp*height/sp,-cy*cp*height/sp,height};
  float halfY=tan(25.f*3.14159265f/180)/(4.f/3);
  c.lo={-halfY*aspect,-halfY};c.hi={halfY*aspect,halfY};
  auto b=TerrainViewBounds::calculate(c,map,0,500);
  for(int x=-4500;x<=4500;x+=150)for(int y=-4500;y<=4500;y+=150)for(int z:{0,100,500}){
   float d[3]={x-c.eye.X,y-c.eye.Y,z-c.eye.Z},v[3]={};
   for(int col=0;col<3;++col)for(int row=0;row<3;++row)v[col]+=d[row]*c.matrix[row][col];
   if(v[2]>=0)continue;
   float sx=v[0]/-v[2],sy=v[1]/-v[2];
   if(sx<c.lo.X||sx>c.hi.X||sy<c.lo.Y||sy>c.hi.Y)continue;
   int gx=x/10+500,gy=y/10+500;++visiblePoints;
   if(gx<b.minX||gx>b.maxX||gy<b.minY||gy>b.maxY){printf("FAIL aspect=%f height=%f pitch=%f yaw=%f point=%d,%d,%d bounds=%d,%d,%d,%d\n",aspect,height,pitchDeg,yawDeg,x,y,z,b.minX,b.minY,b.maxX,b.maxY);return 1;}
  }
  ++cases;
 }
 printf("PASS: %d camera configurations; %d independently projected visible terrain points covered.\n",cases,visiblePoints);
}
