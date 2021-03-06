//+------------------------------------------------------------------+
//|                                                        Edite.mq5 |
//|                                 Copyright 2021, Arismário Neves. |
//|                                           arismarioneves@hotmail |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Arismário Neves."
#property link      "http://arismario.tk"

#property description "Edite é um robô customizado para day trade.\n"
#property description "@arismarioneves – arismarioneves@hotmail.com"

#define EA "Edite"
#define VERSION "1.0"

#define MQL5STORE false

#property version VERSION

//Arismário Neves
//Versão 1.0

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
//--- Painel
#include "Painel.mqh"
//--- Fontes
#include "Fonts.mqh"
//--- TraderPad
#include "TraderPad.mqh"

#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\Trade.mqh>

#include <Controls\Button.mqh>

//--- Keys IDs
#define KEY_I 73

//#resource "\\Experts\\"+EA+"\\System.ex5"
//+------------------------------------------------------------------+
//--- enums
enum ENUM_TIMEFRAMES_INDEX {
   CURRENT  = PERIOD_CURRENT, // Período atual [Current]
   M1    = PERIOD_M1,         // 1 minutos
   M5    = PERIOD_M5,         // 5 minutos
   M15   = PERIOD_M15,        // 15 minutos
   M30   = PERIOD_M30,        // 30 minutos
   H1    = PERIOD_H1,         // 1 hora
   H4    = PERIOD_H4,         // 4 horas
   D1    = PERIOD_D1,         // Diariamente [Daily]
   W1    = PERIOD_W1,         // Semanal [Weekly]
   MN1   = PERIOD_MN1         // Mensal [Monthly]
};
enum NUMBER_LIST {
   ZERO  = 0, // Não
   ONE   = 1, // 1
   TWO   = 2, // 2
   TREE  = 3, // 3
   FOUR  = 4, // 4
   FIVE  = 5  // 5
};
enum CHOOSE {
   SIM   = 1, // Sim
   NAO   = 0  // Não
};
enum ENUM_BAR {
   ATUAL = 0, // Atual
   NOVO  = 1  // Próximo
};
enum ENUM_OBJ_CORNER {
   CORNER_CHART_RIGHT_UPPER   = CORNER_RIGHT_UPPER,   // Canto superior direito do gráfico
   CORNER_CHART_LEFT_LOWER    = CORNER_LEFT_LOWER     // Canto inferior esquerdo do gráfico
};
enum ENUM_BUTTON_CORNER {
   CORNER_BUTTON_LEFT_UPPER   = CORNER_LEFT_UPPER,    // Canto superior esquerdo do gráfico
   CORNER_BUTTON_RIGHT_UPPER  = CORNER_RIGHT_UPPER,   // Canto superior direito do gráfico
   CORNER_BUTTON_LEFT_LOWER   = CORNER_LEFT_LOWER,    // Canto inferior esquerdo do gráfico
   CORNER_BUTTON_RIGHT_LOWER  = CORNER_RIGHT_LOWER    // Canto inferior direito do gráfico
};
enum ENUM_WEEK_BEGIN {
   BEGINNING_ON_MONDAY, // Segunda
   BEGINNING_ON_SUNDAY  // Domingo
};
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
sinput   string   ExpertTitle          = EA;       // Robô
sinput   string   AcessCode            = "";       // Código de acesso

//--- inputs parameters
input group "CONTRATOS";
input    double   InpLots              = 1;        // Quantidade de contratos

input group "GANHO E PERDA";
input    ushort   InpTakeProfit        = 60;       // Ganho máximo [Take Profit]
input    ushort   InpStopLoss          = 90;       // Perda máxima [Stop Loss]

input group "REVERSÃO";
input    CHOOSE   TradeReverse         = NAO;      // Usar Reversão em caso de perda
input    double   InpLotsReverse       = 2;        // Contratos na Reversão

input group "TRADER PAD";
input    double   PadLots              = 1;        // Contratos
input    ushort   PadTakeProfit        = 50;       // Ganho [Gain]
input    ushort   PadStopLoss          = 50;       // Perda [Loss]

input group "LÓGICA";
input    ENUM_TIMEFRAMES_INDEX InpTimeFrame = M5;  // Tempo gráfico [Time frame]

input    int      InpShortMA_Period    = 10;       // MA I: Período curto
input    ENUM_MA_METHOD       InpShortMA_Method    = MODE_EMA;    // MA I: Método
input    int      InpFirst_MA_Shift    = 0;        // MA I: Deslocar
input    ENUM_APPLIED_PRICE   InpShortMA_Applied   = PRICE_CLOSE; // MA I: Aplicar

input    int      InpLongMA_Period     = 50;       // MA II: Período longo
input    ENUM_MA_METHOD       InpLongMA_Method     = MODE_SMA;    // MA II: Método
input    int      InpSecond_MA_Shift   = 0;        // MA II: Deslocar
input    ENUM_APPLIED_PRICE   InpLongMA_Applied    = PRICE_CLOSE; // MA II: Aplicar

input    ushort   InpMinCrossDistance  = 50;       // Distância mínima após cruzamento

input group "PARCIAL";
input    CHOOSE   HabilitaParcial      = SIM;      // Usar Parcial nas operações
input    double   PontosParcial        = 30;       // Pontos para ativar a Parcial
input    int      PorcentParcial       = 50;       // Porcentagem contratos na Parcial
input    CHOOSE   MoveStop             = SIM;      // Mover Stop Loss ao usar a Parcial
input    double   PontosMoveStop       = 30;       // Perda máxima do novo Stop Loss

input group "STOP MÓVEL";
input    ushort   InpTrailingStop      = 0;        // Stop Móvel [Trailing Stop]
input    ushort   InpTrailingStep      = 0;        // Trailing Step

input group "PERSONALIZAR";
input    double   MetaGain             = 0;        // Meta de ganhos no dia R$
input    double   MetaLoss             = 0;        // Máximo de perdas no dia R$
input    NUMBER_LIST MaxLoss           = ZERO;     // Máximo de perdas seguidas

input    double   CustoTrade           = 0.51;     // Custo médio contrato operado (0.00)

input    CHOOSE   OneTrade             = NAO;      // Operar apenas uma vez ao dia
input    CHOOSE   TradeAlways          = SIM;      // Operar com outras ordens abertas
input    CHOOSE   CloseOpposite        = SIM;      // Fechar ordem em caso de ordem oposta
input    CHOOSE   ClosePositions       = NAO;      // Fechar ordens ainda abertas (17h30)
input    CHOOSE   CheckMoney           = NAO;      // Verificar saldo antes da operação

input    CHOOSE   NewBar               = SIM;      // Operar apenas no início do candle
input    ENUM_BAR InpCurrentBar        = NOVO;     // Candle da operação

input    CHOOSE   Push                 = NAO;      // Ativar notificação Android ou iPhone
input    CHOOSE   Alerts               = NAO;      // Exibir alertas
input    CHOOSE   Prints               = SIM;      // Exibir mensagens/avisos

input    ulong    InpSlippage          = 10;       // Derrapagem [Slippage]
input    ulong    InpDevPts            = 10;       // Desvio permitido do preço

input    ulong    MagicNumber          = 587590;   // Número mágico [1-100000]

input group "HORÁRIO DE FUNCIONAMENTO";
input    CHOOSE   HourTrade            = SIM;      // Ativar horário de funcionamento
input    uchar    InpStartHour         = 9;        // Início operações [horas]
input    uchar    InpStartMinute       = 0;        // Início operações [minutos]
input    uchar    InpEndHour           = 16;       // Término operações [horas]
input    uchar    InpEndMinute         = 30;       // Término operações [minutos]

