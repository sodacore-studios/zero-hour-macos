#pragma once
struct Vector2 { float X,Y; };
struct Vector3 { float X,Y,Z; Vector3(float x=0,float y=0,float z=0):X(x),Y(y),Z(z){} };
struct Matrix3D { float v[3][3]; const float* operator[](int i)const{return v[i];} };
struct CameraClass {
 Vector2 lo,hi; Vector3 eye; Matrix3D matrix;
 void Get_View_Plane(Vector2& l,Vector2& h)const{l=lo;h=hi;}
 const Matrix3D& Get_Transform()const{return matrix;}
 Vector3 Get_Position()const{return eye;}
};
