unit EasyDB.Logger;

interface

uses
  System.SysUtils, System.TypInfo, System.StrUtils,
  EasyDB.Core;

type
  TLogger = class;

  TLoggerEventHandler = procedure(AActionType: TActionTypes; AMessage, AEntityName: string; AVersion: Int64) of object;

  TLogger = class(TObject)
  private
    FOnLog: TLoggerEventHandler;
    class var FLocalLog: Boolean;
    class var FLocalFilePath: string;
    class var FInstance: TLogger;
  public
    destructor Destroy; override;
    procedure Log(AActionType: TActionTypes; AMessage: string; AEntityName: string = ''; AVersion: Int64 = 0);
    procedure DoCallBack(AActionType: TActionTypes; AMessage: string; AEntityName: string = ''; AVersion: Int64 = 0);
    class function Instance: TLogger;
    class function ConfigLocal(ALocalLog: Boolean; ALocalFilePath: string): TLogger;

    property OnLog: TLoggerEventHandler read FOnLog write FOnLog;
  end;

implementation

{ TLogger }

class function TLogger.ConfigLocal(ALocalLog: Boolean; ALocalFilePath: string): TLogger;
begin
  FLocalFilePath := ALocalFilePath;
  FLocalLog := ALocalLog;
  Result := FInstance;
end;

destructor TLogger.Destroy;
begin
  FInstance := nil;
  inherited;
end;

procedure TLogger.DoCallBack(AActionType: TActionTypes; AMessage, AEntityName: string; AVersion: Int64);
begin
  try
    if Assigned(FOnLog) then
      OnLog(AActionType, AMessage, AEntityName, AVersion);
  except on E: Exception do
    Log(atCallBackEvent, E.Message, AEntityName, AVersion);
  end;
end;

class function TLogger.Instance: TLogger;
begin
  if not Assigned(FInstance) then
    FInstance := TLogger.Create;

  Result := FInstance;
end;

procedure TLogger.Log(AActionType: TActionTypes; AMessage, AEntityName: string; AVersion: Int64);
var
  LvLogFile: TextFile;
begin
  DoCallBack(AActionType, AMessage, AEntityName, AVersion);

  if (not FLocalLog) or (FLocalFilePath.IsEmpty) then
    Exit;

  AssignFile(LvLogFile, FLocalFilePath);

  if FileExists(FLocalFilePath) then
    Append(LvLogFile)
  else
    Rewrite(LvLogFile);

  try
    Writeln(LvLogFile, '========== ' + DateTimeToStr(Now) + ' ==========');
    Writeln(LvLogFile, 'Action Type: ' + GetEnumName(TypeInfo(TActionTypes), Ord(AActionType)));
    Writeln(LvLogFile, 'Exception: ' + AMessage);
    Writeln(LvLogFile, 'Class Name: ' + IfThen(AEntityName.IsEmpty, 'N/A', AEntityName));
    Writeln(LvLogFile, 'Version: ' + IfThen(AVersion = 0, 'N/A', IntToStr(AVersion)));
    Writeln(LvLogFile, '');
  finally
    CloseFile(LvLogFile);
  end;
end;

end.