//--- input parameters button
ENUM_BUTTON_CORNER   ButtonPosition    = CORNER_BUTTON_RIGHT_LOWER;  // Posição do botão ON/OFF

//--- input parameters painel
ENUM_WEEK_BEGIN   InpWeekBegin         = BEGINNING_ON_SUNDAY;  // Dia de início da semana
uint              InpOffsetX           = 10;                   // Deslocamento horizontal do painel
uint              InpOffsetY           = 25;                   // Deslocamento vertical do painel

input group "CONFIGURAR EXIBIÇÃO";
input    ENUM_OBJ_CORNER   InpCorner               = CORNER_CHART_RIGHT_UPPER;      // Posição do painel
input    uchar             InpPanelTransparency    = 200;                           // Transparência do painel (48-255)
input    TYPE_FONTE        FontType                = Font5;                         // Fonte
input    color             InpPanelColorBG         = clrAliceBlue;                  // Cor do painel
input    color             InpPanelColorBD         = clrSilver;                     // Cor da borda do painel
input    color             InpPanelColorTX         = clrBlack;                      // Cor do texto no painel
input    color             InpPanelColorLoss       = clrRed;                        // Cor do texto da perda
input    color             InpPanelColorProfit     = clrGreen;                      // Cor do texto do lucro

//--- input parameters label
input    color             ColorTimeCandle         = clrOrangeRed;                  // Cor do tempo do candle
//+------------------------------------------------------------------+
double   ExtTakeProfit        = 0.0;
double   ExtStopLoss          = 0.0;
double   ExtMinCrossDistance  = 0.0;
double   ExtTrailingStop   = 0.0;
double   ExtTrailingStep   = 0.0;
double   Parcial           = 0.0;
double   BreakEven         = PontosParcial;

int      Crossed           = 0;
int      TradeDay          = 0;
int      ContLoss          = 0;
int      OneTimePost       = 0;
int      MarketOpenMin     = 0;
int      StopReverse       = 1;
int      MaxReverse        = 0;
int      Assinatura        = 1;
int      ParcialGo         = 0;
int      FontSize          = 10; //Tempo do Candle e Botão

bool     HasCrossed        = false;
bool     HasReverse        = false;
bool     StopTrade         = false;
bool     ReverseParcial    = false;
bool     TurnON            = true;

string   FontName;
string   TradeMode;
string   TextTimeCandle    = "[ i ] | Próximo Candle ";

datetime NewDay;
datetime TradeOneTimeDay;

MqlTick  LastTick;

ENUM_TIMEFRAMES TimeFrame;

//--- handle
int      handle_iMA_short; //variable for storing the handle of the iMA indicator
int      handle_iMA_long; //variable for storing the handle of the iMA indicator

//--- enviar dados da plataforma para o servidor
string   URL = "https://3mtrader.com.br/";
string   cookie = NULL, headers;
char     post[], resultado[];
int      connection;

//--- extra parameters
string   DialogName  = EA + " " + VERSION;   //Nome do painel
string   ButtonName  = "Liga/Desliga";       //Nome do botão ON/OFF
string   LabelName   = "Tempo do Candle";    //Nome do label
//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CPositionInfo  m_position;             //trade position object
CTrade         m_trade;                //trading object
CSymbolInfo    m_symbol;               //symbol info object
COrderInfo     m_order;                //pending orders object

CAccountInfo   account_info;           //objeto CAccountInfo
CBotPanel      panel;                  //create panel object
CChartObjectButton button;             //create button object
CFontName      FONT;                   //create font object
TraderPad      BOT;                    //create robotcore object
//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit() {
//MessageBox("Olá, eu sou " + EA + "!", MQLInfoString(MQL_PROGRAM_NAME), MB_OK);
//--- conect robot
   if(!MQL5STORE) {
      if(!MQLInfoInteger(MQL_TESTER)) {
         //--- para trabalhar com o servidor é necessário adicionar a URL
         //--- na lista de URLs permitidas (menu Principal->Ferramentas->Opções, guia "Experts")
         ResetLastError(); //redefinimos o código do último erro
         //--- download da página html
         connection = WebRequest("GET", URL + EA + "/code/" + AcessCode + ".txt", cookie, NULL, 500, post, 0, resultado, headers);
         if(connection == -1) {
            Print("Erro ao conectar no servidor. Erro: ", GetLastError());
            //--- é possível que a URL não esteja na lista, exibimos uma mensagem sobre a necessidade de adicioná-la
            MessageBox("É necessário adicionar o endereço '" + URL + "' à lista de URLs permitidas (Ferramentas->Opções, guia 'Expert Advisors').", EA, MB_ICONINFORMATION);
            return(INIT_FAILED);
         } else {
            if(connection == 200) {
               //--- download bem-sucedido
               PrintFormat("Ativado com sucesso! (%d bytes).", ArraySize(resultado));
               Assinatura = 1;
            } else {
               Print("Falha na ativação!");
               Assinatura = 0;
            }
         }
      }
   }
//---
   FontName = FONT.GetFontName(FontType);
//--- Conta demo, de torneio ou real
   ENUM_ACCOUNT_TRADE_MODE account_type = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
//--- Agora transforma o valor da enumeração em uma forma inteligível
   switch(account_type) {
   case ACCOUNT_TRADE_MODE_DEMO:
      TradeMode = "Conta DEMO";
      break;
   case ACCOUNT_TRADE_MODE_CONTEST:
      TradeMode = "Conta CONCURSO";
      break;
   default:
      TradeMode = "Conta REAL";
      break;
   }
//--- enviar dados da plataforma para o servidor
   WebRequest("POST", URL + EA + "/botapi.php" +
              "?nome=" + AccountInfoString(ACCOUNT_NAME) +
              "&codigo=" + AcessCode +
              "&versao=" + VERSION +
              "&ativo=" + Symbol() +
              "&conta=" + TradeMode +
              "&corretora=" + AccountInfoString(ACCOUNT_COMPANY),
              NULL, 0, post, resultado, headers);
//--- setting the timer to 100 milliseconds
   EventSetMillisecondTimer(100);
//--- setting global variables
   transparency_p    = (InpPanelTransparency < 48 ? 48 : InpPanelTransparency);
   prev_begin_day    = 0;
   prev_begin_week   = 0;
   prev_begin_month  = 0;
   prev_begin_year   = 0;
//---
   prev_chart_w      = 0;
   prev_chart_h      = 0;
//---
   ResetDatas();
   SetCoords();
//--- create application panel
   if(!CreatePanel()) {
      Print("Falha ao criar o painel! Erro: ", GetLastError());
      return(INIT_FAILED);
   }
//--- create application button
   if(!ButtonCreate(button, ButtonName, 10, 25, 100, 30, ButtonPosition)) {
      Print("Falha ao criar o botão [ON/OFF]. Erro: ", GetLastError());
      return(INIT_FAILED);
   }
//--- run button text to ON
   button.SetString(OBJPROP_TEXT, EA + " ON");
