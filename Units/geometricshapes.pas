unit GeometricShapes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  BGRABitmap, BGRABitmapTypes ;


const

  SHAPECOUNT = 18;

  WIDTHTEMPLATE = 100;     // on utilise un cadre de 100x100 pointF pour repérer les sommets du tracé.


type

{ TGeometricShapes }

TGeometricShapes = class
private
  procedure SetGlobalColor(AValue: TBGRAPixel);
  protected
    FPointsArray: ArrayOfTPointF;
    FPointsArrayScaled: ArrayOfTPointF;
    storedSpline: ArrayOfTPointF;
    FPenWidthPercent: single;  // Pen width is relative to bitmap width
    FPenWidth: single;
    FGlobalColor: TBGRAPixel;
    FPenColor: TBGRAPixel;
    FFillColor: TBGRAPixel;
    FApplyLight: boolean;
    FMarginPercent,  // Margins are relative to bitmap width
    HMargin,
    VMargin,
    Radius,
    XImageCenter,
    YImageCenter: single;
    function ScalePoints(aWidth, aHeight: integer): ArrayOfTPointF;
    procedure DrawShapeGradient(aBitmap: TBGRACustomBitmap);
    procedure DrawShape(aBitmap: TBGRACustomBitmap; aPts:ArrayOfTPointF);
    procedure DrawSpline(aBitmap: TBGRACustomBitmap; aPts:ArrayOfTPointF);
  public
    Constructor Create;
    Destructor Destroy; override;
    // Available Shapes
    procedure DrawArrowUp(aBitmap: TBGRACustomBitmap);
    procedure DrawArrowDown(aBitmap: TBGRACustomBitmap);
    procedure DrawArrowLeft(aBitmap: TBGRACustomBitmap);
    procedure DrawArrowRight(aBitmap: TBGRACustomBitmap);
    procedure DrawSquare(aBitmap: TBGRACustomBitmap);
    procedure DrawTriangle(aBitmap: TBGRACustomBitmap);
    procedure DrawLozenge(aBitmap: TBGRACustomBitmap);
    procedure DrawPlus(aBitmap: TBGRACustomBitmap);
    procedure DrawMultiply(aBitmap: TBGRACustomBitmap);
    procedure DrawX(aBitmap: TBGRACustomBitmap);
    procedure DrawStar(aBitmap: TBGRACustomBitmap);
    procedure DrawFlash(aBitmap: TBGRACustomBitmap);
    procedure DrawHexagon(aBitmap: TBGRACustomBitmap);
    procedure DrawCircle(aBitmap: TBGRACustomBitmap);
    procedure DrawRing(aBitmap: TBGRACustomBitmap);
    procedure DrawEgg(aBitmap: TBGRACustomBitmap);
    procedure DrawHeart(aBitmap: TBGRACustomBitmap);
    procedure DrawFlower(aBitmap: TBGRACustomBitmap);

    procedure DrawMouseCursor(aBitmap: TBGRACustomBitmap);

    property GlobalColor: TBGRAPixel read FGlobalColor write SetGlobalColor;
    property PenWidth: single read FPenWidth write FPenWidth;
    property PenColor: TBGRAPixel read FPenColor write FPenColor;
    property FillColor: TBGRAPixel read FFillColor write FFillColor;
    property ApplyLight: boolean read FApplyLight write FApplyLight;
    property MarginPercent: single read FMarginPercent write FMarginPercent;
    property PenWidthPercent: single read FPenWidthPercent write FPenWidthPercent;
end;


var
  FGeometricShapes: TGeometricShapes;

implementation


function PercentColor(aColor: TBGRAPixel; aPercent: single): TBGRAPixel;
var b,g,r:integer ;
begin
 b := round(aColor.blue*aPercent); if b>255 then b:=255 else if b<0 then b:=0;
 g := round(aColor.green*aPercent); if g>255 then g:=255 else if g<0 then g:=0;
 r := round(aColor.red*aPercent); if r>255 then r:=255 else if r<0 then r:=0;
 Result.blue:=b;
 Result.green:=g;
 Result.red:=r;
 Result.alpha:=aColor.alpha;
end;

{ TGeometricShapes }

constructor TGeometricShapes.Create;
begin
 FPenColor := BGRAWhite ;
 FFillColor := PercentColor(FPenColor,45);
 FApplyLight := TRUE ;
 FMarginPercent := 4/100 ;
 FPenWidthPercent := 1/100 ;
end;

destructor TGeometricShapes.Destroy;
begin
 inherited Destroy;
end;

procedure TGeometricShapes.SetGlobalColor(AValue: TBGRAPixel);
begin
  FGlobalColor:=AValue;
  FPenColor := PercentColor(FGlobalColor,0.75) ;
  FFillColor := FGlobalColor ;
end;

