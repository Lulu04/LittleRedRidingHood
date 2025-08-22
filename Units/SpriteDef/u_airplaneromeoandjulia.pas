unit u_airplaneromeoandjulia;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  OGLCScene, u_common, u_app, u_audio, BGRABitmap, BGRABitmapTypes;

type

{ TAirplaneRomeoAndJulia }

TAirplaneRomeoAndJulia = class(TSprite)
private
  class var texAirplaneRomeoJulia, texAirplanePropeller, texAirplaneRope, texAirplaneBanner: PTexture;
private
  AirplanePropeller: TSprite;
  Rope: TSprite;
  Banner: TDeformationgrid;
  FsndEngine: TALSSound;
public
  AnimDone: boolean;
  class procedure LoadTexture(aAtlas: TOGLCTextureAtlas);
  constructor Create(aLayerIndex: integer=-1);
  procedure ProcessMessage(UserValue: TUserMessageValue); override;
  procedure StartAnimCrossTheScreen;
end;

implementation

{ TAirplaneRomeoAndJulia }

class procedure TAirplaneRomeoAndJulia.LoadTexture(aAtlas: TOGLCTextureAtlas);
var path: string;
begin
  path := FolderSpriteWolfCastle;
  texAirplaneRomeoJulia := aAtlas.AddFromSVG(path+'AirplaneRomeoJulia.svg', ScaleW(355), -1);
  texAirplanePropeller := aAtlas.AddFromSVG(path+'AirplanePropeller.svg', -1, ScaleH(80));
  texAirplaneRope := aAtlas.AddFromSVG(path+'AirplaneRope.svg', ScaleW(82), -1);
  texAirplaneBanner := aAtlas.AddFromSVG(path+'AirplaneBanner.svg', ScaleW(393), -1);
end;

constructor TAirplaneRomeoAndJulia.Create(aLayerIndex: integer);
begin
  inherited Create(texAirplaneRomeoJulia, False);
  if aLayerIndex <> -1 then
    FScene.Add(Self, aLayerIndex);

  AirplanePropeller := TSprite.Create(texAirplanePropeller, False);
  with AirplanePropeller do begin
    SetChildOf(Self, 0);
    SetCoordinate(0.905*Self.Width, 0.302*Self.Height);
  end;

  Rope := TSprite.Create(texAirplaneRope, False);
  with Rope do begin
    SetChildOf(Self, -1);
    SetCoordinate(-0.140*Self.Width, 0.248*Self.Height);
  end;

  Banner := TDeformationgrid.Create(texAirplaneBanner, False);
  with Banner do begin
    SetChildOf(Rope, -1);
    SetCoordinate(-4.687*Rope.Width, -0.343*Rope.Height);
    SetGrid(2, 6);
    ApplyDeformation(dtWaveV);
    SetDeformationAmountOnColumn(6, 0);
    DeformationSpeed.Value := PointF(1.5,1.5);
  end;

  FsndEngine := Audio.AddSound('engine-47745.ogg', 0.0, True);

  PostMessage(0); // propeller anim
end;

procedure TAirplaneRomeoAndJulia.ProcessMessage(UserValue: TUserMessageValue);
begin
  case UserValue of
    // propeller animation
    0: begin
      AirplanePropeller.FlipH := False;
      AirplanePropeller.FlipV := False;
      PostMessage(5);
    end;
    5: begin
      AirplanePropeller.FlipH := False;
      AirplanePropeller.FlipV := True;
      PostMessage(10);
    end;
    10: begin
      AirplanePropeller.FlipH := True;
      AirplanePropeller.FlipV := True;
      PostMessage(15);
    end;
    15: begin
      AirplanePropeller.FlipH := True;
      AirplanePropeller.FlipV := False;
      PostMessage(0);
    end;

    // anim cross the screen
    100: begin
      Visible := True;
      FsndEngine.FadeIn(0.8, 3.0);
      FsndEngine.Pan.Value := -1.0;
      FsndEngine.Pan.ChangeTo(0.0, 3.0);
      SetCoordinate(-Width*2, ScaleH(156));
      X.ChangeTo(FScene.Width+Rope.Width+Banner.Width, 10.0);
      PostMessage(150); // vertical anim
      PostMessage(105, 5.0);
    end;
    105: begin
      FsndEngine.Pan.ChangeTo(1.0, 5.0);
      FsndEngine.FadeOutThenKill(6.0);
      FsndEngine := NIL;
      PostMessage(110, 5.0);
    end;
    110: AnimDone := True;

    150: begin
      MoveYRelative(ScaleH(15), 0.5, idcSinusoid);
      PostMessage(155, 0.5);
    end;
    155: begin
      MoveYRelative(-ScaleH(15), 0.5, idcSinusoid);
      PostMessage(150, 0.5);
    end;

  end;//case
end;

procedure TAirplaneRomeoAndJulia.StartAnimCrossTheScreen;
begin
  AnimDone := False;
  Visible := False;
  PostMessage(100);
end;

end.