//--- create application label
   ObjectCreate(0, LabelName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, LabelName, OBJPROP_ANCHOR, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, LabelName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
   ObjectSetInteger(0, LabelName, OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, LabelName, OBJPROP_YDISTANCE, 15);
   ObjectSetInteger(0, LabelName, OBJPROP_FONTSIZE, FontSize);
   ObjectSetInteger(0, LabelName, OBJPROP_COLOR, ColorTimeCandle);
   ObjectSetString(0, LabelName, OBJPROP_TEXT, TextTimeCandle);
   ObjectSetString(0, LabelName, OBJPROP_FONT, FontName);
//---
   /*
   if(ChartPeriod(0) != PERIOD_M1) {
      Print(EA + " deve operar somente no tempo gráfico M1!");
      ChartSetSymbolPeriod(0, _Symbol, PERIOD_M1);
      return(INIT_SUCCEEDED);
   }*/
//---
   if (HourTrade) {
      if(InpStartHour < 9 || InpStartHour > 17) {
         MessageBox("O horário de início das operações não pode ser antes das 9h ou após as 17h.", EA, MB_ICONEXCLAMATION);
         return(INIT_PARAMETERS_INCORRECT);
      }
      if(InpEndHour < 10 || InpEndHour > 18) {
         MessageBox("O horário de término das operações não pode ser antes das 10h ou após as 18h.", EA, MB_ICONEXCLAMATION);
         return(INIT_PARAMETERS_INCORRECT);
      }
      if(InpStartHour >= InpEndHour) {
         MessageBox("O horário de início das operações não pode ser igual ou maior do que o horário do término das operações.", EA, MB_ICONEXCLAMATION);
         return(INIT_PARAMETERS_INCORRECT);
      }
   }
//---
   if(InpShortMA_Period >= InpLongMA_Period) {
      MessageBox("\"MA short: averaging period\" não pode ser igual ou maior do que \"MA long: averaging period\".");
      return(INIT_PARAMETERS_INCORRECT);
   }
//---
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      Print("Verifique se a Negociação Automatizada é permitida nas configurações da plataforma!");
//---
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      Print("A Negociação Automatizada é proibida nas configurações do robô " + EA);
//---
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      Print("Negociação automatizada é proibida para a conta ", AccountInfoInteger(ACCOUNT_LOGIN), " no lado do servidor de negociação.");
//---
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      Print("A negociação está proibida para a conta ", AccountInfoInteger(ACCOUNT_LOGIN), ". Verifique a aba Diário na plataforma.");
//---
   Comment("\n", EA, "\n________________________",
           "\nContratos: ", InpLots,
           "\nGanho máximo: ", InpTakeProfit, " pontos", "\nPerda máxima: ", InpStopLoss, " pontos",
           "\nOperar uma vez: ", (OneTrade == 1 ? "SIM" : "NÃO"),
           "\nUsar Reversão: ", (TradeReverse == 1 ? "SIM" : "NÃO"),
           "\nUsar Parcial: ", (HabilitaParcial == 1 ? "SIM" : "NÃO"),
           "\nMeta de ganho: ", (MetaGain == 0 ? " - " : DoubleToString(MetaGain, 2)), " R$");
//---
   if(!m_symbol.Name(Symbol()))
      return(INIT_FAILED);
   RefreshRates();
//---
   string err_text = "";
   if(!CheckVolumeValue(InpLots, err_text)) {
      Print("Erro ", err_text);
      return(INIT_PARAMETERS_INCORRECT);
   }
//--- magic
   m_trade.SetExpertMagicNumber(MagicNumber);
//--- deviation
   m_trade.SetDeviationInPoints(InpDevPts);
//--- tipo de execução da ordem
   if(IsFillingTypeAllowed(m_symbol.Name(), SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(m_symbol.Name(), SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//--- tipo de expiração da ordem
//ORDER_TIME_DAY - Ordem válida até o final do dia corrente de negociação
//--- slippage
   m_trade.SetDeviationInPoints(InpSlippage);
//--- tuning for 3 or 5 digits
   double adjusted_point;
   int digits_adjust = 1;
   if(m_symbol.Digits() == 3 || m_symbol.Digits() == 5)
      digits_adjust = 10;
   adjusted_point          = m_symbol.Point()      * digits_adjust;
   ExtTakeProfit           = InpTakeProfit         * adjusted_point;
   ExtStopLoss             = InpStopLoss           * adjusted_point;
   ExtMinCrossDistance     = InpMinCrossDistance   * adjusted_point;
   ExtTrailingStop         = InpTrailingStop       * adjusted_point;
   ExtTrailingStep         = InpTrailingStep       * adjusted_point;
//---
   TesterHideIndicators(true);
//---
   if(InpTimeFrame == 0)
      TimeFrame = PERIOD_CURRENT;
   else if(InpTimeFrame == 1)
      TimeFrame = PERIOD_M1;
   else if(InpTimeFrame == 5)
      TimeFrame = PERIOD_M5;
   else if(InpTimeFrame == 15)
      TimeFrame = PERIOD_M15;
   else if(InpTimeFrame == 30)
      TimeFrame = PERIOD_M30;
   else if(InpTimeFrame == 60)
      TimeFrame = PERIOD_H1;
   else if(InpTimeFrame == 240)
      TimeFrame = PERIOD_H4;
   else if(InpTimeFrame == 1440)
      TimeFrame = PERIOD_D1;
   else if(InpTimeFrame == 10080)
      TimeFrame = PERIOD_W1;
   else if(InpTimeFrame == 43200)
      TimeFrame = PERIOD_MN1;
//--- create handle of the indicator iMA
   handle_iMA_short = iMA(m_symbol.Name(), TimeFrame, InpShortMA_Period, InpFirst_MA_Shift, InpShortMA_Method, InpShortMA_Applied);
//--- create handle of the indicator iMA
   handle_iMA_long = iMA(m_symbol.Name(), TimeFrame, InpLongMA_Period, InpSecond_MA_Shift, InpLongMA_Method, InpLongMA_Applied);
//--- Trader Pad
//Definições Básicas
   BOT.SetSymbol(_Symbol);
   BOT.SetVolume(PadLots); //Volume
   BOT.SetSpread(0); //Spread para entrada na operação em ticks
   BOT.SetLastPriceType(0); //Tipo de referência do ultimo preço
//Alvos
   ushort StopGainEmTicks;
   ushort StopLossEmTicks;
//if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_EXCH_FUTURES); //BMF
   if(StringFind(_Symbol, "WIN") == 0) { //WIN - Um tick é 5 pontos.
      StopGainEmTicks = PadTakeProfit / 5;
      StopLossEmTicks = PadStopLoss / 5;
   } else if(StringFind(_Symbol, "WDO") == 0) { //WDO - Um tick é meio ponto.
      StopGainEmTicks = PadTakeProfit * 2;
      StopLossEmTicks = PadStopLoss * 2;
      //} else if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_EXCH_STOCKS) { //BOVESPA
   } else { //Ações - Um tick é 1 centavo.
      StopGainEmTicks = PadTakeProfit;
      StopLossEmTicks = PadStopLoss;
   }
   BOT.SetStopGain(StopGainEmTicks); //Stop Gain em ticks
   BOT.SetStopLoss(StopLossEmTicks); //Stop Loss em ticks
//Expert Control
   BOT.SetNumberMagic(MagicNumber);
   BOT.SetRobotName(EA);
   BOT.SetRobotVersion(VERSION);
//Load Expert
   BOT.OnInit();
//--- succeed
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- Deleta Tempo Candle
   ObjectDelete(0, LabelName);
//--- Deleta Botão
   ObjectDelete(0, ButtonName);
//--- Deleta Painel
   DeletePanel();
   EventKillTimer();
//--- Deleta Info dos Parâmetros
   Comment("");
//--- Deleta Trader Pad
   BOT.Destroy(reason);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//--- Time
   datetime Time = iTimes(0);
//--- Time Candle
   int Minutos = int(Time + PeriodSeconds() - TimeCurrent());
   int Segundos = Minutos % 60;
   Minutos = (Minutos - Segundos) / 60;
   string MinutosZero = "", SegundosZero = "";
   if (Minutos < 10) MinutosZero = "0";
   if (Segundos < 10) SegundosZero = "0";
   ObjectSetString(0, LabelName, OBJPROP_TEXT, TextTimeCandle + MinutosZero + IntegerToString(Minutos) + ":" + SegundosZero + IntegerToString(Segundos));
//--- Trader Pad
   BOT.OnTick();
//--- Desliga o robô se o botão estive OFF
   if(!TurnON)
      return;
//--- Horário
   MqlDateTime FTimeCurrent;
//--- a última hora conhecida do servidor
   TimeToStruct(TimeCurrent(), FTimeCurrent);
//--- hora estimada atual do servidor de negociação
//TimeToStruct(TimeTradeServer(),FTimeCurrent);
//--- hora estimada atual do servidor de negociação
   long STimeCurrent = FTimeCurrent.hour * 60 * 60 + FTimeCurrent.min * 60;
//--- Market Status
   static int OneTimeOpen = 10;
   if(OneTimeOpen == 10)
      if(!MarketStatus())
         OneTimeOpen = 0;
      else
         OneTimeOpen = 1;
//--- MarketStatus
   if(!MarketStatus() && OneTimeOpen == 0) {
      if(Prints)
         Print("Mercado fechado ou sem conexão!");
      OneTimeOpen = 1;
      return;
   } else if(MarketStatus() && OneTimeOpen == 1) {
      if(Prints)
         Print("Mercado aberto!");
      OneTimeOpen = 0;
      static bool GetMinOpen = true;
      if(GetMinOpen) {
         MarketOpenMin = FTimeCurrent.min;
         GetMinOpen = false;
      }
   }
//--- Stop Móvel
   TrailingStop();
//--- Parcial
   if(HabilitaParcial) {
      //Recupera informações no preço atual (do tick)
      if(!SymbolInfoTick(_Symbol, LastTick)) {
         return;
      }
      //Verifica se o preço atingiu o valor de realização da parcial
      if(Parcial != 0.0 && LastTick.last == Parcial) {
         if(!RealizaParcial())
            if(Prints)
               Print("Erro na realização da Parcial!");
         //Executa Elevação do StopLoss
         if(MoveStop) {
            if(!EvoluiStop())
               if(Prints)
                  Print("Erro na evolução do Stop Loss!");
         }
         ReverseParcial = false;
         Parcial = 0.0;
      }
   }
//--- Verificar se é um novo dia
   if(NewDay != FTimeCurrent.day) {
      TradeDay  = 0;
      StopTrade = false;
      NewDay = FTimeCurrent.day;
   }
//--- Verifica se já foi operado no dia atual
   /*if(TradeDay) {
      TimeFrame = PERIOD_M5; //M5
      if(TradeDay >= 2)
         StopTrade = true;
   } else {
      TimeFrame = PERIOD_M1; //M1
   }*/
//--- Opera o dia todo dentro do horário definido
   if(!OneTrade) {
      StopTrade = false;
   } else { //Opera somente na primeira entrada
      //Verifica se já foi operado no dia atual
      if(TradeDay)
         StopTrade = true;
      else
         StopTrade = false;
   }
//--- TimeBar
   datetime TimeBar = iTimes(0, m_symbol.Name(), TimeFrame);
//--- Turn ON only in the second bar
   static datetime StartBar = TimeBar;
   if(TimeBar == StartBar)
      return;
//--- Work only at the time of the birth of new bar
   if(NewBar) {
      static datetime PrevBars = 0;
      if(TimeBar == PrevBars)
         return;
      PrevBars = TimeBar;
   }
//---
   if(!RefreshRates())
      return;
//--- Evita swing trader fechando ordens abertas após as 17h30
   if(ClosePositions) {
      long EndTime     = 17 * 60 * 60 + 30 * 60; //17H30
      //Fecha todas as ordens abertas
      if(STimeCurrent >= EndTime + 30)
         CloseAllPositions();
      if(STimeCurrent >= EndTime + 30) //+ 30 Duration in seconds
         return;
   }
//--- Horário para funcionamento
   if(HourTrade) {
      int StartMinute = InpStartMinute;
      int MarketOpenSafe = MarketOpenMin + 3;
      if(InpStartHour == 9)
         StartMinute = (InpStartMinute < 3 ? 3 : InpStartMinute);
      StartMinute = (MarketOpenSafe < StartMinute ? StartMinute : MarketOpenSafe);
      long StartTime   = InpStartHour * 60 * 60 + StartMinute * 60;
      long EndTime     = InpEndHour * 60 * 60 + InpEndMinute * 60;
      //+ 30 Minutos após o término operações para fechar todas as ordens
      long CloseTime   = InpEndHour * 60 * 60 + InpEndMinute * 60 + 1800;
      if(STimeCurrent >= CloseTime + 30)
         CloseAllPositions();
      if(STimeCurrent < StartTime || STimeCurrent >= EndTime + 30) //+ 30 Duration in seconds
         return;
   } else { //--- Evitar falsa entrada na abertura do mercado
      long StartTime   = 9 * 60 * 60 + 0 * 60; //9H00
      long EndTime     = 9 * 60 * 60 + 3 * 60; //9H03
      if(STimeCurrent > StartTime && STimeCurrent <= EndTime + 30) //+ 30 Duration in seconds
         return;
   }
//--- Máximo de perdas seguidas
   if(MaxLoss != 0) {
      if(ContLoss >= MaxLoss) {
         static int OneTimeLossSeq;
         if(MaxLoss != OneTimeLossSeq) {
            if(Prints)
               Print("Máximo de perdas seguidas alcançada, infelizmente! :(");
            OneTimeLossSeq = MaxLoss;
         }
         return;
      }
   }
//--- Meta de perda no dia
   if(MetaPerda())
      return;
//--- Meta de ganho no dia
   if(MetaGanho())
      return;
//---
   if(Assinatura) {
      if(!StopTrade) {
         Crossed = Crossed();
      }
   }
//---
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol() == m_symbol.Name() && m_position.Magic() == MagicNumber) {
            if(m_position.PositionType() == POSITION_TYPE_BUY) {
               if(Crossed == 1) {
                  Crossed = 0;
                  continue;
               }
               if(Crossed == 2) {
                  if(CloseOpposite)
                     m_trade.PositionClose(m_position.Ticket());
                  else
                     Crossed = 0;
                  continue;
               }
            } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
               if(Crossed == 1) {
                  if(CloseOpposite)
                     m_trade.PositionClose(m_position.Ticket());
                  else
                     Crossed = 0;
                  continue;
               }
               if(Crossed == 2) {
                  Crossed = 0;
                  continue;
               }
            }
         }
      if(!TradeAlways)
         return;
   }
//if(Crossed == 0)
//--- Comprar
   if(Crossed == 1 && !HasReverse) {
      //Ordem de Comprar a Mercado
      if(CheckMoney)
         if(!CheckMoneyForTrade(m_symbol.Name(), InpLots, ORDER_TYPE_BUY))
            return;
      //---
      double sl = (InpStopLoss == 0) ? 0.0 : m_symbol.Ask() - ExtStopLoss;
      double tp = (InpTakeProfit == 0) ? 0.0 : m_symbol.Ask() + ExtTakeProfit;
      if(!m_trade.Buy(InpLots, m_symbol.Name(), m_symbol.Ask(),
                      m_symbol.NormalizePrice(sl),
                      m_symbol.NormalizePrice(tp)))
         Print("Falha ao execultar a Ordem. Código: ", m_trade.ResultRetcode(),
               " | Descrição: ", m_trade.ResultRetcodeDescription(), " | Resultado: ", m_trade.ResultOrder());
      Parcial = m_symbol.Last() + BreakEven;
      Crossed           = 0;
      HasCrossed        = false;
      OneTimePost       = 1;
      TradeOneTimeDay   = FTimeCurrent.day;
      TradeDay++;
      //---
      if(Alerts)
         Alert(EA + " executou uma COMPRA!");
      //---
      if(Prints)
         Print(EA + " executou uma COMPRA!");
      //---
      if(Push) {
         if(!SendNotification(EA + " executou uma COMPRA!")) {
            if(Prints)
               Print("Falha ao enviar notificação para o smartphone!");
         } else {
            if(Prints)
               Print("Notificação enviada para o smartphone!");
         }
      }
   }
//--- Vender
   if(Crossed == 2 && !HasReverse) {
      //Ordem de Vender a Mercado
      if(CheckMoney)
         if(!CheckMoneyForTrade(m_symbol.Name(), InpLots, ORDER_TYPE_SELL))
            return;
      //---
      double sl = (InpStopLoss == 0) ? 0.0 : m_symbol.Bid() + ExtStopLoss;
      double tp = (InpTakeProfit == 0) ? 0.0 : m_symbol.Bid() - ExtTakeProfit;
      if(!m_trade.Sell(InpLots, m_symbol.Name(), m_symbol.Bid(),
                       m_symbol.NormalizePrice(sl),
                       m_symbol.NormalizePrice(tp)))
         Print("Falha ao execultar a Ordem. Código: ", m_trade.ResultRetcode(),
               " | Descrição: ", m_trade.ResultRetcodeDescription(), " | Resultado: ", m_trade.ResultOrder());
      Parcial = m_symbol.Last() - BreakEven;
      Crossed           = 0;
      HasCrossed        = false;
      OneTimePost       = 1;
      TradeOneTimeDay   = FTimeCurrent.day;
      TradeDay++;
      //---
      if(Alerts)
         Alert(EA + " executou uma VENDA!");
      //---
      if(Prints)
         Print(EA + " executou uma VENDA!");
      //---
      if(Push) {
         if(!SendNotification(EA + " executou uma VENDA!")) {
            if(Prints)
               Print("Falha ao enviar notificação para o smartphone!");
         } else {
            if(Prints)
               Print("Notificação enviada para o smartphone!");
         }
      }
   }
//--- Comprar com Reversão
   if(Crossed == 1 && HasReverse) {
      //Ordem de Comprar a Mercado
      if(CheckMoney)
         if(!CheckMoneyForTrade(m_symbol.Name(), InpLots, ORDER_TYPE_BUY))
            return;
      //---
      double sl = (InpStopLoss == 0) ? 0.0 : m_symbol.Ask() - ExtStopLoss;
      double tp = (InpTakeProfit == 0) ? 0.0 : m_symbol.Ask() + ExtTakeProfit;
      m_trade.Buy(InpLotsReverse, m_symbol.Name(), m_symbol.Ask(),
                  m_symbol.NormalizePrice(sl),
                  m_symbol.NormalizePrice(tp));
      Parcial = m_symbol.Last() + BreakEven;
      Crossed           = 0;
      HasCrossed        = false;
      HasReverse        = false;
      ReverseParcial    = true;
      OneTimePost       = 1;
      TradeOneTimeDay   = FTimeCurrent.day;
      //---
      if(Alerts)
         Alert(EA + " executou uma COMPRA com Reversão!");
      //---
      if(Prints)
         Print(EA + " executou uma COMPRA com Reversão!");
      //---
      if(Push)
         SendNotification(EA + " executou uma COMPRA com Reversão!");
   }
//--- Vender com Reversão
   if(Crossed == 2 && HasReverse) {
      //Ordem de Vender a Mercado
      if(CheckMoney)
         if(!CheckMoneyForTrade(m_symbol.Name(), InpLots, ORDER_TYPE_SELL))
            return;
      //---
      double sl = (InpStopLoss == 0) ? 0.0 : m_symbol.Bid() + ExtStopLoss;
      double tp = (InpTakeProfit == 0) ? 0.0 : m_symbol.Bid() - ExtTakeProfit;
      m_trade.Sell(InpLotsReverse, m_symbol.Name(), m_symbol.Bid(),
                   m_symbol.NormalizePrice(sl),
                   m_symbol.NormalizePrice(tp));
      Parcial = m_symbol.Last() - BreakEven;
      Crossed           = 0;
      HasCrossed        = false;
      HasReverse        = false;
      ReverseParcial    = true;
      OneTimePost       = 1;
      TradeOneTimeDay   = FTimeCurrent.day;
      //---
      if(Alerts)
         Alert(EA + " executou uma VENDA com Reversão!");
      //---
      if(Prints)
         Print(EA + " executou uma VENDA com Reversão!");
      //---
      if(Push)
         SendNotification(EA + " executou uma VENDA com Reversão!");
   }
}
//+------------------------------------------------------------------+
//| Crossed Moving Average                                           |
//+------------------------------------------------------------------+
int Crossed() {
   double FastMAPrevious = iMAGet(handle_iMA_short, InpCurrentBar + 1);
   double FastMACurrent  = iMAGet(handle_iMA_short, InpCurrentBar);
   double SlowMAPrevious = iMAGet(handle_iMA_long, InpCurrentBar + 1);
   double SlowMACurrent  = iMAGet(handle_iMA_long, InpCurrentBar);
   if(FastMAPrevious < SlowMAPrevious && FastMACurrent > SlowMACurrent) {
      HasCrossed = true;
   }
   if(FastMAPrevious > SlowMAPrevious && FastMACurrent < SlowMACurrent) {
      HasCrossed = true;
   }
//--- BUY CONDITION
   if(HasCrossed && (FastMACurrent - SlowMACurrent) >= ExtMinCrossDistance) {
      return(1);
   }
//--- SELL CONDITION
   if(HasCrossed && (SlowMACurrent - FastMACurrent) >= ExtMinCrossDistance) {
      return(2);
   }
//---
   return(0);
}
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void) {
//--- refresh rates
   if(!m_symbol.RefreshRates()) {
      if(Prints)
         Print("Erro na atualização dos dados da cotação.");
      return(false);
   }
//--- protection against the return value of "zero"
   if(m_symbol.Ask() == 0 || m_symbol.Bid() == 0)
      return(false);
//---
   return(true);
}
//+------------------------------------------------------------------+
//| CheckMoneyForTrade                                               |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb, double lots, ENUM_ORDER_TYPE type) {
//--- obtemos o preço de abertura
   MqlTick mqltick;
   SymbolInfoTick(symb, mqltick);
   double price = mqltick.ask;
   if(type == ORDER_TYPE_SELL)
      price = mqltick.bid;