function TGeometricShapes.ScalePoints(aWidth, aHeight: integer): ArrayOfTPointF;
var i : integer ;
  Factor: single;
begin
 if aWidth <= aHeight then begin
   HMargin := aWidth * FMarginPercent ;
   Factor := (aWidth-HMargin*2)/WIDTHTEMPLATE ;
   VMargin := (aHeight-Factor*WIDTHTEMPLATE)/2;
   FPenWidth := aWidth*FPenWidthPercent ;
   Radius := (aWidth-HMargin*2) / 2 ;
 end else begin
  VMargin := aHeight * FMarginPercent ;
  Factor := (aHeight-VMargin*2)/WIDTHTEMPLATE ;
  HMargin := (aWidth-Factor*WIDTHTEMPLATE)/2;
  FPenWidth := aHeight*FPenWidthPercent ;
  Radius := (aHeight-VMargin*2) / 2 ;
 end;

 XImageCenter := aWidth shr 1 ;
 YImageCenter := aHeight shr 1 ;
// if FPenWidth < 1 then FPenWidth:=1;

 Result := NIL;
 SetLength( Result, Length( FPointsArray ));
 for i:=low(FPointsArray) to high(FPointsArray) do begin
  Result[i].x := FPointsArray[i].x * Factor + HMargin ;
  Result[i].y := FPointsArray[i].y * Factor + VMargin ;
 end;
end;

procedure TGeometricShapes.DrawShapeGradient( aBitmap: TBGRACustomBitmap );
begin
 if FApplyLight then begin
   aBitmap.GradientFill(0,0,aBitmap.Width,aBitmap.Height,
                      MergeBGRA(BGRAWhite,70,FFillColor,70),FFillColor,
                      gtRadial,
                      PointF(aBitmap.Width shr 2,aBitmap.Height shr 2),
                      PointF(aBitmap.Width*3/5,aBitmap.Height*3/5),
                      dmSet);
 end else begin
  aBitmap.GradientFill(0,0,aBitmap.Width,aBitmap.Height,
                     FFillColor,PercentColor(FFillColor,0.6),
                     gtRadial,
                     PointF(0,0),
                     PointF(aBitmap.Width,aBitmap.Height),
                     dmSet);
 end;

end;

procedure TGeometricShapes.DrawShape(aBitmap: TBGRACustomBitmap; aPts:ArrayOfTPointF );
var mask: TBGRABitmap;
begin
 DrawShapeGradient ( aBitmap ) ;
 // Shape drawing
 mask := TBGRABitmap.Create(aBitmap.Width,aBitmap.Height,BGRABlack);
 mask.FillPolyAntialias(aPts, BGRAWhite );
 aBitmap.ApplyMask ( mask ) ;
 mask.Free ;
 // Contour drawing
 with aBitmap do
 begin
  JoinStyle := pjsRound;
  //LineCap := pecRound;
  PenStyle := psSolid ;
  DrawPolygonAntialias( aPts, FPenColor, FPenWidth );
 end;
end;

procedure TGeometricShapes.DrawSpline(aBitmap: TBGRACustomBitmap; aPts: ArrayOfTPointF);
var mask : TBGRABitmap ;
begin
 DrawShapeGradient ( aBitmap ) ;
 // Shape drawing
 storedSpline := aBitmap.ComputeClosedSpline(aPts, ssInside);
 mask := TBGRABitmap.Create(aBitmap.Width,aBitmap.Height,BGRABlack);
 mask.FillPolyAntialias(storedSpline, BGRAWhite );
 aBitmap.ApplyMask ( mask ) ;
 mask.Free ;
 // Contour drawing
 with aBitmap do
 begin
  JoinStyle := pjsRound;
  //LineCap := pecRound;
  PenStyle := psSolid ;
  DrawPolygonAntialias( storedSpline, FPenColor, FPenWidth );
 end;
end;

