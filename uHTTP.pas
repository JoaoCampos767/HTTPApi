unit uHTTP;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IniFiles,

  System.JSON, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack,
  IdSSL, IdBaseComponent, IdComponent, IdTCPConnection, IdSSLOpenSSL,
  IdSSLOpenSSLHeaders, IdTCPClient, System.DateUtils, IdHTTP,
  IdCoderMIME;

type
  TForm1 = class(TForm)
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    vsURL         ,
    vsMETHOD      ,
    vsCONTENT     ,
    vsACCEPT      ,
    vsCERT        ,
    vsKEY         ,
    vsCLIENTID    ,
    vsCLIENTSECRET,
    vsSCOPE       ,
    vsJSONENVIO   ,
    vsTOKEN       : String;

    vsRETORNO     : String;

    procedure LendoINI();
    function PostApi(vsURL         ,
                     vsMETHOD      ,
                     vsCONTENT     ,
                     vsACCEPT      ,
                     vsCERT        ,
                     vsKEY         ,
                     vsCLIENTID    ,
                     vsCLIENTSECRET,
                     vsSCOPE       : String;
                     vsJSONENVIO   : String = '';
                     vsTOKEN       : String = ''): Boolean;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  IdSSLOpenSSLHeaders.IdOpenSSLSetLibPath('D:\Joao\Projetos\HTTPApi\bin');
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  LendoINI;
end;

procedure TForm1.LendoINI;
var
  arquivoINI    : TIniFile;
  nI            : Integer;
begin
  if not FileExists('C:\Ini\HTTPParam.ini') then
    ShowMessage('Nao existe esse arquivo');

  arquivoINI := TIniFile.Create('C:\Ini\HTTPParam.ini');
  try
    vsURL          := arquivoINI.ReadString('config', 'Url'        , vsURL);
    vsMETHOD       := arquivoINI.ReadString('config', 'Method'     , vsMETHOD);
    vsCONTENT      := arquivoINI.ReadString('config', 'ContentType', vsCONTENT);
    vsACCEPT       := arquivoINI.ReadString('config', 'Accept'     , vsACCEPT);

    vsCERT         := arquivoINI.ReadString('param', 'Cert'        , vsCERT);
    vsKEY          := arquivoINI.ReadString('param', 'Key'         , vsKEY);
    vsCLIENTID     := arquivoINI.ReadString('param', 'ClientID'    , vsCLIENTID);
    vsCLIENTSECRET := arquivoINI.ReadString('param', 'ClientSecret', vsCLIENTSECRET);
    vsJSONENVIO    := arquivoINI.ReadString('param', 'json'        , vsJSONENVIO);
    vsTOKEN        := arquivoINI.ReadString('param', 'Token'       , vsTOKEN);

    vsSCOPE        := 'extrato.read boleto-cobranca.read boleto-cobranca.write';

    if not PostApi(vsURL,
                   vsMETHOD      ,
                   vsCONTENT     ,
                   vsACCEPT      ,
                   vsCERT        ,
                   vsKEY         ,
                   vsCLIENTID    ,
                   vsCLIENTSECRET,
                   vsSCOPE       ,
                   vsJSONENVIO   ,
                   vsTOKEN       ) then
      Exit;
  finally

  end;
end;

function TForm1.PostApi(vsURL         ,
                        vsMETHOD      ,
                        vsCONTENT     ,
                        vsACCEPT      ,
                        vsCERT        ,
                        vsKEY         ,
                        vsCLIENTID    ,
                        vsCLIENTSECRET,
                        vsSCOPE       : String;
                        vsJSONENVIO   : String = '';
                        vsTOKEN       : String = ''): Boolean;
var
  Params         : TStringList;
  JsonStreamEnvio,
  Resp           : TStringStream;
  Jso            : TJSONObject;
  JsoPair        : TJSONPair;
  HTTP           : TIdHTTP;
  IOHandle       : TIdSSLIOHandlerSocketOpenSSL;
begin
  try
    Params := TStringList.Create;
    Resp := TStringStream.Create;

    HTTP                                 := TIdHTTP.Create(nil);
    HTTP.Request.BasicAuthentication     := False;
    HTTP.Request.UserAgent               := 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0';
    IOHandle                             := TIdSSLIOHandlerSocketOpenSSL.Create(HTTP);
    IOHandle.SSLOptions.Method           := sslvTLSv1_2;
    IOHandle.SSLOptions.Mode             := sslmClient;
    IOHandle.SSLOptions.CertFile         := vsCERT;
    IOHandle.SSLOptions.KeyFile          := vsKEY;
    HTTP.IOHandler                       := IOHandle;
    HTTP.Request.ContentType             := vsCONTENT;
    HTTP.Request.Accept                  := vsACCEPT;
    HTTP.Request.CharSet                 := 'UTF-8';
    HTTP.Request.CustomHeaders.FoldLines := False;
    HTTP.Request.CustomHeaders.Add('Authorization: Bearer ' + vsTOKEN);

    if (vsCLIENTID <> '') and (vsCLIENTSECRET <> '') then
    begin
      Params.Add('client_id=' + vsCLIENTID);
      Params.Add('client_secret=' + vsCLIENTSECRET);
      Params.Add('scope=' + vsSCOPE);
      Params.Add('grant_type=client_credentials');
    end;

    if vsJSONENVIO <> '' then
    begin
      Params.Add(vsJSONENVIO);
      JsonStreamEnvio := TStringStream.Create(Params.Text);
    end;

    try
      if vsJSONENVIO <> '' then
        HTTP.Post(vsURL, JsonStreamEnvio, Resp)
      else
        HTTP.Post(vsURL, Params, Resp);

      if HTTP.ResponseCode = 200 then
      begin
        if FileExists('D:\Joao\Projetos\JSON_RETORNO\LogRetornoHTTP.txt') then
          DeleteFile('D:\Joao\Projetos\JSON_RETORNO\LogRetornoHTTP.txt');

        Resp.SaveToFile('D:\Joao\Projetos\JSON_RETORNO\LogRetornoHTTP.txt');

        Result := true;
      end
      else
      begin
        Resp.WriteString('Error: ' + HTTP.ResponseText);
        Resp.SaveToFile('D:\Joao\Projetos\JSON_RETORNO\LogRetornoHTTP.txt');
      end;
    except
      on e: EIdHTTPProtocolException do
      begin
        Resp.WriteString('Error: ' + HTTP.ResponseText + ' - ' + e.ErrorMessage);
        Resp.SaveToFile('D:\Joao\Projetos\JSON_RETORNO\LogRetornoHTTP.txt');
      end;
    end;
  finally
    FreeAndNil(Params);
    FreeAndNil(Resp);
  end;
end;


end.