//--- valores da margem necessária e livre
   double margin, free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
//--- chamamos a função de verificação
   if(!OrderCalcMargin(type, symb, lots, price, margin)) {
      //--- algo deu errado, informamos e retornamos false
      if(Prints)
         Print("Erro em ", __FUNCTION__, ". Código de erro: ", GetLastError());
      return(false);
   }
//--- se não houver fundos suficientes para realizar a operação
   if(margin > free_margin) {
      //--- informamos sobre o erro e retornamos false
      if(Prints)
         Print("Não há saldo suficiente para ", EnumToString(type), " ", InpLots, " " + symb + ". Código de erro: ", GetLastError(), ".");
      return(false);
   }
//--- a verificação foi realizada com sucesso
   return(true);
}
//+------------------------------------------------------------------+
//| Verifica a validez do volume da ordem                            |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume, string & description) {
//--- valor mínimo permitido para operações de negociação
   double min_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if(volume < min_volume) {
      description = StringFormat("Volume inferior ao mínimo permitido SYMBOL_VOLUME_MIN=%.2f", min_volume);
      return(false);
   }
//--- volume máximo permitido para operações de negociação
   double max_volume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if(volume > max_volume) {
      description = StringFormat("Volume superior ao máximo permitido SYMBOL_VOLUME_MAX=%.2f", max_volume);
      return(false);
   }