procedure TGeometricShapes.DrawArrowUp(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(50,0);
 FPointsArray[1] := PointF(100,50);
 FPointsArray[2] := PointF(75,50);
 FPointsArray[3] := PointF(75,100);
 FPointsArray[4] := PointF(25,100);
 FPointsArray[5] := PointF(25,50);
 FPointsArray[6] := PointF(0,50);
 FPointsArray[7] := PointF(50,0);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawArrowDown(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(50,100);
 FPointsArray[1] := PointF(100,50);
 FPointsArray[2] := PointF(75,50);
 FPointsArray[3] := PointF(75,0);
 FPointsArray[4] := PointF(25,0);
 FPointsArray[5] := PointF(25,50);
 FPointsArray[6] := PointF(0,50);
 FPointsArray[7] := PointF(50,100);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawArrowLeft(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(0,50);
 FPointsArray[1] := PointF(50,0);
 FPointsArray[2] := PointF(50,25);
 FPointsArray[3] := PointF(100,25);
 FPointsArray[4] := PointF(100,75);
 FPointsArray[5] := PointF(50,75);
 FPointsArray[6] := PointF(50,100);
 FPointsArray[7] := PointF(0,50);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawArrowRight(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(100,50);
 FPointsArray[1] := PointF(50,0);
 FPointsArray[2] := PointF(50,25);
 FPointsArray[3] := PointF(0,25);
 FPointsArray[4] := PointF(0,75);
 FPointsArray[5] := PointF(50,75);
 FPointsArray[6] := PointF(50,100);
 FPointsArray[7] := PointF(100,50);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawSquare(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,4);
 FPointsArray[0] := PointF(0,0) ;
 FPointsArray[1] := PointF(100,0) ;
 FPointsArray[2] := PointF(100,100) ;
 FPointsArray[3] := PointF(0,100) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawTriangle(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,3);
 FPointsArray[0] := PointF(50,0) ;
 FPointsArray[1] := PointF(100,100) ;
 FPointsArray[2] := PointF(0,100) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawLozenge(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,4);
 FPointsArray[0] := PointF(50,0) ;
 FPointsArray[1] := PointF(100,50) ;
 FPointsArray[2] := PointF(50,100) ;
 FPointsArray[3] := PointF(0,50) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawPlus(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,12);
 FPointsArray[0] := PointF(33,0) ;
 FPointsArray[1] := PointF(66,0) ;
 FPointsArray[2] := PointF(66,33) ;
 FPointsArray[3] := PointF(100,33) ;
 FPointsArray[4] := PointF(100,66) ;
 FPointsArray[5] := PointF(66,66) ;
 FPointsArray[6] := PointF(66,100) ;
 FPointsArray[7] := PointF(33,100) ;
 FPointsArray[8] := PointF(33,66) ;
 FPointsArray[9] := PointF(0,66) ;
 FPointsArray[10] := PointF(0,33) ;
 FPointsArray[11] := PointF(33,33) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawMultiply(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,18);
 FPointsArray[0] := PointF(37,0) ;
 FPointsArray[1] := PointF(62,0) ;
 FPointsArray[2] := PointF(62,27) ;
 FPointsArray[3] := PointF(86,14) ;
 FPointsArray[4] := PointF(100,36) ;
 FPointsArray[5] := PointF(75,50) ;
 FPointsArray[6] := PointF(100,63) ;
 FPointsArray[7] := PointF(86,85) ;
 FPointsArray[8] := PointF(62,70) ;
 FPointsArray[9] := PointF(62,100) ;
 FPointsArray[10] := PointF(37,100) ;
 FPointsArray[11] := PointF(37,70) ;
 FPointsArray[12] := PointF(13,85) ;
 FPointsArray[13] := PointF(0,63) ;
 FPointsArray[14] := PointF(25,50) ;
 FPointsArray[15] := PointF(0,36) ;
 FPointsArray[16] := PointF(13,14) ;
 FPointsArray[17] := PointF(37,27) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawX(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,12);
 FPointsArray[0] := PointF(20,0) ;
 FPointsArray[1] := PointF(50,32) ;
 FPointsArray[2] := PointF(79,0) ;
 FPointsArray[3] := PointF(100,19) ;
 FPointsArray[4] := PointF(66,49) ;
 FPointsArray[5] := PointF(100,80) ;
 FPointsArray[6] := PointF(79,100) ;
 FPointsArray[7] := PointF(50,66) ;
 FPointsArray[8] := PointF(19,100) ;
 FPointsArray[9] := PointF(0,80) ;
 FPointsArray[10] := PointF(33,49) ;
 FPointsArray[11] := PointF(0,19) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawStar(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,10);
 FPointsArray[0] := PointF(50,0) ;
 FPointsArray[1] := PointF(64,32) ;
 FPointsArray[2] := PointF(100,37) ;
 FPointsArray[3] := PointF(74,62) ;
 FPointsArray[4] := PointF(81,100) ;
 FPointsArray[5] := PointF(50,81) ;
 FPointsArray[6] := PointF(20,100) ;
 FPointsArray[7] := PointF(26,62) ;
 FPointsArray[8] := PointF(0,37) ;
 FPointsArray[9] := PointF(34,32) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawFlash(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,11);
 FPointsArray[0] := PointF(56,2) ;
 FPointsArray[1] := PointF(78,3) ;
 FPointsArray[2] := PointF(35,34) ;
 FPointsArray[3] := PointF(98,27) ;
 FPointsArray[4] := PointF(33,80) ;
 FPointsArray[5] := PointF(52,86) ;
 FPointsArray[6] := PointF(2,97) ;
 FPointsArray[7] := PointF(18,58) ;
 FPointsArray[8] := PointF(25,74) ;
 FPointsArray[9] := PointF(67,40) ;
 FPointsArray[10] := PointF(6,47) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawHexagon(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(33,0) ;
 FPointsArray[1] := PointF(66,0) ;
 FPointsArray[2] := PointF(100,33) ;
 FPointsArray[3] := PointF(100,66) ;
 FPointsArray[4] := PointF(66,100) ;
 FPointsArray[5] := PointF(33,100) ;
 FPointsArray[6] := PointF(0,66) ;
 FPointsArray[7] := PointF(0,33) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;


procedure TGeometricShapes.DrawCircle(aBitmap: TBGRACustomBitmap);
var mask : TBGRABitmap ;
begin
 SetLength(FPointsArray,0);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 DrawShapeGradient ( aBitmap ) ;
 mask := TBGRABitmap.Create(aBitmap.Width,aBitmap.Height,BGRABlack);
 mask.FillEllipseAntialias( XImageCenter, YImageCenter, Radius, Radius,BGRAWhite);
 aBitmap.ApplyMask(mask);
 mask.Free;
 aBitmap.EllipseAntialias( XImageCenter, YImageCenter, Radius, Radius, FPenColor, FPenWidth );
end;

procedure TGeometricShapes.DrawRing(aBitmap: TBGRACustomBitmap);
begin
 DrawCircle( aBitmap );
 aBitmap.EraseEllipseAntialias(XImageCenter, YImageCenter, Radius/2, Radius/2,255);
 aBitmap.EllipseAntialias( XImageCenter, YImageCenter, Radius/2, Radius/2, FPenColor, FPenWidth );
end;



procedure TGeometricShapes.DrawEgg(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,3);
 FPointsArray[0] := PointF(50,-53) ;
 FPointsArray[1] := PointF(130,105) ;
 FPointsArray[2] := PointF(-30,105) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawSpline( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawHeart(aBitmap: TBGRACustomBitmap);
begin
 FPointsArray := aBitmap.ComputeBezierSpline(
               [BezierCurve(PointF(50,20), PointF(75,-9), PointF(100,10), PointF(100,30)),   //ok
               BezierCurve(PointF(100,30), PointF(100,55), PointF(45,75), PointF(52,100)),
               BezierCurve(PointF(48,100), PointF(55,75), PointF(0,55), PointF(0,30)),
               BezierCurve(PointF(0,30), PointF(0,10),    PointF(25,-9),    PointF(50,20))  //ok
               ]);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 DrawSpline( aBitmap, FPointsArrayScaled ) ;
end;

procedure TGeometricShapes.DrawFlower(aBitmap: TBGRACustomBitmap);
begin
 FPointsArray := aBitmap.ComputeBezierSpline(
               [BezierCurve(PointF(33,22), PointF(35,-10), PointF(65,-10), PointF(67,22)),  //ok
                BezierCurve(PointF(67,22), PointF(90,6), PointF(112,29), PointF(84,48)),    //ok
                BezierCurve(PointF(84,48), PointF(107,64), PointF(94,86), PointF(67,76)),   //ok
                BezierCurve(PointF(67,76), PointF(65,108), PointF(35,108), PointF(33,76)),  //ok
                BezierCurve(PointF(33,76), PointF(8,92), PointF(-11,68), PointF(15,48)),
                BezierCurve(PointF(15,48), PointF(-10,24), PointF(8,8), PointF(33,22))
               ]);
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 DrawSpline( aBitmap, FPointsArrayScaled ) ;
// aBitmap.FillEllipseAntialias(XImageCenter, YImageCenter, Radius/2.5, Radius/2.5,MergeBGRA(BGRA(255,255,0),10,FFillColor,50));
aBitmap.EraseEllipseAntialias(XImageCenter, YImageCenter, Radius/2.5, Radius/2.5, 255);
 aBitmap.EllipseAntialias( XImageCenter, YImageCenter, Radius/2.5, Radius/2.5, FPenColor, FPenWidth );
end;

procedure TGeometricShapes.DrawMouseCursor(aBitmap: TBGRACustomBitmap);
begin
 SetLength(FPointsArray,8);
 FPointsArray[0] := PointF(0,0) ;
 FPointsArray[1] := PointF(71,15) ;
 FPointsArray[2] := PointF(56,30) ;
 FPointsArray[3] := PointF(100,73.5) ;
 FPointsArray[4] := PointF(74.7,100) ;
 FPointsArray[5] := PointF(30.5,55.3) ;
 FPointsArray[6] := PointF(13.8,71.7) ;
 FPointsArray[7] := PointF(0,0) ;
 FPointsArrayScaled := ScalePoints(aBitmap.Width,aBitmap.Height) ;
 FPenWidth*=2 ;
 DrawShape( aBitmap, FPointsArrayScaled ) ;
end;

end.