//--- obtemos a gradação mínima do volume
   double volume_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
   int ratio = (int)MathRound(volume / volume_step);
   if(MathAbs(ratio * volume_step - volume) > 0.0000001) {
      description = StringFormat("O volume não é múltiplo da gradação mínima SYMBOL_VOLUME_STEP=%.2f, volume mais próximo do válido é %.2f",
                                 volume_step, ratio * volume_step);
      return(false);
   }
   description = "Valor válido do volume";
   return(true);
}
//+------------------------------------------------------------------+
//| Verifica se um modo de preenchimento específico é permitido      |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(string symbol, int fill_type) {
//--- Obtém o valor da propriedade que descreve os modos de preenchimento permitidos
   int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
//--- Retorna true, se o modo fill_type é permitido
   return((filling & fill_type) == fill_type);
}
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA, const int index) {
   double MA[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iMA, 0, index, 1, MA) < 0) {
      //--- if the copying fails, tell the error code
      if(Prints)
         PrintFormat("Falha ao copiar dados do indicador iMA, código de erro %d", GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
   }
   return(MA[0]);
}
//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTimes(const int index, string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
   int count = 1; //number of bars
   datetime time[1]; //array storing the returned bar time
   datetime rtime = 0;
//---
   if(symbol == NULL)
      symbol = Symbol();
//--- copy time
   int copied = CopyTime(symbol, timeframe, index, count, time);
   if(copied > 0)
      rtime = time[0];
   return(rtime);
}
//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, //event ID
                  const long & lparam,  //event parameter of the long type
                  const double & dparam, //event parameter of the double type
                  const string & sparam) { //event parameter of the string type
   BOT.OnChartEvent(id, lparam, dparam, sparam);
//---
   if(id == CHARTEVENT_CHART_CHANGE) {
      if(SetCoords()) {
         DeletePanel();
         CreatePanel();
         ResetDatas();
         CheckPositions(true);
         CheckPositions(false);
      }
   }
//---
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == ButtonName) { //button is clicked
         if(button.GetString(OBJPROP_TEXT) == EA + " OFF") {
            button.SetString(OBJPROP_TEXT, EA + " ON"); //set the current state to ON
            button.BackColor(clrYellowGreen);
            button.BorderColor(clrYellowGreen);
            Print(EA + " LIGADO!");
            TurnON = true;
         } else { //switch to OFF
            button.SetString(OBJPROP_TEXT, EA + " OFF"); //set the current state to OFF
            button.BackColor(clrTomato);
            //button.BorderColor(clrTomato);
            Print(EA + " DESLIGADO!");
            TurnON = false;
         }
      }
      if(sparam == LabelName) { //label is clicked
         MessageBox("Total Contratos: " + DoubleToString(num_b_day + num_s_day, 0) +
                    "\nLucro Bruto: " + DoubleToString(profit_day, 2) +
                    "\nLucro Líquido: " + DoubleToString(profit_day - (num_b_day + num_s_day * CustoTrade), 2)
                    , EA + " Info\n", MB_OK);
      }
   }
//---
   if(id == CHARTEVENT_KEYDOWN) {
      switch((int)lparam) {
      case KEY_I:
         MessageBox("Total Contratos: " + DoubleToString(num_b_day + num_s_day, 0) +
                    "\nLucro Bruto: " + DoubleToString(profit_day, 2) +
                    "\nLucro Líquido: " + DoubleToString(profit_day - (num_b_day + num_s_day * CustoTrade), 2)
                    , EA + " Info\n", MB_OK);
         break;
         //default:
         //if(Prints)
         //Print("Pressed unlisted key");
      }
   }
}
//+------------------------------------------------------------------+
//| Trade event handler function                                     |
//+------------------------------------------------------------------+
void OnTrade() {
//---
}
//+------------------------------------------------------------------+
//| Timer event handler function                                     |
//+------------------------------------------------------------------+
void OnTimer() {
//--- Verificação de posição
   CheckPositions(true);
   CheckPositions(false);
}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction & trans,
                        const MqlTradeRequest & request,
                        const MqlTradeResult & result) {
   string Volume, Profit;
//--- post transaction type as enumeration value
   ENUM_TRADE_TRANSACTION_TYPE type = trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type == TRADE_TRANSACTION_DEAL_ADD) {
      long     deal_entry     = 0;
      double   deal_profit    = 0.0;
      double   deal_volume    = 0.0;
      string   deal_symbol    = "";
      long     deal_magic     = 0;
      long     deal_reason    = -1;
      if(HistoryDealSelect(trans.deal)) {
         deal_entry  = HistoryDealGetInteger(trans.deal, DEAL_ENTRY);
         deal_profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
         deal_volume = HistoryDealGetDouble(trans.deal, DEAL_VOLUME);
         deal_symbol = HistoryDealGetString(trans.deal, DEAL_SYMBOL);
         deal_magic  = HistoryDealGetInteger(trans.deal, DEAL_MAGIC);
         deal_reason = HistoryDealGetInteger(trans.deal, DEAL_REASON);
      } else
         return;
      Volume = DoubleToString(deal_volume, 1);
      Profit = DoubleToString(deal_profit, 2);
      if(deal_symbol == m_symbol.Name() && deal_magic == MagicNumber)
         if(deal_entry == DEAL_ENTRY_OUT) {
            if(deal_reason == DEAL_REASON_SL) {
               if(TradeReverse) {
                  if(MaxReverse < StopReverse) {
                     HasReverse = true;
                     MaxReverse = MaxReverse + 1;
                  } else {
                     HasReverse = false;
                  }
               }
               if(OneTimePost == 1) {
                  if(MaxLoss != 0)
                     ContLoss = ContLoss + 1;
                  //--- enviar dados da plataforma para o servidor
                  WebRequest("POST", URL + EA + "/botopr.php" +
                             "?id=" + DoubleToString(AccountInfoInteger(ACCOUNT_LOGIN), 0) +
                             "&nome=" + AccountInfoString(ACCOUNT_NAME) +
                             "&resultado=Perda" +
                             "&conta=" + TradeMode +
                             "&contrato=" + Volume +
                             "&lucro=" + Profit,
                             NULL, 0, post, resultado, headers);
                  OneTimePost = 0;
               }
            } else if(deal_reason == DEAL_REASON_TP) {
               MaxReverse = 0;
               if(OneTimePost == 1) {
                  ContLoss = 0;
                  ReverseParcial = false;
                  //--- enviar dados da plataforma para o servidor
                  WebRequest("POST", URL + EA + "/botopr.php" +
                             "?id=" + DoubleToString(AccountInfoInteger(ACCOUNT_LOGIN), 0) +
                             "&nome=" + AccountInfoString(ACCOUNT_NAME) +
                             "&resultado=Ganho" +
                             "&conta=" + TradeMode +
                             "&contrato=" + Volume +
                             "&lucro=" + Profit,
                             NULL, 0, post, resultado, headers);
                  OneTimePost = 0;
               }
            }
         }
   }
}
//+------------------------------------------------------------------+
//| ButtonCreate                                                     |
//+------------------------------------------------------------------+
bool ButtonCreate(CChartObjectButton & btn, const string name,
                  const int x, const int y, int width, int height, ENUM_BUTTON_CORNER corner = CORNER_BUTTON_RIGHT_LOWER) {
//--- button coordinate, relative to the corner of chart
   int pointX = 0, pointY = 0; //Exactly, it is the coordinate of the button's LEFT_UPPER
   ENUM_BASE_CORNER cornerBase = CORNER_RIGHT_LOWER;
   if(corner == CORNER_BUTTON_LEFT_UPPER) {
      pointX = x;
      pointY = y;
      cornerBase = CORNER_LEFT_UPPER;
   } //corner=0,button is at the left upper of chart
   if(corner == CORNER_BUTTON_RIGHT_UPPER) {
      pointX = x + width;
      pointY = y;
      cornerBase = CORNER_RIGHT_UPPER;
   } //corner=3
   if(corner == CORNER_BUTTON_LEFT_LOWER) {
      pointX = x;
      pointY = height + y;
      cornerBase = CORNER_LEFT_LOWER;
   } //corner=1
   if(corner == CORNER_BUTTON_RIGHT_LOWER) {
      pointX = x + width;
      pointY = y + height;
      cornerBase = CORNER_RIGHT_LOWER;
   } //corner=2
//--- Create button
   if(!btn.Create(0, name, 0, pointX, pointY, width, height)) return(false);
   if(!btn.Corner(cornerBase)) return(false);
   if(!btn.FontSize(FontSize)) return(false);
   if(!btn.Color(clrWhite)) return(false); //OBJPROP_COLOR: the color of text on button
   if(!btn.BackColor(clrYellowGreen)) return(false); //OBJPROP_BGCOLOR
   if(!btn.BorderColor(clrYellowGreen)) return(false); //OBJPROP_BORDER_COLOR,same as backcolor to make button flat.
   if(!btn.SetInteger(OBJPROP_HIDDEN, true)) return(false);
   if(!btn.SetInteger(OBJPROP_SELECTABLE, false)) return(false);
//--- successful execution
   return(true);
}
//+------------------------------------------------------------------+
//| Fecha todas as posições abertas                                  |
//+------------------------------------------------------------------+
void CloseAllPositions() {
//--- declaração do pedido e o seu resultado
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal(); //número de posições abertas
//--- iterar todas as posições abertas
   for(int i = total - 1; i >= 0; i--) {
      //--- parâmetros da ordem
      ulong  position_ticket = PositionGetTicket(i);                          //bilhete da posição
      string position_symbol = PositionGetString(POSITION_SYMBOL);            //simbolo
      int    digits = (int)SymbolInfoInteger(position_symbol, SYMBOL_DIGITS); //número de casas decimais
      ulong  magic = PositionGetInteger(POSITION_MAGIC);                      //MagicNumber da posição
      double volume = PositionGetDouble(POSITION_VOLUME);                     //volume da posição
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); //tipo de posição
      //--- se o MagicNumber coincidir
      if(magic == MagicNumber) {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- configuração dos parâmetros da ordem
         request.action    = TRADE_ACTION_DEAL;       //tipo de operação de negociação
         request.position  = position_ticket;         //bilhete da posição
         request.symbol    = position_symbol;         //símbolo
         request.volume    = volume;                  //volume da posição
         request.deviation = InpSlippage;             //desvio permitido do preço
         request.magic     = MagicNumber;             //MagicNumber da posição
         //--- saída de informação sobre a posição
         if(Prints)
            PrintFormat("#%I64u %s %s %.2f %s",
                        position_ticket,
                        position_symbol,
                        EnumToString(type),
                        volume,
                        DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), digits));
         Alert("Ordem aberta fora do horário configurado. Encerramento em 30 segundos...");
         Sleep(30000); //pausa de 30 segundos antes de encerrar a operação
         if(type == POSITION_TYPE_BUY) {
            request.price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
            request.type = ORDER_TYPE_SELL;
         } else {
            request.price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
            request.type = ORDER_TYPE_BUY;
         }
         //--- saída de informação sobre o fechamento
         if(Prints)
            Print("Ordem encerrada pelo robô " + EA + ".");
         //--- envio do pedido
         if(!OrderSend(request, result)) {
            if(Prints)
               Print("Falha ao encerrar operação. Erro: ", GetLastError());
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Fecha todas as posições abertas                                  |
//+------------------------------------------------------------------+
void CloseNow() {
//--- declaração do pedido e o seu resultado
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal(); //número de posições abertas
//--- iterar todas as posições abertas
   for(int i = total - 1; i >= 0; i--) {
      //--- parâmetros da ordem
      ulong  position_ticket = PositionGetTicket(i);                          //bilhete da posição
      string position_symbol = PositionGetString(POSITION_SYMBOL);            //simbolo
      int    digits = (int)SymbolInfoInteger(position_symbol, SYMBOL_DIGITS); //número de casas decimais
      ulong  magic = PositionGetInteger(POSITION_MAGIC);                      //MagicNumber da posição
      double volume = PositionGetDouble(POSITION_VOLUME);                     //volume da posição
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE); //tipo de posição
      //--- se o MagicNumber coincidir
      if(magic == MagicNumber) {
         //--- zerar os valores do pedido e os seus resultados
         ZeroMemory(request);
         ZeroMemory(result);
         //--- configuração dos parâmetros da ordem
         request.action    = TRADE_ACTION_DEAL;       //tipo de operação de negociação
         request.position  = position_ticket;         //bilhete da posição
         request.symbol    = position_symbol;         //símbolo
         request.volume    = volume;                  //volume da posição
         request.deviation = InpSlippage;             //desvio permitido do preço
         request.magic     = MagicNumber;             //MagicNumber da posição
         if(type == POSITION_TYPE_BUY) {
            request.price = SymbolInfoDouble(position_symbol, SYMBOL_BID);
            request.type = ORDER_TYPE_SELL;
         } else {
            request.price = SymbolInfoDouble(position_symbol, SYMBOL_ASK);
            request.type = ORDER_TYPE_BUY;
         }
         //--- envio do pedido
         if(!OrderSend(request, result)) {
            if(Prints)
               Print("Falha ao encerrar operação. Erro: ", GetLastError());
         }
      }
   }
}
//+------------------------------------------------------------------+
//| Expert Realização Parcial function                               |
//+------------------------------------------------------------------+
bool RealizaParcial() {
   double Volume = 0;
   if(!ReverseParcial) {
      //if(InpLots%2 == 0)
      if(InpLots == 1) {
         if(Prints)
            Print("A Parcial não pode ser realizada com 1 contrato.");
         return(false);
      }
      Volume = MathRound(InpLots - ((InpLots * PorcentParcial) / 100)); //Valor arredondado até o inteiro mais próximo.
   } else {
      if(InpLotsReverse == 1) {
         if(Prints)
            Print("A Parcial não pode ser realizada com 1 contrato na Reversão.");
         return(false);
      }
      Volume = MathRound(InpLotsReverse - ((InpLotsReverse * PorcentParcial) / 100));
   }
   if(!PositionSelect(_Symbol))
      return(false);
   else {
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            if(!m_trade.Sell(Volume, _Symbol, LastTick.bid, NULL, NULL)) {
               if(Prints)
                  Print("Erro ao realizar Parcial: ", GetLastError());
               return(false);
            } else {
               return(true);
            }
         } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            if(!m_trade.Buy(Volume, _Symbol, LastTick.ask, NULL, NULL)) {
               if(Prints)
                  Print("Erro ao realizar Parcial: ", GetLastError());
               return(false);
            } else {
               return(true);
            }
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
//| Expert Evolui Stop function                                      |
//+------------------------------------------------------------------+
bool EvoluiStop() {
   if(!ReverseParcial) {
      //if(InpLots%2 == 0)
      if(InpLots == 1) {
         if(Prints)
            Print("A Evolução do Stop Loss não pode ser realizada com 1 contrato.");
         return(false);
      }
   } else {
      if(InpLotsReverse == 1) {
         if(Prints)
            Print("A Evolução do Stop Loss não pode ser realizada com 1 contrato no Reversão.");
         return(false);
      }
   }
   if(!PositionSelect(_Symbol))
      return(false);
   else {
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         //Recupera o preço de entrada da posição
         double NewStop = PositionGetDouble(POSITION_PRICE_OPEN);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
            NewStop = NewStop - PontosMoveStop;
         } else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
            NewStop = NewStop + PontosMoveStop;
         }
         if(!m_trade.PositionModify(_Symbol, NewStop, PositionGetDouble(POSITION_TP))) {
            if(Prints)
               Print("Erro ao mover o Stop Loss: ", GetLastError());
            return(false);
         } else {
            return(true);
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
//| Função para meta diária de ganho                                 |
//+------------------------------------------------------------------+
bool MetaGanho() {
   double      Resultado = 0; //Resultado financeiro do dia
   MqlDateTime Data;
   TimeCurrent(Data);
   string StrTime = string(Data.year) + "." + string(Data.mon) + "." + string(Data.day);
   HistorySelect(StringToTime(StrTime), TimeCurrent());
   int         total = HistoryDealsTotal();
   ulong       ticket = 0;
   double      price;
   double      profit;
   datetime    time;
   string      symbol;
   long        type;
   long        entry;
//--- para todos as operações
   for(int i = 0; i < total; i++) {
      //--- tentar obter ticket das operações
      if((ticket = HistoryDealGetTicket(i)) > 0) {
         //--- obter as propriedades das operações
         price   = HistoryDealGetDouble(ticket, DEAL_PRICE);
         time    = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         symbol  = HistoryDealGetString(ticket, DEAL_SYMBOL);
         type    = HistoryDealGetInteger(ticket, DEAL_TYPE);
         entry   = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         profit  = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         //--- apenas para o ativo atual
         if(symbol == Symbol())
            Resultado = Resultado + profit;
      }
   }
   if (MetaGain != 0 && Resultado >= MetaGain) {
      static string OneTimeGain;
      if(StrTime != OneTimeGain) {
         if(Prints)
            Print("Meta de ganho no dia alcançada com sucesso! :)");
         OneTimeGain = StrTime;
      }
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
//| Função para meta diária de perda                                 |
//+------------------------------------------------------------------+
bool MetaPerda() {
   double      Resultado = 0; //Resultado financeiro do dia
   MqlDateTime Data;
   TimeCurrent(Data);
   string StrTime = string(Data.year) + "." + string(Data.mon) + "." + string(Data.day);
   HistorySelect(StringToTime(StrTime), TimeCurrent());
   int         total = HistoryDealsTotal();
   ulong       ticket = 0;
   double      price;
   double      profit;
   datetime    time;
   string      symbol;
   long        type;
   long        entry;
//--- para todos as operações
   for(int i = 0; i < total; i++) {
      //--- tentar obter ticket das operações
      if((ticket = HistoryDealGetTicket(i)) > 0) {
         //--- obter as propriedades das operações
         price   = HistoryDealGetDouble(ticket, DEAL_PRICE);
         time    = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         symbol  = HistoryDealGetString(ticket, DEAL_SYMBOL);
         type    = HistoryDealGetInteger(ticket, DEAL_TYPE);
         entry   = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         profit  = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         //--- apenas para o ativo atual
         if(symbol == Symbol())
            Resultado = Resultado + profit;
      }
   }
   if (MetaLoss != 0 && Resultado <= MetaLoss * -1) {
      static string OneTimeLoss;
      if(StrTime != OneTimeLoss) {
         if(Prints)
            Print("Meta de perda no dia alcançada, infelizmente! :(");
         OneTimeLoss = StrTime;
      }
      return(true);
   }
   return(false);
}
//+------------------------------------------------------------------+
//| MarketStatus                                                     |
//+------------------------------------------------------------------+
bool MarketStatus() {
   if(TerminalInfoInteger(TERMINAL_CONNECTED)) {
      //--- Time
      datetime Time = iTimes(0);
      //--- Time Candle
      int SegundosRestantes = int(Time - TimeCurrent() + PeriodSeconds());
      if(SegundosRestantes < 0) {
         return(false); //FECHADO
      } else {
         return(true); //ABERTO
      }
   }
   return(false); //SEM CONEXÃO
}
//+------------------------------------------------------------------+
//| Stop Móvel                                                       |
//+------------------------------------------------------------------+
bool TrailingStop() {
   if(InpTrailingStop != 0) {
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         if(m_position.SelectByIndex(i))
            if(m_position.Symbol() == m_symbol.Name() && m_position.Magic() == MagicNumber) {
               if(m_position.PositionType() == POSITION_TYPE_BUY) {
                  if(m_position.PriceCurrent() - m_position.PriceOpen() > ExtTrailingStop + ExtTrailingStep)
                     if(m_position.StopLoss() < m_position.PriceCurrent() - (ExtTrailingStop + ExtTrailingStep)) {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(m_position.PriceCurrent() - ExtTrailingStop),
                                                   m_position.TakeProfit())) {
                           if(Prints)
                              Print("Erro ao modificar a Posição: ", m_position.Ticket(),
                                    ". Código do resultado: ", m_trade.ResultRetcode(),
                                    ", descrição do resultado: ", m_trade.ResultRetcodeDescription());
                           return(false);
                        } else
                           return(true);
                     }
               } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
                  if(m_position.PriceOpen() - m_position.PriceCurrent() > ExtTrailingStop + ExtTrailingStep)
                     if((m_position.StopLoss() > (m_position.PriceCurrent() + (ExtTrailingStop + ExtTrailingStep))) ||
                           (m_position.StopLoss() == 0)) {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                                                   m_symbol.NormalizePrice(m_position.PriceCurrent() + ExtTrailingStop),
                                                   m_position.TakeProfit())) {
                           if(Prints)
                              Print("Erro ao modificar a Posição: ", m_position.Ticket(),
                                    ". Código do resultado: ", m_trade.ResultRetcode(),
                                    ", descrição do resultado: ", m_trade.ResultRetcodeDescription());
                           return(false);
                        } else
                           return(true);
                     }
               }
            }
      }
   }
   return(true);
}
//+------------------------------------------------------------------+
